# PhysiologyPlotting

[![License][license-img]](LICENSE)

[![][docs-stable-img]][docs-stable-url] 

[![][GHA-img]][GHA-url]

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://mattar13.github.io/ElectroPhysiology.jl/dev

[GHA-img]: https://github.com/mattar13/PhysiologyPlotting.jl/workflows/CI/badge.svg
[GHA-url]: https://github.com/mattar13/PhysiologyPlotting.jl/actions?query=workflows/CI

This is the plotting toolkit for the larger package ElectroPhysiology.jl
see documentation [here](https://github.com/mattar13/ElectroPhysiology.jl)


### Basic usage

~~~
#=====================================================================#
using ElectroPhysiology, PhysiologyPlotting
using GLMakie

#=[Open data]=========================================================#
data_fn = "<DATA_FILEPATH>"
save_fn = "<SAVE_FILEPATH"

data = readABF(filename)

#=[Plot data]=========================================================#
fig, axs = experimentplot(data)
save(save_fn, fig)
~~~
