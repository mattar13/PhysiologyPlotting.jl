module PhysiologyPlotting

using Dates
using Requires

using ElectroPhysiology
import ElectroPhysiology: Experiment, readABF, parseABF
using DataFrames, Query
using Distributions, Statistics

frontend = :None

using PyCall

#using Plots
#println(Plots) 

#using PyPlot
#println(PyPlot)

# Include all the plotting utilities
include("utilities.jl")

"""


"""
function plot_experiment(args...) 
     @warn "One of the frontends must first be loaded."
     @info """
     Please load and use one of the following
     using GLMakie
     using CairoMakie
     using PyPlot
     """
end
export plot_experiment


function __init__()
     @require CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0" begin
          frontend = :CairoMakie
          using CairoMakie
          include("PhysMakie/makie_plot.jl")
          export draw_circle, draw_arrow_with_text
     end

     @require GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a" begin
          frontend = :GLMakie
          using GLMakie
          include("PhysMakie/makie_plot.jl")
          export draw_circle, draw_arrow_with_text
     end

     @require PyPlot = "d330b81b-6aea-500a-939a-2ce795aea3ee" begin
          frontend = :PyPlot
          using PyPlot
          # Include all of the PyPlot functions
          include("PhysPyPlot/pyplot_plot.jl")
          export plot_experiment, waveplot , default_violin

          @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
               include("PhysPyPlot/datasheet_plot.jl")
               export plot_data_summary
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
