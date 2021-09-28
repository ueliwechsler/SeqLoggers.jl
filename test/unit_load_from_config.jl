using SeqLoggers
using Test
using Logging
using LoggingExtras

@testset "Load SeqLogger" begin
# Only Required Values
log_dict = Dict(
    "server_url" => "http://subdn215:5341/",
    "min_level" => "Info"
)

seq_logger = SeqLoggers.load_seqlogger(log_dict)
@test seq_logger.server_url == "http://subdn215:5341/api/events/raw"
@test seq_logger.min_level == Logging.Info
@test !haskey(seq_logger.headers, "X-Seq-api_key") 
@test seq_logger.event_properties[] == ""
@test seq_logger.batch_size == 10

# All arguments without global event properties
log_dict = Dict(
    "server_url" => "http://subdn215:5341/",
    "min_level" => "INFO",
    "api_key" => "test",
    "batch_size" => 12,
    "transformation" => "identity",
)

seq_logger = SeqLoggers.load_seqlogger(log_dict)
@test seq_logger.server_url == "http://subdn215:5341/api/events/raw"
@test seq_logger.min_level == Logging.Info
@test seq_logger.headers["X-Seq-api_key"] == "test"
@test seq_logger.batch_size == 12
@test seq_logger.event_properties[] == ""

log_dict = Dict(
    "server_url" => "http://subdn215:5341/",
    "min_level" => "INFO",
    "transformation" => "identity",
    "api_key" => "test",
    "batch_size" => 12,
    "App" => "SeqLoggers_Test",
    "Env" => "Test"
)

seq_logger = SeqLoggers.load_seqlogger(log_dict)
@test seq_logger.server_url == "http://subdn215:5341/api/events/raw"
@test seq_logger.min_level == Logging.Info
@test seq_logger.headers["X-Seq-api_key"] == "test"
@test seq_logger.batch_size == 12
@test seq_logger.event_properties[] == "\"Env\":\"Test\",\"App\":\"SeqLoggers_Test\""

# Transformation different than "identity"
log_dict = Dict(
    "server_url" => "http://subdn215:5341/",
    "min_level" => "Error",
    "transformation" => "add_timestamp"
)

trans_logger = SeqLoggers.load_seqlogger(log_dict)
seq_logger = trans_logger.logger
@test seq_logger.server_url == "http://subdn215:5341/api/events/raw"
@test seq_logger.min_level == Logging.Error
@test !haskey(seq_logger.headers, "X-Seq-api_key") 
@test seq_logger.event_properties[] == ""
@test seq_logger.batch_size == 10

end


@testset "Load ConsoleLogger" begin 

logging_config = Dict(
    "min_level" => "INFO",
)

logger = SeqLoggers.load_consolelogger(logging_config)
@test logger.min_level == Logging.Info

logging_config = Dict(
    "min_level" => "ERROR",
    "transformation" => "add_timestamp",
)

tran_logger = SeqLoggers.load_consolelogger(logging_config)
@test tran_logger.logger.min_level == Logging.Error

end

@testset "Load FileLogger" begin 

logging_config = Dict(
    "min_level" => "INFO",
    "file_path" => "C:\\temp\\test.csv",
    "append" => true
)

logger = SeqLoggers.load_filelogger(logging_config)
@test logger.min_level == Logging.Info

logging_config = Dict(
    "min_level" => "INFO",
    "file_path" => "C:\\temp\\test.csv",
    "append" => true,
    "transformation" => "add_timestamp",
)

tran_logger = SeqLoggers.load_filelogger(logging_config)
@test tran_logger.logger.min_level == Logging.Info

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
        )
    ]
)

@test SeqLoggers.get_logger(config["logging"][1]...) isa SeqLogger
@test SeqLoggers.get_logger(config["logging"][2]...) isa ConsoleLogger
@test SeqLoggers.get_logger(config["logging"][3]...) isa MinLevelLogger # of FileLogger
tee_logger = SeqLoggers.load_logger_from_config(config)
@test tee_logger.loggers[1] isa SeqLogger
@test tee_logger.loggers[2] isa ConsoleLogger
@test tee_logger.loggers[3] isa MinLevelLogger # of FileLogger

# Broken test
@test_throws ArgumentError SeqLoggers.get_logger("FalseLogger", Dict())

end

@testset "Register New Logger" begin 

struct FakeLogger <: AbstractLogger
    fake_field::String
end

function load_fake_logger(config::Dict)
    return FakeLogger(config["fake_field"])
end

SeqLoggers.register_logger!("FakeLogger", load_fake_logger)

config = Dict(
    "logging" => Dict(
        "FakeLogger" => Dict(
            "fake_field" => "Nothing to Log here!"
        )
    )
)
tee_logger = SeqLoggers.load_logger_from_config(config)
@test tee_logger.loggers[1] isa FakeLogger

end


@testset "Load Logger from config" begin 

file_path = joinpath(@__DIR__, "data", "config.json")
tee_logger = SeqLoggers.load_logger_from_config(file_path)
@test tee_logger.loggers[1] isa SeqLogger
@test tee_logger.loggers[2] isa ConsoleLogger
@test tee_logger.loggers[3] isa MinLevelLogger # of FileLogger

end
