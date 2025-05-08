module PhysiologyPlotting

using Dates
using Requires

using ElectroPhysiology
import ElectroPhysiology: Experiment, readABF, parseABF
import ElectroPhysiology: WHOLE_CELL, TWO_PHOTON
using Distributions, Statistics

frontend = :None

include("utilities.jl")
export getChannelName

function __init__()
     @require CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0" begin
          using .CairoMakie
          frontend = :CairoMakie
          include("PhysMakie/MakiePlot.jl")
          include("PhysMakie/MakieRecipes.jl")
          export experimentplot, experimentplot!
          export twophotonframe, twophotonframe!
          export twophotonprojection, twophotonprojection!
          export plot, plot!
     end

     @require GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a" begin
          using .GLMakie #In the requires syntax, you need to include the using .Pkg syntax
          frontend = :GLMakie
          #include("PhysMakie/MakiePlot.jl")
          include("PhysMakie/MakieRecipes.jl")
          export experimentplot, experimentplot!
          export plot, plot!
     end

     @require PyPlot = "d330b81b-6aea-500a-939a-2ce795aea3ee" begin
          using .PyPlot
          frontend = :PyPlot
          #using PyPlot
          # Include all of the PyPlot functions
          include("PhysPyPlot/pyplot_plot.jl")
          export plot_experiment, waveplot , default_violin

          @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
               #println("Dataframes Loaded")
               @require Query = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1" begin
                    #println("Query Loaded")
                    include("PhysPyPlot/datasheet_plot.jl")
                    export plot_data_summary
               end
          end

          include("PhysPyPlot/PlottingAddons.jl")
          export add_scalebar, add_sig_bar, add_border
          export draw_gradient_box
     end
end

#=
# Write your package code here.
include("DefaultSettings.jl") #This requires PyPlot
export plot_experiment
=#

end
