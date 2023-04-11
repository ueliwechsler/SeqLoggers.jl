using SeqLoggers
using Logging
using Test

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


@testset "run_with_logger SeqLoggers Flush event batch" begin
    logger = SeqLogger(SERVER_URL; App="Trialrun")

    @test_throws DomainError run_with_logger(logger, -1) do x
        @info "Run stuff"
        sqrt(x)
    end

    @test isempty(logger.event_batch)
end


@testset "Throw exception in all available Loggers" begin

    console_logger = global_logger()
    @test_throws ArgumentError run_with_logger(console_logger) do
        throw(ArgumentError("Tester, indeed!"))
    end

    seq_logger = SeqLogger(SERVER_URL; App="TrialRun")
    @test_throws ArgumentError run_with_logger(seq_logger) do
        @info "sfd"
        @warn "sfd"
        @error "Logged error with backtrace" back_trace = "This is a backtrace"
        @error "Logged error without backtrace"
        throw(ArgumentError("Real exception thrown"))
    end

    # Run this test after load logger from config was successful
    file_path = joinpath(@__DIR__, "data", "config.json")
    tee_logger = SeqLoggers.load_logger_from_config(file_path)
    @test_throws ArgumentError run_with_logger(tee_logger) do
        @info "sfd"
        @warn "sfd"
        @error "Logged error with backtrace" back_trace = "This is a backtrace"
        @error "Logged error without backtrace"
        throw(ArgumentError("Real exception thrown"))
    end

end