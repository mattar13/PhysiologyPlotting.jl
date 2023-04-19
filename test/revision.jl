using Revise
using ElectroPhysiology
using PhysiologyPlotting
using PyPlot; PyPlot.pygui(true)

#%% Section 1. Revision of some plotting tools
test_file = raw"test/to_analyze.abf"
data = readABF(test_file)
average_sweeps!(data)
#filt_data = data_filter(data)
data *= 1000.0
baseline_adjust!(data)
truncate_data!(data, t_post = 5.0)

#%%
fig, ax = plt.subplots(1)
plot_experiment(ax, data, channels = 2, color = :black, alpha = 0.2, xlims = (-0.25, 5.0))
plot_experiment(ax, filt_data, channels = 2, color = :red, xlims = (-0.25, 5.0))
fig