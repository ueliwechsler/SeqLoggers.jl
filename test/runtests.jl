using Test

using SeqLoggers
using LoggingExtras

@testset "Unit Tests" begin include("unit_tests.jl") end

@testset "Integration Tests" begin include("integration_tests.jl") end
