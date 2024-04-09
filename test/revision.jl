using Revise
using GLMakie
using ElectroPhysiology
using PhysiologyPlotting
PhysiologyPlotting.frontend
import ElectroPhysiology.create_signal_waveform!
#using Pkg; Pkg.activate("test")

#%% Fixing GLMakie plotting
root = raw"F:\Data\Patching"
file = "2024_01_25_ChAT-RFP_DSGC/Cell1/24125005.abf"
filename = joinpath(root, file)
data = readABF(filename)
create_signal_waveform!(data, "Cmd 0")

f = Figure(size = (4000, 5000))
ax1 = Axis(f[1,1], 
     xlabel = "Time (ms)", 
     ylabel = "$(data.chNames[1]) $(data.chUnits[1])"
)
ax2 = Axis(f[2,1], 
     xlabel = "Time (ms)", 
     ylabel = "$(data.chNames[2]) $(data.chUnits[2])" 
)
#ax2 = Axis(f[2,1])
line_arr = plot_experiment(ax1, data; channels = 1)
line_arr = plot_experiment(ax2, data; channels = 2)
display(f)

#%% Important to know which protocol is being run
data.HeaderDict["ProtocolPath"]
data.HeaderDict["nOperationMode"]
data.HeaderDict["dacNames"]
data.HeaderDict["dacUnits"]
GLMakie.save("IV_curve2_00.png", f)

#%%
using PyPlot
#%% We can  use maybe a gaussian curve to properly plot the points maximum value
xs = collect(1:6)
yvals = rand(100, maximum(xs))

#%%
fig, ax = plt.subplots(3, 2)
for i in xs
     ys = yvals[:, i]
     default_violin(ax[i], i, ys)
end

add_border(ax[1], xpad_ratio = 0.1, ypad_ratio = 0.1)
#%%
#%% Make and plot ERG episodic data
data = readABF(raw"C:\Users\mtarc\OneDrive - The University of Akron\Data\ERG\P14_Wildtype\2019_11_10_P14WT\Mouse2_P14_WT\BaCl_LAP4\Rods" |> parseABF)# |> data_filter
data_filter!(data)

#%% Generate a makie plot
dpi = 600
f = Figure(size = (2.5, 2.5))
ax1 = Axis(f[1,1], 
     title = "Experiment Plot Test",
     xlabel = "Time (ms)", 
     ylabel = "Response (μV)"
)
ax2 = Axis(f[2,1], 
     title = "Experiment Plot Test",
     xlabel = "Time (ms)", 
     ylabel = "Response (μV)"
)

line_arr = plot_experiment(ax1, data; color = :black)
line_arr = plot_experiment(ax2, data; color = :black)

line_arr[2].color = :blue
line_arr[3].color = :green

display(f)

#%%
fig = plot_experiment(data; color = :black)

f