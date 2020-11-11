using SeqLoggers
using Test

@testset "SeqLoggers.jl" begin

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

    invalidString = "Test\"BadString\\"
    validString = "Test'BadString/"
    @test SeqLoggers.replace_invalid_character(invalidString) == validString
end

@testset "SeqLogger" begin

    minimalSeqLogger = SeqLogger(;)
    @test minimalSeqLogger isa SeqLogger
    @test minimalSeqLogger.minLevel == Logging.Info
    minimalSeqLogger.serverUrl == "http://localhost:5341/api/events/raw"
    @test minimalSeqLogger.loggerEventProperties  == ""
    @test minimalSeqLogger.header == ["Content-Type" => "application/vnd.serilog.clef"]

    minLevel = Logging.Debug
    seqLogger = SeqLogger(; minLevel=minLevel,
                            apiKey="Test",
                            App="Trialrun",
                            serverUrl="http://myhost:1010",
                            HistoryId=raw"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
                            Env="Test")

    @test seqLogger.minLevel == Logging.Debug
    @test seqLogger.serverUrl == "http://myhost:1010/api/events/raw"
    @test seqLogger.loggerEventProperties  ==  "\"App\":\"Trialrun\",\"HistoryId\":\"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\",\"Env\":\"Test\""
    @test seqLogger.header == ["Content-Type" => "application/vnd.serilog.clef"
                         "X-Seq-ApiKey" => "Test"]

    @test Logging.shouldlog(seqLogger) == true
    @test Logging.min_enabled_level(seqLogger) == minLevel
    @test Logging.catch_exceptions(seqLogger) == false


end

end
