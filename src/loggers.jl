abstract type PostType end
struct Parallel <:PostType end
struct Serial <:PostType end
struct Background <:PostType
    nWorkers::Int
end
Background() = Background(one(Int))

struct SeqLogger{PT<:PostType} <: AbstractLogger
    serverUrl::String
    header::Vector{Pair{String,String}}
    minLevel::Logging.LogLevel
    eventProperties::Ref{String}
    postType::PT
    eventBatch::Vector{String}
    batchSize::Int
end

"""
    SeqLogger(serverUrl="http://localhost:5341", postType=Serial();
              minLevel=Logging.Info,
              apiKey="",
              batchSize=10,
              kwargs...)

Logger to post log events to a `Seq` log server.

### Inputs
- `serverUrl` -- (optional, `default="http://localhost:5341"`) `Seq` server url
- `postType` -- (optional, `default=Serial()`) defines how `HTTP` posts the log events
- `minLevel` -- (optional, `default=Logging.Info`) minimal log level required to post events
- `apiKey` --  (optional, `default=""`) API-key string for registered Applications
- `batchSize` -- (optional, `default=10`) number of log events sent to `Seq` server in single post
- `kwargs` -- (optional) global log event properties

#### Global Log Event Properties
The user can provide the logger with global log event properties by using the
keyword-arguments `kwargs`.
```julia
SeqLogger(; App="DJSON", Env="PROD", Id="24e0d145-d385-424b-b6ec-081aa17d504a")
```

#### Local Log Event Properties
For each individual log event, additional log event properties can be added which
only apply to the respective log event.
```julia
@info "Log additional user id {userId}" userId="1"
```
This only works, if the [`Logging.current_logger`](@ref) is of type `SeqLogger`.
"""
function SeqLogger(serverUrl="http://localhost:5341", postType=Serial();
                   minLevel=Logging.Info,
                   apiKey="",
                   batchSize=10,
                   kwargs...)
    if postType isa Background
        WorkerUtilities.init(postType.nWorkers)
    end

    urlEndpoint = joinurl(serverUrl, "api/events/raw")
    header = ["Content-Type" => "application/vnd.serilog.clef"]
    if !isempty(apiKey)
        push!(header, "X-Seq-ApiKey" => apiKey)
    end
    eventProperties = stringify(; kwargs...)
    return SeqLogger(urlEndpoint,
                     header,
                     minLevel,
                     Ref(eventProperties),
                     postType,
                     String[],
                     batchSize)
end

Logging.shouldlog(logger::SeqLogger, arg...) = true
Logging.min_enabled_level(logger::SeqLogger) = logger.minLevel
Logging.catch_exceptions(logger::SeqLogger) = false

"""
    event_property!(logger::SeqLogger; kwargs...)

Add one or more event properties to the list of global event properties in `logger`.

### Example
```julia
event_property!(logger, user="Me", userId=1)
```
### Note
If a new event property with identical name as an existing on is added with
`event_property!`, the existing property in `newEventProperties` is not
replaced, the new property is just added to `newEventProperties`.
However, this still works since on the `Seq` side the raw post events considers the last property key as the final one if more than one has the same key.
"""
function event_property!(logger::SeqLogger; kwargs...)
    newEventProperties = stringify(; kwargs...)
    if isempty(logger.eventProperties[])
        logger.eventProperties[] = newEventProperties
    else
        logger.eventProperties[] = join([logger.eventProperties[],
                                         newEventProperties], ",")
    end
    return nothing
end

"""
    Logging.with_logger(@nospecialize(f::Function), logger::SeqLogger)

Extends the method [`Logging.with_logger`](@ref) to work for a `SeqLogger`.
"""
function Logging.with_logger(@nospecialize(f::Function), seqLogger::SeqLogger)
    result = Base.CoreLogging.with_logstate(f, Base.CoreLogging.LogState(seqLogger))
    flush_events(seqLogger)
    return result
end

const l = ReentrantLock()

function Logging.handle_message(logger::SeqLogger, args...; kwargs...)
    lock(l)
    try
        handleMessageArgs = LoggingExtras.handle_message_args(args...; kwargs...)
        eventJson = parse_event_from_args(logger, handleMessageArgs)
        push!(logger.eventBatch, eventJson)
        if length(logger.eventBatch) >= logger.batchSize
            flush_events(logger)
        end
    finally
        unlock(l)
    end
    return nothing
