module PhysiologyPlotting

using Dates
using Requires

using ElectroPhysiology
import ElectroPhysiology: Experiment, readABF, parseABF
import ElectroPhysiology: WHOLE_CELL, TWO_PHOTON
using Distributions, Statistics
using Statistics

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
          
          @require PhysiologyAnalysis = "123dc426-2d49-4783-ab3e-573ab3c498a8" begin
               using .PhysiologyAnalysis
               import .PhysiologyAnalysis: get_fit_parameters, get_significant_rois
               include("PlottingFunctions/ROIVisualization.jl")
               export plot_roi_analysis, plot_roi_analysis_averaged, plot_roi_analysis_stitched, plot_analysis, plot_fulltime_analysis, get_significant_traces, get_significant_traces_matrix
          end
     end

     @require GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a" begin
          println("GLMakie Loaded")
          using .GLMakie #In the requires syntax, you need to include the using .Pkg syntax
          frontend = :GLMakie
          #include("PhysMakie/MakiePlot.jl")
          include("PhysMakie/MakieRecipes.jl")
          export experimentplot, experimentplot!
          export plot, plot!

          @require PhysiologyAnalysis = "69cbc4a0-077e-48a7-9b45-fa8b7014b5ca" begin
               println("PhysiologyAnalysis Loaded")
               using .PhysiologyAnalysis
               import .PhysiologyAnalysis: get_fit_parameters, get_significant_rois
               import .PhysiologyAnalysis: baseline_trace
               include("PlottingFunctions/ROIVisualization.jl")
               export plot_roi_analysis
          end
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
