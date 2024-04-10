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
    fig, axis = plt.subplots(2)
    plot_experiment(axis, data, channels = 2, alpha = 0.2, xlims = (-0.25, 5.0))
end

@testset "Testing CairoMakie" begin 
    using CairoMakie
    @test PhysiologyPlotting.frontend == :CairoMakie
end

@testset "Testing GLMakie" begin
    using GLMakie
    @test PhysiologyPlotting.frontend == :GLMakie

    #This is the plot where we use specific subplots
    fig = Figure()
    ax1 = Axis(fig[1,1], ylabel = getChannelName(data, 1))
    ax2 = Axis(fig[2,1], xlabel = "Time (ms)", ylabel = getChannelName(data, 2))
    experimentplot!(ax1, data, channel = 1)
    experimentplot!(ax2, data, channel = 2)
    display(fig)

end