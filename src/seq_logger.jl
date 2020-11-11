abstract type AbstractSeqLogger <: AbstractLogger end

abstract type PostType end
struct Parallel <:PostType end
struct Serial <:PostType end
struct Background <:PostType
    nWorkers::Int
end
Background() = Background(one(Int))

struct SeqLogger{PT<:PostType} <: AbstractSeqLogger
    serverUrl::String
    header::Vector{Pair{String,String}}
    minLevel::Logging.LogLevel
    loggerEventProperties::String
    postType::PT
end

"""
    SeqLogger(serverUrl="http://localhost:5341", postType=Background();
                   minLevel=Logging.Info, apiKey="", kwargs...)

Logger that sends log events to a `Seq` logging server.

### Notes
The `kwargs` correspond to additional log event properties that can be added "globally"
for a `SeqLogger` instance.
e.g.
App = "DJSON", Env = "Test" # Dev, Prod, Test, UAT, HistoryId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

Additional log events can also be added separately for each idividual log event
`@info "Event" logEventProperty="logEventValue"`
"""
function SeqLogger(serverUrl="http://localhost:5341", postType=Background();
                   minLevel=Logging.Info, apiKey="", kwargs...)
    if postType isa Background
        WorkerUtilities.init(postType.nWorkers)
    end

    urlEndpoint = joinurl(serverUrl, "api/events/raw")
    header = ["Content-Type" => "application/vnd.serilog.clef"]
    if !isempty(apiKey)
        push!(header, "X-Seq-ApiKey" => apiKey)
    end
    loggerEventProperties = stringify(; kwargs...)
    return SeqLogger(urlEndpoint, header, minLevel, loggerEventProperties, postType)
end

Logging.shouldlog(logger::AbstractSeqLogger, arg...) = true
Logging.min_enabled_level(logger::AbstractSeqLogger) = logger.minLevel
Logging.catch_exceptions(logger::AbstractSeqLogger) = false

function Logging.handle_message(logger::AbstractSeqLogger, args...; kwargs...)
    handleMessageArgs = LoggingExtras.handle_message_args(args...; kwargs...)
    eventJson = parse_event_from_args(logger, handleMessageArgs)
    post_event(logger, eventJson)
    return nothing
end

function parse_event_from_args(logger::AbstractSeqLogger, handleMessageArgs)
    lineEventProperties = stringify(; _file=handleMessageArgs.file, _line=handleMessageArgs.line)
    additonalEventProperties = stringify(; handleMessageArgs.kwargs...)
    cleanMessage = replace_invalid_character("$(handleMessageArgs.message)")
    atTime = "\"@t\":\"$(now())\""
    atMsg = "\"@mt\":\"$(cleanMessage)\""
    atLevel = "\"@l\":\"$(to_seq_level(handleMessageArgs.level))\""
    event = join([atTime, atMsg, atLevel,
                 logger.loggerEventProperties,
                 lineEventProperties,
                 additonalEventProperties], ",")
    return "{$event}"
end

function post_event(logger::SeqLogger{Background}, eventJson)
    worker = WorkerUtilities.@spawn begin
        HTTP.request("POST", logger.serverUrl, logger.header, eventJson)
    end
    fetch(worker)
    return nothing
end

function post_event(logger::SeqLogger{Parallel}, eventJson)
    worker = Threads.@spawn begin
        HTTP.request("POST", logger.serverUrl, logger.header, eventJson)
    end
    fetch(worker)
    return nothing
end

function post_event(logger::SeqLogger{Serial}, eventJson)
    HTTP.request("POST", logger.serverUrl, logger.header, eventJson)
    return nothing
end
