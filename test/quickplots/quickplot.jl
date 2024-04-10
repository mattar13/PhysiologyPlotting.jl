#=====================================================================#
using ElectroPhysiology, PhysiologyPlotting
using GLMakie

#=[Open data]=========================================================#
data_fn = "F:/Data/Patching/2024_01_25_ChAT-RFP_DSGC/Cell1/24125005.abf"
save_fn = "quickplot.abf"

data = readABF(filename)
create_signal_waveform!(data, "Cmd 0")

#=[Plot data]=========================================================#
fig, axs = experimentplot(data)
save(save_fn, fig)