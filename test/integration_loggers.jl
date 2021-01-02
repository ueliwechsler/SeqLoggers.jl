serverUrl = "http://localhost:5341/"
logger = SeqLogger(serverUrl, ; App="Trialrun")
Logging.global_logger(logger)
@info "Test"
@info "Test invalid string\n, \r, \\ \""
SeqLoggers.flush_global_logger()

batchSeqLogger = SeqLogger(serverUrl; batchSize=1, App="Trialrun", Env="Test")
Logging.global_logger(batchSeqLogger)
@info "Batch=1 test; doesn't need to flush"


# write TeeLogger
serverUrl = "http://localhost:5341/"
teeLogger = SeqLoggers.LoggingExtras.TeeLogger(
        SeqLogger(serverUrl; App="TeeLogger"),
        Logging.ConsoleLogger(stderr)
)

Logging.with_logger(teeLogger) do
    @info "Test teelogger, plus does not need to flush, because run with `with_logger`"
end

SeqLoggers.Logging.global_logger(teeLogger)
SeqLoggers.Logging.global_logger()
@info "In Atom main module, the current logger is an atomlogger"
SeqLoggers.flush_current_logger() # flushes the current_logger()
@info "And to flush global logger, we need the flush_global_logger function"
SeqLoggers.flush_global_logger() # flushes the global_logger()

logger1 = Logging.ConsoleLogger(stderr)
logger3 = SeqLogger(serverUrl, ; App="Trialrun")
logger2 = SeqLoggers.LoggingExtras.TeeLogger(
        SeqLogger(serverUrl; App="TeeLogger"),
        Logging.ConsoleLogger(stderr)
)
Logging.global_logger(logger1)
@info "Test logger recursion 0"
Logging.with_logger(logger2) do
    @info "Test logger recursion 1"
    @show Logging.current_logger()
    @show Logging.global_logger()
    Logging.with_logger(logger3) do
        @info "Test logger recursion 2"
        @show Logging.current_logger()
        @show Logging.global_logger()
    end
end
