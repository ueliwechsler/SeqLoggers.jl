# const SERVER_URL = "http://localhost:5341/"
const SERVER_URL = "http://subdn215:5341/"

logger = SeqLogger(SERVER_URL; App="Trialrun")
Logging.global_logger(logger)
@info "Test"
@info "Test invalid string\n, \r, \\ \""
@test length(logger.event_batch) == 2
SeqLoggers.flush_global_logger()
@test isempty(logger.event_batch)

unbatched_logger = SeqLogger(SERVER_URL; batch_size=1, App="Trialrun", Env="Test")
Logging.global_logger(unbatched_logger)
@info "Batch=1 test; doesn't need to flush"
@test isempty(unbatched_logger.event_batch)

# write TeeLogger
tee_logger = SeqLoggers.LoggingExtras.TeeLogger(
        SeqLogger(SERVER_URL; App="Trialrun"),
        Logging.ConsoleLogger(stderr)
)

Logging.with_logger(tee_logger) do
    @info "Test teelogger, plus does not need to flush, because run with `with_logger`"
end
@test isempty(tee_logger.loggers[1].event_batch)


SeqLoggers.Logging.global_logger(tee_logger)
@test SeqLoggers.Logging.global_logger() == tee_logger
@info "In Atom main module, the current logger is an atomlogger"
SeqLoggers.flush_current_logger() # flushes the current_logger()
@info "And to flush global logger, we need the flush_global_logger function"
SeqLoggers.flush_global_logger() # flushes the global_logger()

logger1 = Logging.ConsoleLogger(stderr)
logger2 = SeqLoggers.LoggingExtras.TeeLogger(
    SeqLogger(SERVER_URL; App="Trialrun", recursion1="yeeees"),
    Logging.ConsoleLogger(stderr)
)
logger3 = SeqLogger(SERVER_URL, ; App="Trialrun", recursion2="yes")
Logging.global_logger(logger1)
@info "Test logger recursion 0"
Logging.with_logger(logger2) do
    @info "Test logger recursion 1 {recursion1}"
    @test Logging.current_logger() == logger2
    @test Logging.global_logger() == logger1
    Logging.with_logger(logger3) do
        @info "Test logger recursion 2 {recursion2}"
        @test Logging.current_logger() == logger3
        @test Logging.global_logger() == logger1
    end
end
