#=
[compat]
CairoMakie = "0.10"
Conda = "1"
DataFrames = "1"
Distributions = "0.25"
ElectroPhysiology = "0.4"
GLMakie = "0.8"
PyCall = "1"
PyPlot = "2"
Query = "1"
Requires = "1"
Statistics = "1"
julia = "1"
=#
using Pkg
println(Pkg.status())
using ElectroPhysiology
using PhysiologyPlotting
using Test

test_file = raw"to_analyze.abf"
data = readABF(test_file)

@testset "Testing PyPlot plotting" begin
    #Test the default frontend
    using PyPlot
    @test PhysiologyPlotting.frontend == :PyPlot

    plot_experiment(data, channels = 2, color = :black, alpha = 0.2, xlims = (-0.25, 5.0))
end

@testset "Testing CairoMakie" begin 
    using CairoMakie
    @test PhysiologyPlotting.frontend == :CairoMakie
end

@testset "Testing GLMakie" begin
    using GLMakie
    @test PhysiologyPlotting.frontend == :GLMakie
end