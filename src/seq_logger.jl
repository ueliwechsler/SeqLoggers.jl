struct SeqLogger <: AbstractLogger
    serverUrl::String
    header::Vector{Pair{String,String}}
    minLevel::Logging.LogLevel
    loggerEventProperties::String
end

"""
    SeqLogger(;serverUrl="http://localhost:5341",
               minLevel=Logging.Info,
               apiKey = "",
               kwargs...)

### Notes
The `kwargs` correspond to additional log event properties that can be added "globally"
for a `SeqLogger` instance.
e.g.
App = "DJSON", Env = "Test" # Dev, Prod, Test, UAT, HistoryId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

Additional log events can also be added separately for each idividual log event
`@info "Event" logEventProperty="logEventValue"`
"""
SeqLogger(;serverUrl="http://localhost:5341",
           minLevel=Logging.Info,
           apiKey="",
           kwargs...) = begin
    urlEndpoint = joinurl(serverUrl, "api/events/raw")
    header = ["Content-Type" => "application/vnd.serilog.clef"]
    if !isempty(apiKey)
        push!(header, "X-Seq-ApiKey" => apiKey)
    end
    loggerEventProperties = stringify(; kwargs...)
    return SeqLogger(urlEndpoint, header, minLevel, loggerEventProperties)
end

Logging.shouldlog(logger::SeqLogger, arg...) = true
Logging.min_enabled_level(logger::SeqLogger) = logger.minLevel
Logging.catch_exceptions(logger::SeqLogger) = false

function Logging.handle_message(logger::SeqLogger, args...; kwargs...)
    handleMessageArgs = LoggingExtras.handle_message_args(args...; kwargs...)
    eventJson = parse_event_from_args(logger, handleMessageArgs)
    flush(logger, eventJson)
    return nothing
end

function parse_event_from_args(logger::SeqLogger, handleMessageArgs)
    lineEventProperties = stringify(; _file=handleMessageArgs.file, _line=handleMessageArgs.line)
    additonalEventProperties = stringify(; handleMessageArgs.kwargs...)
    atTime = "\"@t\":\"$(now())\""
    atMsg = "\"@mt\":\"$(handleMessageArgs.message)\""
    atLevel = "\"@l\":\"$(to_seq_level(handleMessageArgs.level))\""
    event = join([atTime, atMsg, atLevel,
                 logger.loggerEventProperties,
                 lineEventProperties,
                 additonalEventProperties], ",")
    return "{$event}"
end

function Base.flush(logger::SeqLogger, eventJson)
    # TODO: add some feedback mechanism if the Post did not work!
    Threads.@spawn begin
        HTTP.request("POST", logger.serverUrl, logger.header, eventJson)
    end
    return nothing
end

#
# function Base.sequential_flush(logger::SeqLogger, eventJson)
#     HTTP.request("POST", logger.serverUrl, logger.header, eventJson)
#     return nothing
# end
