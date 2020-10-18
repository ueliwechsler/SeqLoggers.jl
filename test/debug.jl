# ===================
# Execute
# ===================

using Revise
# push!(LOAD_PATH, abspath(joinpath(@__DIR__,"..")))
using SeqLoggers

seqLogger = SeqLogger(; App="Trialrun", Env="Test")

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
 # 15.514324 seconds (319.50 k allocations: 17.198 MiB)

seqLogger = SeqLogger(; App="Trialrun", Env="Test")
@time Logging.with_logger(seqLogger) do
    for i=1:1000
        @info "Iteration $i of {type}" type=typeof(seqLogger)
        sleep(0.001)
    end
end
# 4.242601 seconds (538.67 k allocations: 30.332 MiB, 0.21% gc time)
