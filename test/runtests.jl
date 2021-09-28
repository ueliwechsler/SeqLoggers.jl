using Test

using SeqLoggers
using LoggingExtras


@testset "Unit Tests SeqLoggers" begin include("unit_tests_loggers.jl") end
@testset "Load from Configs" begin include("unit_load_from_config.jl") end

# only for local tests (fail on server?)
@testset "Advanced file logger" begin include("unit_advanced_file_logger.jl") end
# @testset "Integration Tests SeqLoggers" begin include("integration_tests_loggers.jl") end
