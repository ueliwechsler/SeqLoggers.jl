using Test

using SeqLoggers
using LoggingExtras


@testset "Unit Tests SeqLoggers" begin include("unit_tests_loggers.jl") end
@testset "Test Load from Configs" begin include("unit_load_from_config.jl") end

# @testset "Integration Tests SeqLoggers" begin include("integration_tests_loggers.jl") end
