# NOTE: BatchSeqLogger only works correctly with `with_logger`
# NOTE: Not yet parallelizable (we need to lock the array during posting!)

struct BatchSeqLogger <: AbstractLogger
    seqLogger::SeqLogger
    batchEvents::Vector{String}
    batchSize::Int
end

BatchSeqLogger(serverUrl="http://localhost:5341";
               minLevel=Logging.Info,
               apiKey="",
               batchSize=10,
               kwargs...) = begin
   seqLogger = SeqLogger(serverUrl;
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
        push!(logger.batchEvents, eventJson)
        if length(logger.batchEvents) >= logger.batchSize
            flush(logger)
        end
    finally
        unlock(l)
    end
    return nothing
end

function Base.flush(batchLogger::BatchSeqLogger)
    if !isempty(batchLogger.batchEvents)
        eventBatch = join(batchLogger.batchEvents, "\n")
        empty!(batchLogger.batchEvents)
        HTTP.request("POST", batchLogger.seqLogger.serverUrl,
                             batchLogger.seqLogger.header,
                             eventBatch)
    end
    return nothing
end
