module SeqLoggers

export SeqLogger
export Logging

using Logging
# using Logging: Debug, Info, Warn, Error
using LoggingExtras
using Dates
using HTTP

"""
    SeqLogger(url, min_level=Logging.Info; kwargs...)

`url=raw"http://localhost:5341/api/events/raw?clef"`

### kwargs
App = "DJSON"
Env = "Test" # Dev, Prod, Test, UAT
HistoryId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
"""
struct SeqLogger <: AbstractLogger
    url::String #from config
    min_level::Logging.LogLevel
    loggerEventProperties::String
end

SeqLogger(url, min_level=Logging.Info; kwargs...) = begin
    loggerEventProperties = stringify(; kwargs...)
    return SeqLogger(url, min_level, loggerEventProperties)
end

Logging.shouldlog(logger::SeqLogger, arg...) = true
Logging.min_enabled_level(logger::SeqLogger) = logger.min_level
Logging.catch_exceptions(logger::SeqLogger) = false

function Logging.handle_message(logger::SeqLogger, args...; kwargs...)
    logArgs = LoggingExtras.handle_message_args(args...; kwargs...)
    additonalEventProperties = stringify(; logArgs.kwargs...)
    atTime = "\"@t\":\"$(now())\""
    atMsg = "\"@mt\":\"$(logArgs.message)\""
    atLevel = "\"@l\":\"$(to_seq_level(logArgs.level))\""
    event = join([atTime, atMsg, atLevel,
                 logger.loggerEventProperties,
                 additonalEventProperties], ",")
    flush(logger, event)
    return nothing
end
function Base.flush(logger::SeqLogger, event)
    # HTTP.request("POST", logger.url, [], "{$event}\n")
    Threads.@spawn HTTP.request("POST", logger.url, [], "{$event}\n")
    return nothing
end

function stringify(; kwargs...)
    kwargsString = Vector{String}()
    for kwarg in kwargs
        push!(kwargsString, "\"$(kwarg.first)\":\"$(kwarg.second)\"")
    end
    return join(kwargsString, ",")
end

function to_seq_level(logLevel::Base.CoreLogging.LogLevel)
    if logLevel == Logging.Info
        return "Information"
    elseif logLevel == Logging.Debug
        return "Debug"
    elseif logLevel == Logging.Warn
        return "Warning"
    elseif logLevel == Logging.Error
        return "Error"
    end
end



end
