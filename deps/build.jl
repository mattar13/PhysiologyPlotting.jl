import Pkg, Conda
@info "Building PyCall for PyPlot from CONDA!"
Conda.pip_interop(true)
Conda.pip("install", "matplotlib")
Conda.add("matplotlib")
ENV["PYTHON"] = joinpath(Conda.ROOTENV, "bin", "python")
Pkg.build("PyCall")
@info "PyCall successfully build"