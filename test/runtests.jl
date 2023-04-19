using PhysiologyPlotting
using Test

test_file = raw"to_analyze.abf"
data = readABF(test_file)

@testset "Testing basic quick plotting" begin
    plot_experiment(ax, data, channels = 2, color = :black, alpha = 0.2, xlims = (-0.25, 5.0))
end
