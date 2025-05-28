using Revise
using ElectroPhysiology
using PhysiologyPlotting

using Pkg; Pkg.activate("test")
using GLMakie
using PhysiologyAnalysis
#using Pkg; Pkg.activate("test")
 
#Electrical Stimulus
img_fn = raw"F:\Data\Two Photon\2025-03-05-GRAB-DA-STRIATUM\grab-da_b4_str_stim500uA_3x_NOMF046.tif"
stim_fn = raw"F:\Data\Patching\2025-03-26-GRAB-DA_STR\25326050.abf"

img_exp = readImage(img_fn);
deinterleave!(img_exp)
stim_exp = readABF(stim_fn);
addStimulus!(img_exp, stim_exp, "IN 3", flatten_episodic = true, stimulus_threshold = 0.5)
stim_protocol = getStimulusProtocol(img_exp)
spike_train_group!(stim_protocol, 3.0)

# Example of using stimulus timing and scale bar recipes
z_profile = project(img_exp, dims=(1,2))[1,1,:,1]
baseline_trace = PhysiologyAnalysis.baseline_trace(z_profile, 
    window = 5, 
    lam = 1e4,
    niter = 100
)
time_axis = data2P.t

#%% Plot 
fig = Figure(size=(800, 400))
ax = Axis(fig[1,1], 
    title="Example with Stimulus Timing and Scale Bars",
    xlabel="Time (s)",
    ylabel="Signal Intensity"
)

# Plot the z-profile trace for channel 1
lines!(ax, time_axis, baseline_trace, color=:green, linewidth=2.5)
# Add scale bars

stimulustiming!(ax, img_exp,
    show_start = true,
    show_end = true,
    show_span = true,
    start_color = :blue,
    end_color = :red,
    span_color = :gray,
    span_alpha = 0.25
)
display(fig)

#%%
scalebar!(ax, 
    start_x = 40.0,  # Start at 40 seconds
    length_x = 25.0, # 25 second scale bar
    start_y = 0.005, # Start at 0.005 intensity
    length_y = 0.1,  # 0.1 intensity scale bar
    x_label = "25 s",
    y_label = "0.1"
)
fig

#%%
fig = plot_roi_analysis(data2P, stim_idx = 2)
display(fig)
save(raw"H:\Data\Analysis\fig_roi_analysis_striatum_elec.png", fig)

# Save the ROI analysis figure