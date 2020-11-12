# NOTE: BatchSeqLogger only works correctly with `with_logger`
# NOTE: Not yet parallelizable (we need to lock the array during posting!)

struct BatchSeqLogger <: AbstractLogger
    seqLogger::SeqLogger
    eventBatch::Vector{String}
    batchSize::Int
end

BatchSeqLogger(serverUrl="http://localhost:5341", postType=Background();
               minLevel=Logging.Info,
               apiKey="",
               batchSize=10,
               kwargs...) = begin
   seqLogger = SeqLogger(serverUrl, postType;
                  minLevel=minLevel,
                  apiKey = apiKey,
                  kwargs...)
   return BatchSeqLogger(seqLogger, String[], batchSize)
end

function Logging.with_logger(@nospecialize(f::Function), batchSeqlogger::BatchSeqLogger)
    Base.CoreLogging.with_logstate(f, Base.CoreLogging.LogState(batchSeqlogger))
    flush(batchSeqlogger)
end

Logging.shouldlog(logger::BatchSeqLogger, arg...) = true
Logging.min_enabled_level(logger::BatchSeqLogger) = logger.seqLogger.minLevel
Logging.catch_exceptions(logger::BatchSeqLogger) = false

const l = ReentrantLock()

function Logging.handle_message(logger::BatchSeqLogger, args...; kwargs...)
    lock(l)
    try
        handleMessageArgs = LoggingExtras.handle_message_args(args...; kwargs...)
        eventJson = parse_event_from_args(logger.seqLogger, handleMessageArgs)
        push!(logger.eventBatch, eventJson)
        if length(logger.eventBatch) >= logger.batchSize
            flush_events(logger)
        end
    finally
        unlock(l)
    end
    return nothing
end

function flush_events(batchLogger::BatchSeqLogger)
    if !isempty(batchLogger.eventBatch)
        eventBatch = join(batchLogger.eventBatch, "\n")
        empty!(batchLogger.eventBatch)
        HTTP.request("POST", batchLogger.seqLogger.serverUrl,
                             batchLogger.seqLogger.header,
                             eventBatch)
    end
    return nothing
end

# QuickFix to FLush BatchSeqLogger as part of LoggingExtras.TeeLogger
function Logging.with_logger(@nospecialize(f::Function), demux::TeeLogger)
    result = Base.CoreLogging.with_logstate(f, Base.CoreLogging.LogState(demux))
    flush_events.(demux.loggers)
    return result
end

flush_events(::Logging.AbstractLogger) = nothing
