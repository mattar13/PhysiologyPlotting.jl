module PhysiologyPlotting

using ElectroPhysiology
import ElectroPhysiology: Experiment, readABF, parseABF
using DataFrames, Query

using PyCall
ENV["PYTHON"] = ""
#using Pkg; Pkg.build("PyCall")
#using Plots
#println(Plots) 

using PyPlot
println(PyPlot)

# Include all the plotting utilities
include("utilities.jl")

# Include all of the PyPlot functions
include("PhysPyPlot.jl")
export plot_experiment

println("Dataframes loaded")
include("DatasheetPlotting.jl")
export plot_data_summary


#=
# Write your package code here.
include("DefaultSettings.jl") #This requires PyPlot
export plot_experiment
=#

end
