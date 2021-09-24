
# ====================
# Extend with_logger to work with  LoggingExtras.TeeLogger
# ====================

"""
    Logging.with_logger(@nospecialize(f::Function), demuxLogger::TeeLogger)

Extends the method [`Logging.with_logger`](@ref) to work for a `LoggingExtras.TeeLogger`
containing a `SeqLogger`.

### Note
This constitutes as type piracy and should be treated with caution.
But it is necessary such that also `TeeLogger`s that contain a `SeqLogger` do flush 
the log events after exiting the `with_logger` function.
"""
function Logging.with_logger(@nospecialize(f::Function), demuxLogger::TeeLogger)
    result = Base.CoreLogging.with_logstate(f, Base.CoreLogging.LogState(demuxLogger))
    flush_events(demuxLogger)
    return result
end

"""
    flush_events(teeLogger::LoggingExtras.TeeLogger)

Extend `flush_events` to a work for a `LoggingExtras.TeeLogger` containing a `SeqLogger`.
"""
function flush_events(teeLogger::LoggingExtras.TeeLogger)
    loggers = teeLogger.loggers # LoggingExtras API
    for logger in loggers
        flush_events(logger)
    end
    return nothing
end
flush_events(::Logging.AbstractLogger) = nothing

"""
    event_property!(teelogger::LoggingExtras.TeeLogger; kwargs...)

Extend `event_property!` to a work for a `LoggingExtras.TeeLogger` containing a `SeqLogger`.
"""
function event_property!(teelogger::LoggingExtras.TeeLogger; kwargs...)
    loggers = teelogger.loggers
    for logger in loggers
        event_property!(logger; kwargs...)
    end
    return nothing
end
event_property!(logger::AbstractLogger; kwargs...) = nothing
