println("I am being build")

ENV["PYTHON"] = ""
println("Building PyCall from Python version")
using Pkg; Pkg.build("PyCall")