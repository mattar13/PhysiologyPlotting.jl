using Revise
using ElectroPhysiology
using PhysiologyPlotting

import ElectroPhysiology.create_signal_waveform!
using Pkg; Pkg.activate("test")
using GLMakie
using PhysiologyAnalysis
#using Pkg; Pkg.activate("test")
 

# ╔═╡This task is for extraction of points, centroids, and ROIs using cellpose
img_fn = raw"F:\Data\Two Photon\2025-05-02-GRAB-DA-nirCAT-STR\grab-nircat-str-kpuff_3x012.tif"
stim_fn = raw"F:\Data\Patching\2025-05-02-GRAB-DA-STR\25502017.abf"

#We should look through the available files and see which ones fit
img_fn = raw"F:\Data\Two Photon\2025-05-02-GRAB-DA-nirCAT-STR\grab-nircat-str-20hz-100uA001.tif"
stim_fn = raw"F:\Data\Patching\2025-05-02-GRAB-DA-STR\25502000.abf"

#We should look through the available files and see which ones fit
img_fn = raw"F:\Data\Two Photon\2025-05-02-GRAB-DA-nirCAT-STR\grab-nircat-str-20hz-100uA001.tif"
stim_fn = raw"F:\Data\Patching\2025-05-02-GRAB-DA-STR\25502000.abf"

data2P = readImage(img_fn);
deinterleave!(data2P) #This seperates the movies into two seperate movies

spike_train = true
if spike_train
    #If we have a electrical stimulus we need to do the spike train analysis
    addStimulus!(data2P, stim_fn, "IN 3", flatten_episodic = true, stimulus_threshold = 0.5)
    stim_protocol = getStimulusProtocol(data2P)
    spike_train_group!(stim_protocol, 3.0) 
else
    #Else we can just use the stimulus to get the time of the stimulus
    addStimulus!(data2P, stim_fn, "IN 2", flatten_episodic = true)
    time2P = data2P.t
end

# Split the image into 8x8 pixel ROIs
pixel_splits_roi!(data2P, 8)

# Process all ROIs for channel 2 and stimulus 2
roi_analysis = process_rois(data2P; 
    channels=[1, 2],           # Only process channel 2
    stim_indices=nothing,      # Only process the second stimulus
    delay_time=50.0,       # 50ms delay time for analysis
    sig_window=50.0,        # 50ms window to look for significant responses after stimulus
    window = 15,             # 15-point window for moving average
    n_stds = 5.0, 
    lam = 1e4,  #These are baselineing parameters
    niter = 100
)

# Store the analysis in the experiment's HeaderDict
# data2P.HeaderDict["ROI_Analysis"] = roi_analysis
data2P.HeaderDict["ROI_Analysis"]
# Get all significant ROIs and print summary
sig_rois = get_significant_rois(roi_analysis)
println("Found $(length(sig_rois)) significant ROIs")

# Get fit parameters and print summary statistics
fit_params = get_fit_parameters(roi_analysis)
println("Mean amplitude of significant ROIs: ", mean(first.(fit_params)))

fig = plot_roi_analysis(data2P, stim_idx = 2)
display(fig)


#%% Test the new simple analysis plot function
PhysiologyPlotting.__init__()
fig_raw = PhysiologyPlotting.plot_analysis(data2P)
display(fig_raw)