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
end


end
