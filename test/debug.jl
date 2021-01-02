# ===================
# Execute
# ===================

using Revise
# push!(LOAD_PATH, abspath(joinpath(@__DIR__,"..")))
using SeqLoggers

## Methods
using LinearAlgebra
function parallel_iterations(logger, nIter, duration=1)
    Logging.with_logger(logger) do
        for i=1:nIter
            Threads.@threads for idx=1:4
                @info "Iteration $i,$idx, threadId $(Threads.threadid()) of {type}" type=typeof(logger)
                t = time()
                x = randn(10,10)
                while time() < t + duration
                    x = x * (x.^2 + I)
                end
            end
        end
    end
end

function busy_iterations(logger, nIter, duration=1)
    Logging.with_logger(logger) do
        for i=1:nIter
            @info "Iteration $i of {type}" type=typeof(logger)
            x = randn(10,10)
            t = time()
            while time() < t + duration
                x = x * (x.^2 + I)
            end
        end
    end
end

function idle_iterations(logger, nIter, duration=1)
    Logging.with_logger(logger) do
        for i=1:nIter
            @info "Iteration $i of {type}" type=typeof(logger)
            sleep(duration)
        end
    end
end

function parallel_iterations2(logger, nIter, duration=0.1)
    Logging.with_logger(logger) do
        Threads.@threads for idx=1:nIter
            @info "Iteration $idx, threadId $(Threads.threadid()) of {type}" type=typeof(logger)
            t = time()
            x = randn(10,10)
            while time() < t + duration
                x = x * (x.^2 + I)
            end
        end
    end
end

## Define Loggers
# serverUrl = "http://subdn215:5341/"
serverUrl = "http://localhost:5341/"
parallelLogger = SeqLogger(serverUrl, SeqLoggers.Parallel(); App="Trialrun")
serialLogger = SeqLogger(serverUrl; App="Trialrun")
bgLogger = SeqLogger(serverUrl, SeqLoggers.Background();App="Trialrun", Env="Test")
serialLoggerBatchSize1 = SeqLogger(serverUrl; batchSize=1, App="Trialrun")

bg3Logger = SeqLogger(serverUrl, SeqLoggers.Background(3); App="Trialrun", Env="Test")
bgBrokenLogger = SeqLogger("brokenUrl", SeqLoggers.Background();)

## Benchmarks
# We only need, background, serial and batched logger (batched is the best (but parallelisation?))
@elapsed busy_iterations(parallelLogger, 10)
@elapsed busy_iterations(serialLogger, 10)
@elapsed busy_iterations(serialLoggerBatchSize1, 10)
@elapsed busy_iterations(bgLogger, 10)
@elapsed busy_iterations(bg3Logger, 10)

@elapsed busy_iterations(parallelLogger, 100, 0.1)
@elapsed busy_iterations(serialLogger, 100, 0.1)
@elapsed busy_iterations(bgLogger, 100, 0.1)
@elapsed busy_iterations(bg3Logger, 100, 0.1)

@elapsed busy_iterations(parallelLogger, 25)
@elapsed busy_iterations(serialLogger, 25)
@elapsed busy_iterations(bgLogger, 25)
@elapsed busy_iterations(bg3Logger, 25)

@elapsed idle_iterations(parallelLogger, 10)
@elapsed idle_iterations(serialLogger, 10)
@elapsed idle_iterations(bgLogger, 10)
@elapsed idle_iterations(bg3Logger, 10)

@elapsed parallel_iterations(parallelLogger, 10)
@elapsed parallel_iterations(serialLogger, 10)
@elapsed parallel_iterations(bgLogger, 10)
@elapsed parallel_iterations(bg3Logger, 10)

@elapsed parallel_iterations2(serialLogger, 15)
@elapsed parallel_iterations2(parallelLogger, 15)
@elapsed parallel_iterations2(bgLogger, 15)


@elapsed parallel_iterations(bgBrokenLogger, 10)

@elapsed busy_iterations(serialLogger, 10)


##
serverUrl = "http://localhost:5341/"
serialLogger = SeqLogger(serverUrl; App="Trialrun")
@time Logging.with_logger(serialLogger) do
    @debug "Debug Event Welt"
    sleep(0.1)
    @info "Info Event"
    sleep(0.1)
    @warn "Warning Event with one logger event property: User: {User}" User="Ueli Wechsler"
    sleep(0.1)
    @error "Error Event with multiple logger event properties: User: {User}, machine: {machine}" User="Ueli Wechsler" machine="speedy"
    sleep(0.1)
    SeqLoggers.event_property!(serialLogger; new="NewProperty")
    @info "Info Event with additional event property: {new}"
end

# In combination with LoggingExtras.jl
using LoggingExtras
combinedLogger = TeeLogger(Logging.current_logger(), serialLogger)

@time Logging.with_logger(combinedLogger) do
    @debug "Debug Event Welt"
    sleep(0.1)
    @info "Info Event"
    sleep(0.1)
    @warn "Warning Event with one logger event property: User: {User}" User="Ueli Wechsler"
    sleep(0.1)
    @error "Error Event with multiple logger event properties: User: {User}, machine: {machine}" User="Ueli Wechsler" machine="speedy"
    sleep(0.1)
    SeqLoggers.event_property!(serialLogger; new="NewPropertyTee")
    @info "Info Event with additional event property: {new}"
end



## Invalid Strings

serverUrl = "http://localhost:5341/"
logger = SeqLogger(serverUrl, ; App="Trialrun")
Logging.global_logger(logger)
@info "Test"
@info "Test3\n, \r, \\ \""
SeqLoggers.flush_global_logger()
