using SeqLoggers
using Test
using LoggingExtras


@testset "Utils" begin
@test SeqLoggers.stringify(a="test") == "\"a\":\"test\""
@test SeqLoggers.stringify(a="testa", b="testb") == "\"a\":\"testa\",\"b\":\"testb\""

@test SeqLoggers.to_seq_level(SeqLoggers.Logging.Debug) == "Debug"
@test SeqLoggers.to_seq_level(SeqLoggers.Logging.Info) == "Info"
@test SeqLoggers.to_seq_level(SeqLoggers.Logging.Warn) == "Warning"
@test SeqLoggers.to_seq_level(SeqLoggers.Logging.Error) == "Error"

url1 = SeqLoggers.joinurl("http://localhost:8080", "index.html")
url2 = SeqLoggers.joinurl("http://localhost:8080/", "index.html")
url3 = SeqLoggers.joinurl("http://localhost:8080/", "/index.html")
url4 = SeqLoggers.joinurl("http://localhost:8080", "/index.html")
@test url1 == url2 == url3 == url4 == "http://localhost:8080/index.html"

invalidString = "Test\" \nBadString\\ \r"
validString = "Test' \\nBadString/ \\r"
@test SeqLoggers.replace_invalid_character(invalidString) == validString
end

@testset "SeqLogger" begin

minimalSeqLogger = SeqLogger("http://localhost:8080";)
@test minimalSeqLogger isa SeqLogger
@test minimalSeqLogger.min_level == Logging.Info
minimalSeqLogger.server_url == "http://localhost:5341/api/events/raw"
@test minimalSeqLogger.event_properties[]  == ""
@test minimalSeqLogger.headers == Dict("Content-Type" => "application/vnd.serilog.clef")
@test minimalSeqLogger.batch_size == 10
@test minimalSeqLogger.event_batch == String[]

min_level = Logging.Debug
seqLogger = SeqLogger(
    "http://myhost:1010";
    min_level=min_level,
    api_key="Test",
    App="Trialrun",
    batch_size=3,
    HistoryId=raw"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    Env="Test"
)

@test seqLogger.min_level == Logging.Debug
@test seqLogger.server_url == "http://myhost:1010/api/events/raw"
@test seqLogger.event_properties[]  ==  "\"App\":\"Trialrun\",\"HistoryId\":\"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\",\"Env\":\"Test\""
@test seqLogger.headers == Dict(
    "Content-Type" => "application/vnd.serilog.clef",
    "X-Seq-api_key" => "Test"
)
@test seqLogger.batch_size == 3
@test seqLogger.event_batch == String[]


@test Logging.shouldlog(seqLogger) == true
@test Logging.min_enabled_level(seqLogger) == min_level
@test Logging.catch_exceptions(seqLogger) == false

end

@testset "Add log event properties dynamically" begin
logger = SeqLogger("http://localhost:5341";)
SeqLoggers.event_property!(logger; newProperty="DynamicProperty")
@test logger.event_properties[] == "\"newProperty\":\"DynamicProperty\""
SeqLoggers.event_property!(logger; next="true")
@test logger.event_properties[] == "\"newProperty\":\"DynamicProperty\",\"next\":\"true\""
combinedLogger = TeeLogger(Logging.current_logger(), logger)
SeqLoggers.event_property!(combinedLogger; next3="true3")
@test combinedLogger.loggers[2].event_properties[] ==
    "\"newProperty\":\"DynamicProperty\",\"next\":\"true\",\"next3\":\"true3\""
end

@testset "parse_event_str_from_args" begin

logger = SeqLogger("http://localhost:5341";)
message_args = (
    level=Logging.Info, 
    message="Log Message", 
    _module=Main, 
    group=:file_name,
    file="file_path",
    line=100,
    kwargs=Dict(:a => 1, :b => 2)
)
parsed_msg_str = SeqLoggers.parse_event_str_from_args(logger, message_args)
parsed_msg_str_without_dt = parsed_msg_str[1:7] * parsed_msg_str[31:end]
@test parsed_msg_str_without_dt == "{\"@t\":\"\",\"@mt\":\"Log Message\",\"@l\":\"Info\",\"_file\":\"file_path\",\"_line\":\"100\",\"a\":\"1\",\"b\":\"2\"}"

message_args = (
    level=Logging.Error, 
    message="Log Message", 
    _module=Main, 
    group=:file_name,
    file="file_path",
    line=100,
    kwargs=Dict(:back_trace => "this is a backtrace", :b => 2)
)
parsed_msg_str = SeqLoggers.parse_event_str_from_args(logger, message_args)
parsed_msg_str_without_dt = parsed_msg_str[1:7] * parsed_msg_str[31:end]
@test parsed_msg_str_without_dt == "{\"@t\":\"\",\"@mt\":\"Log Message\",\"@l\":\"Error\",\"@x\":\"this is a backtrace\",\"_file\":\"file_path\",\"_line\":\"100\",\"b\":\"2\"}"

end



@testset "Run With logger: ConsoleLogger" begin
logger = ConsoleLogger(stderr, Logging.Info)
run_with_logger(logger) do
    @debug "No Exception"
    @info "No Exception"
    @warn "No Exception"
    @error "No Exception"
end

@test_throws DomainError run_with_logger(logger, -1) do x
    sqrt(x)
end

end




