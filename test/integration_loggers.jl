serverUrl = "http://localhost:5341/"
logger = SeqLogger(serverUrl, ; App="Trialrun")
Logging.global_logger(logger)
@info "Test"
@info "Test invalid string\n, \r, \\ \""
SeqLoggers.flush_global_logger()

batchSeqLogger = SeqLogger(serverUrl; batchSize=1, App="Trialrun", Env="Test")
Logging.global_logger(batchSeqLogger)
@info "Batchtest"


# write TeeLogger
serverUrl = "http://localhost:5341/"
teeLogger = SeqLoggers.LoggingExtras.TeeLogger(
        SeqLogger(serverUrl; App="TeeLogger"),
        Logging.ConsoleLogger(stderr)
)

Logging.with_logger(teeLogger) do
    @info "Test"
end

SeqLoggers.Logging.global_logger(teeLogger)
SeqLoggers.Logging.global_logger()
@info "1"
SeqLoggers.flush_global_logger() # flushes the global_logger()
SeqLoggers.flush_current_logger() # flushes the current_logger()

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
