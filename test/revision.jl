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

#%%
fig = Figure()
ax1 = Axis(fig[1,1], ylabel = getChannelName(data, 1))
ax2 = Axis(fig[2,1], xlabel = "Time (ms)", ylabel = getChannelName(data, 2))
experimentplot!(ax1, data, channel = 1)
experimentplot!(ax2, data, channel = 2)
display(fig)

#%%
PhysiologyPlotting.__init__()
fig, axs = experimentplot(data)
display(fig)
#%%
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
GLMakie.save("IV_curve2_00.png", f)