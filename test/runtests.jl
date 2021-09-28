using Test

using SeqLoggers
using LoggingExtras


@testset "Unit Tests SeqLoggers" begin include("unit_tests_loggers.jl") end
@testset "Load from Configs" begin include("unit_load_from_config.jl") end

# only for local tests (fail on server?)
if haskey(ENV, "LOCAL_TEST") && ENV["LOCAL_TEST"] != "FALSE"
@info "Running local tests"
@testset "Advanced file logger" begin include("unit_advanced_file_logger.jl") end
@testset "Integration Tests SeqLoggers" begin include("integration_tests_loggers.jl") end
end
