# ===================
# Execute
# ===================

using Revise
# push!(LOAD_PATH, raw"C:\Users\UELIWECH\OneDrive\_Work\Axpo\workspace\SEQ")
using SeqLoggers

seqLogger = SeqLogger(raw"http://localhost:5341/api/events/raw?clef", Logging.Debug;
               App="DJSON", Env="Test",
               HistoryId=raw"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")


@time Logging.with_logger(seqLogger) do
    @info "Hallo Welt"
    @warn "Hallo Welt, {User}" User="Sem_Speedy"
    sleep(0.5)
    @debug "Hallo Welt, {Userd} & {User2}" User="Sem_Speedy" User2="SUBDN496"
    @error "Hallo Welt"
    sleep(0.5)
end

# In combination with LoggingExtras.jl

using SeqLoggers.LoggingExtras

combinedLogger = TeeLogger(Logging.current_logger(), seqLogger)

@time Logging.with_logger(combinedLogger) do
    @info "Hallo Welt"
    @warn "Hallo Welt, {User}" User="Sem_Speedy"
    sleep(0.5)
    @debug "Hallo Welt, {Userd} & {User2}" User="Sem_Speedy" User2="SUBDN496"
    @error "Hallo Welt"
    sleep(0.5)
end
