using Revise
using ElectroPhysiology
using PhysiologyPlotting

using Pkg; Pkg.activate("test")
using GLMakie
using PhysiologyAnalysis
#using Pkg; Pkg.activate("test")

#Loading data for 10mM Dopamine 
img_da_10mM_fn = raw"F:\Data\Two Photon\2025-05-19-nirCAT-STR-DPUFF\nirCAT_s2_10mM_mq010.tif"
stim_da_10mM_fn = raw"F:\Data\Patching\2025-05-19-nirCAT-str\25519016.abf"
da_10mM_data = load_puffing_data(img_da_10mM_fn, stim_da_10mM_fn, split_channel = true, main_channel = :red)

#%%
PhysiologyPlotting.__init__()
fig_roi = plot_roi_analysis(da_10mM_data["experiment"], stim_idx = 2)

experiment = da_10mM_data["experiment"]
getStimulusProtocol(experiment)
fig, ax = twophotonprojection(experiment, dims = (1, 2))
stimulustiming!(ax, experiment)

scalebar!(ax, 
    origin = (0.5, 0.01),  # Start at 40 seconds
    length_x = 25.0, # 25 second scale bar
    length_y = 0.001,  # 0.1 intensity scale bar
    x_label = "25 s",
    y_label = "1% df/f"
)
fig

#%%
# fig = plot_roi_analysis(data2P, stim_idx = 2)
# display(fig)
# save(raw"H:\Data\Analysis\fig_roi_analysis_striatum_elec.png", fig)

# Save the ROI analysis figure