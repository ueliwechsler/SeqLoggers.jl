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
log_files = joinpath.(dir_path, readdir(dir_path)) #kwarg join=true no in Julia 1.3
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


@testset "Load logger from config" begin

config = Dict(
    "logging" => [
        "SeqLogger" => Dict(
            "server_url" => "http://subdn215:5341/",
            "min_level" => "INFO",
        ),
        "ConsoleLogger" => Dict(
            "min_level" => "INFO",
        ),
        "FileLogger" => Dict(
            "min_level" => "INFO",
            "file_path" => raw"C:\Temp\test.txt",
            "append" => true,
        ),
        "AdvancedFileLogger" => Dict(
            "min_level" => "INFO",
            "dir_path" => "C:\\temp",
            "file_name_pattern" => "\\t\\e\\s\\t_YYYY-mm-dd.\\l\\o\\g",
        )
    ]
)
    
@test SeqLoggers.get_logger(config["logging"][4]...) isa MinLevelLogger # of FileLogger

tee_logger = SeqLoggers.load_logger_from_config(config)
@test tee_logger.loggers[4] isa MinLevelLogger # of FileLogger

file_path = joinpath(@__DIR__, "data", "config_with_advanced_logger.json")
tee_logger = SeqLoggers.load_logger_from_config(file_path)
@test tee_logger.loggers[4] isa MinLevelLogger # of FileLogger


end