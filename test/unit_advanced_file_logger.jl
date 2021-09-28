using Logging
using SeqLoggers
using Test

@testset "Advanced Logger Constructor" begin 

file_name_pattern = raw"\a\c\c\e\s\s-YYYY-mm-dd-HH-MM.\l\o\g"
dir_path = mktempdir()
logger =  AdvancedFileLogger(dir_path, file_name_pattern; min_level=Logging.Debug)
with_logger(logger) do
    @debug "Log to file"
    @info "Log to file"
    @warn "Log to file"
    @error "Log to file"
    sleep(61)
    @info "Log to next file" A = 2
end
log_files = readdir(dir_path, join=true)
@test length(log_files) == 2

content = """[Debug] Log to file
[Info] Log to file
[Warning] Log to file
[Error] Log to file
"""
@test log_files[1] |> read |> String == content


@test_throws ArgumentError run_with_logger(logger) do
    @debug "Debug Log Message with 1 kwargs" keywarg="A"
    @info "Info Log Message with 2 kwargs" keywarg="A" second=rand(200, 10) third=DataFrame(rand(20,10))
    @warn "Warn Log message without kwargs"
    @error "Error Log Before Exception" A="A" B="AB" C="ABC" D="ABCD"
    throw(ArgumentError("Throw an exception"))
    @info "After Exception" # Will not be excecuted
end

end