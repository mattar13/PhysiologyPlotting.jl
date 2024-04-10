using Revise
using GLMakie
using ElectroPhysiology
using PhysiologyPlotting

#=[Open data]===============================================#
root = raw"F:\Data\Patching"
file = "2024_01_25_ChAT-RFP_DSGC/Cell1/24125005.abf"
filename = joinpath(root, file)
data = readABF(filename)
create_signal_waveform!(data, "Cmd 0")

#=[Plot data]===============================================#
fig, axs = experimentplot(data)

save("quickplot.png", fig)