end

function parse_event_from_args(logger::SeqLogger, handleMessageArgs)
    lineEventProperties = stringify(; _file=handleMessageArgs.file, _line=handleMessageArgs.line)
    kwargEventProperties = stringify(; handleMessageArgs.kwargs...)
    cleanMessage = replace_invalid_character("$(handleMessageArgs.message)")
    atTime = "\"@t\":\"$(now())\""
    atMsg = "\"@mt\":\"$(cleanMessage)\""
    atLevel = "\"@l\":\"$(to_seq_level(handleMessageArgs.level))\""
    defaultEventProperties = [atTime, atMsg, atLevel]
    additonalEventProperties = [event for event in (lineEventProperties,
                                                    kwargEventProperties,
                                                    logger.eventProperties[]) if !isempty(event) ]
    event = join([defaultEventProperties..., additonalEventProperties...], ",")
    return "{$event}"
end

function flush_events(logger::SeqLogger)
    if !isempty(logger.eventBatch)
        eventBatchJson = join(logger.eventBatch, "\n")
        empty!(logger.eventBatch)
        post_json(logger, eventBatchJson)
    end
    return nothing
end

"""
    flush_current_logger()

Post the events in the logger batch event for the logger for the current task,
or the global logger if none is attached to the task.

### Note
In the main moduel of `Atom`, the `current_logger` is `Atom.Progress.JunoProgressLogger()`.
Therefore, if you set `SeqLogger` as a [Logging.global_logger](@ref) in in `Atom`
use [`flush_global_logger`](@ref).
"""
function flush_current_logger()
    currentLogger = Logging.current_logger()
    flush_events(currentLogger)
    nothing
end

"""
    flush_global_logger()

Post the events in the logger batch event for the global logger.

### Note
If the logger is run with [`Logging.with_logger`](@ref), this is considered a
current logger [Logging.current_logger](@ref) and  [`flush_current_logger`](@ref).
needs to be used.
"""
function flush_global_logger()
    currentLogger = Logging.global_logger()
    flush_events(currentLogger)
    nothing
end

function post_json(logger::SeqLogger{Background}, jsonBody)
    worker = WorkerUtilities.@spawn begin
        HTTP.request("POST", logger.serverUrl, logger.header, jsonBody)
    end
    fetch(worker)
    return nothing
end

function post_json(logger::SeqLogger{Parallel}, jsonBody)
    worker = Threads.@spawn begin
        HTTP.request("POST", logger.serverUrl, logger.header, jsonBody)
    end
    fetch(worker)
    return nothing
end

function post_json(logger::SeqLogger{Serial}, jsonBody)
    HTTP.request("POST", logger.serverUrl, logger.header, jsonBody)
    return nothing
end

# ====================
# Extend with_logger to work with  LoggingExtras.TeeLogger
# ====================
"""
    Logging.with_logger(@nospecialize(f::Function), demuxLogger::TeeLogger)

Extends the method [`Logging.with_logger`](@ref) to work for a `LoggingExtras.TeeLogger`
containing a `SeqLogger`.

### Note
This constitutes as type piracy and should be treated with caution.
"""
function Logging.with_logger(@nospecialize(f::Function), demuxLogger::TeeLogger)
    result = Base.CoreLogging.with_logstate(f, Base.CoreLogging.LogState(demuxLogger))
    flush_events(demuxLogger)
    return result
end

"""
    flush_events(teeLogger::LoggingExtras.TeeLogger)

Extend `flush_events` to a work for a `LoggingExtras.TeeLogger`
containing a `SeqLogger`.
"""
function flush_events(teeLogger::LoggingExtras.TeeLogger)
    loggers = teeLogger.loggers # LoggingExtras API
    for logger in loggers
        flush_events(logger)
    end
    return nothing
end

flush_events(::Logging.AbstractLogger) = nothing

event_property!(logger::AbstractLogger; kwargs...) = nothing
function event_property!(teelogger::LoggingExtras.TeeLogger; kwargs...)
    loggers = teelogger.loggers
    for logger in loggers
        event_property!(logger; kwargs...)
    end
    return nothing
end
