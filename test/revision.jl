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