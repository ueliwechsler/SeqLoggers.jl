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
@test minimalSeqLogger.header == ["Content-Type" => "application/vnd.serilog.clef"]
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
@test seqLogger.header == ["Content-Type" => "application/vnd.serilog.clef"
                        "X-Seq-api_key" => "Test"]
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
