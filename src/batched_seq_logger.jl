# NOTE: This is not that useful at the moment!

# TODO: Add seqlogger with autoflush (can we do it, with automatice auto_flush_timeout?)

# seqlog.log_to_seq(
#    server_url="http://my-seq-server:5341/",
#    api_key="My API Key",
#    level=logging.INFO,
#    batch_size=10,
#    auto_flush_timeout=10,  # seconds
#    override_root_logger=True,
#    json_encoder_class=json.encoder.JSONEncoder  # Optional; only specify this if you want to use a custom JSON encoder
# )
# Batching and auto-flush
# By default SeqLog will wait until it has a batch of 10 messages before sending them to Seq. You can control the batch size by passing a value for batch_size.
#
# If you also want it to publish the current batch of events when not enough of them have arrived within a certain period, you can pass auto_flush_timeout (a float representing the number of seconds before an incomplete batch is published).

# NOTE: BatchSeqLogger only works correctly with `with_logger` and added flush!
# NOTE: Not yet parallelizable
struct BatchSeqLogger <: AbstractLogger
    seqLogger::SeqLogger
    batchEvents::Vector{String}
    batchSize::Int
end

BatchSeqLogger(;serverUrl="http://localhost:5341",
               minLevel=Logging.Info,
               apiKey="",
               batchSize=10,
               kwargs...) = begin
   seqLogger = SeqLogger(;serverUrl=serverUrl,
                  minLevel=minLevel,
                  apiKey = apiKey,
                  kwargs...)
   return BatchSeqLogger(seqLogger, String[], batchSize)
end

function with_logger(@nospecialize(f::Function), batchSeqlogger::BatchSeqLogger)
    with_logstate(f, LogState(batchSeqlogger))
    flush(batchSeqlogger)
end

Logging.shouldlog(logger::BatchSeqLogger, arg...) = true
Logging.min_enabled_level(logger::BatchSeqLogger) = logger.seqLogger.minLevel
Logging.catch_exceptions(logger::BatchSeqLogger) = false

function Logging.handle_message(logger::BatchSeqLogger, args...; kwargs...)
    eventJson = parse_event_from_args(logger.seqLogger, args...; kwargs...)
    push!(logger.batchEvents, eventJson)
    if length(logger.batchEvents) >= logger.batchSize
        flush(logger)
    end
    return nothing
end

function Base.flush(logger::BatchSeqLogger)
    if !isempty(logger.batchEvents)
        eventBatch = join(logger.batchEvents, "\n")
        empty!(logger.batchEvents)
        HTTP.request("POST", logger.seqLogger.serverUrl,
                                            logger.seqLogger.header,
                                            eventBatch)
    end
    return nothing
end
