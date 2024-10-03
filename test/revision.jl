using Revise
using ElectroPhysiology
using PhysiologyPlotting
PhysiologyPlotting.frontend
import ElectroPhysiology.create_signal_waveform!
using Pkg; Pkg.activate("test")
using GLMakie
#using Pkg; Pkg.activate("test")
 
#We want to plot images
file_loc = "G:/Data/Two Photon"
data2P_fn = "$(file_loc)/2024_09_03_SWCNT_VGGC6/swcntBATH_kpuff_nomf_20um001.tif"
data2P = readImage(data2P_fn);

xlims = data2P.HeaderDict["xrng"]
ylims = data2P.HeaderDict["yrng"]
deinterleave!(data2P) #This seperates the movies into two seperate movies

PhysiologyPlotting.__init__()
twophotonprojection(data2P, dims = (1, 2), channel = 2)

#%%
fig = Figure(figsize = (800, 800))
ax1 = Axis(fig[1,1], aspect = 1.0, title = "Frame 1")
frame = Observable(1)
tp = twophotonframe!(ax1, data2P, frame, channel = 2, colorrange = (0.0, 0.02))
fig
record(fig, "test/test.mp4", enumerate(data2P.t)) do (i, t)
     println(i)
     tp.frame[] = i
     ax1.title = "Frame $i"
end
#%%

#%%
img_arr = get_all_frames(data2P)
grn_zstack = img_arr[:,:,:,1]
grn_zproj = project(data2P, dims = (3))[:,:,1,1]
grn_trace = project(data2P, dims = (1,2))[1,1,:,1]

red_zstack = img_arr[:,:,:,2]
red_zproj = project(data2P, dims = (3))[:,:,1,2]
red_trace = project(data2P, dims = (1,2))[1,1,:,2]

#%% Plot the figure
fig = Figure(size = (1000, 800))
ax1a = GLMakie.Axis(fig[1,1], title = "Green Channel", aspect = 1.0)
ax1b = GLMakie.Axis(fig[2,1], title = "Red Channel", aspect = 1.0)

ax2a = GLMakie.Axis(fig[1,2], title = "Green Trace")#, aspect = 1.0)
ax2b = GLMakie.Axis(fig[2,2], title = "Red Trace")#, aspect = 1.0)

mu_grn = mean(grn_zstack)
sig_grn = std(grn_zstack)*2

mu_red = mean(red_zstack)
sig_red = std(red_zstack)*2

hm2a = heatmap!(ax1a, xlims, ylims, grn_zstack[:,:,1], colormap = Reverse(:algae), colorrange = (0.0, mu_grn + sig_grn))
hm2b = heatmap!(ax1b, xlims, ylims, red_zstack[:,:,1], colormap = :gist_heat, colorrange = (0.0, mu_red + 2sig_red), alpha = 1.0)



#%% 
root = raw"F:\Data\Patching"
file = "2024_01_25_ChAT-RFP_DSGC/Cell1/24125005.abf"
filename = joinpath(root, file)
data = readABF(filename)
create_signal_waveform!(data, "Cmd 0")
experimentplot(data)