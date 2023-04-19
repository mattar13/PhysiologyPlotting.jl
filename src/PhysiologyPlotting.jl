module PhysiologyPlotting

using ElectroPhysiology
import ElectroPhysiology: Experiment, readABF, parseABF

using Plots, PyPlot

# Include all the plotting utilities
include("utilities.jl")

# Include all of the PyPlot functions
include("PhysPyPlot.jl")
export plot_experiment

#=
# Write your package code here.
include("DefaultSettings.jl") #This requires PyPlot
export plot_experiment
=#

end
