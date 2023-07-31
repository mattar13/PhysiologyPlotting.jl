using Revise
using ElectroPhysiology
using PyPlot; PyPlot.pygui(true)
using PhysiologyPlotting
#%% Make a wave plot


#%% Section 1. Revision of some plotting tools
test_file = raw"test/to_analyze.abf"
data = readABF(test_file) |> data_filter
data_ch1 = getchannel(data, 1)
#%%
#We need a method to sort the files by the photon intensity without actually measuring it
fig, axs = plt.subplots(2)
waveplot(axs[1], data_ch1)
plot_experiment(axs[2], data_ch1)

#%%
cvals = minimum(data, dims = 2)[:,1,1]
cvals .-= minimum(cvals)
cvals ./= maximum(cvals)
fig = plot_experiment(data, xlims = (-0.1, 3.2), linewidth=3.0, ylabel = "Voltage (μV)", channels = "Vm_prime", cvals = cvals, color = "brg");
fig.savefig(raw"C:\Users\mtarc\The University of Akron\RetinaRig - General\Presentations\logo.svg", transparent=true)
     #channels = "Vm_prime", color = "turbo",   
#%%
fig, ax = plt.subplots(1)
plot_experiment(ax, data, channels = 2, color = :black, alpha = 0.2, xlims = (-0.25, 5.0))
fig