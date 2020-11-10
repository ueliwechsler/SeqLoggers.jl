# ===================
# Execute
# ===================

using Revise
# push!(LOAD_PATH, abspath(joinpath(@__DIR__,"..")))
using SeqLoggers

## Methods
using LinearAlgebra
function parllel_iterations(logger, nIter, duration=1)
    Logging.with_logger(logger) do
        for i=1:nIter
            @info "Iteration $i of {type}" type=typeof(logger)
            Threads.@threads for i=1:4
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


## Define Loggers
serverUrl = "http://subdn215:5341/"
parallelLogger = SeqLogger(serverUrl, SeqLoggers.Parallel(); App="Trialrun")
serialLogger = SeqLogger(serverUrl, SeqLoggers.Serial(); App="Trialrun")

bgLogger = SeqLogger(serverUrl;App="Trialrun", Env="Test")
bg3Logger = SeqLogger(serverUrl, SeqLoggers.Background(3); App="Trialrun", Env="Test")
bgBrokenLogger = SeqLogger("brokenUrl", SeqLoggers.Parallel(); )

## Benchmarks
@elapsed busy_iterations(parallelLogger, 10)
@elapsed busy_iterations(serialLogger, 10)
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

@elapsed parllel_iterations(parallelLogger, 10)
@elapsed parllel_iterations(serialLogger, 10)
@elapsed parllel_iterations(bgLogger, 10)
@elapsed parllel_iterations(bg3Logger, 10)

@elapsed parllel_iterations(bgBrokenLogger, 10)



##
@time Logging.with_logger(seqLogger) do
    @info "Info Event $(typeof(seqLogger)))"
    sleep(0.1)
end

@time Logging.with_logger(seqLogger) do
    @debug "Debug Event Welt"
    sleep(0.1)
    @info "Info Event"
    sleep(0.1)
    @warn "Warning Event with one logger event property: User: {User}" User="Ueli Wechsler"
    sleep(0.1)
    @error "Error Event with multiple logger event properties: User: {User}, machine: {machine}" User="Ueli Wechsler" machine="speedy"
    sleep(0.1)
end

# In combination with LoggingExtras.jl
using SeqLoggers.LoggingExtras

seqLogger = SeqLogger(; minLevel=Logging.Debug,
                        apiKey="Test",
                        App="Trialrun",
                        HistoryId=raw"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
                        Env="Test")
combinedLogger = TeeLogger(Logging.current_logger(), seqLogger)

@time Logging.with_logger(combinedLogger) do
    @debug "Debug Event Welt"
    sleep(0.1)
    @info "Info Event"
    sleep(0.1)
    @warn "Warning Event with one logger event property: User: {User}" User="Ueli Wechsler"
    sleep(0.1)
    @error "Error Event with multiple logger event properties: User: {User}, machine: {machine}" User="Ueli Wechsler" machine="speedy"
    sleep(0.1)
end

# Unnecessary!!!

# using HTTP
# event = "\"@t\":\"2020-10-17T19:36:30.266\",\"@mt\":\"Hallo Welt\",\"@l\":\"Information\",\"App\":\"DJSON\",\"Env\":\"Test\",\"HistoryId\":\"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\","
# res = HTTP.request("POST", seqLogger.serverUrl, seqLogger.header, "{$event}")


batchSeqLogger = BatchSeqLogger(; batchSize=200, App="Trialrun", Env="Test")

@time Logging.with_logger(batchSeqLogger) do
    for i=1:1000
        @info "Iteration $i of {type}" type=typeof(batchSeqLogger)
        sleep(0.001)
    end
    flush(batchSeqLogger)
end

seqLogger = SeqLogger("http://subdn215:5341/", SeqLoggers.Serial(); App="Trialrun")
seqLogger = SeqLogger("http://subdn215:5341/", SeqLoggers.Parallel(); App="Trialrun")
seqLogger = SeqLogger("http://subdn215:5341/", SeqLoggers.ParallelDirty(); App="Trialrun")

seqLogger = SeqLogger("http://subdn215:5341/";App="Trialrun", Env="Test")
seqLogger = SeqLogger("http://subdn215:5341/", SeqLoggers.Background(3); App="Trialrun", Env="Test")


 # 15.514324 seconds (319.50 k allocations: 17.198 MiB)
seqLogger = SeqLogger(SeqLoggers.Parallel(); App="Trialrun", Env="Test")
seqLogger = SeqLogger(; App="Trialrun", Env="Test")
@time Logging.with_logger(seqLogger) do
    for i=1:250
        @info "Iteration $i of {type}" type=typeof(seqLogger)
        sleep(0.001)
    end
end

using LinearAlgebra

@time Logging.with_logger(seqLogger) do
    for i=1:25
        @info "Iteration $i of {type}" type=typeof(seqLogger)
        t = time()
        x = randn(10,10)
        while time() < t + 1
            x = x * (x.^2 + I)
        end
    end
end

@time Logging.with_logger(seqLogger) do
    for i=1:25
        @info "Iteration $i of {type}" type=typeof(seqLogger)
        t = time()
        x = randn(10,10)
        while time() < t + 1
            x = x * (x.^2 + I)
        end
    end
end
# 4.242601 seconds (538.67 k allocations: 30.332 MiB, 0.21% gc time)

@time Logging.with_logger(seqLogger) do
    for i=1:25
        @info "Iteration $i of {type}" type=typeof(seqLogger)
        Threads.@threads for i=1:4
            t = time()
            x = randn(10,10)
            while time() < t + 1
                x = x * (x.^2 + I)
            end
        end
    end
end
