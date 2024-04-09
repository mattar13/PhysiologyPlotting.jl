import ElectroPhysiology.Experiment
#Makie.convert_arguments(P::Type{<:Lines}, exp::Experiment) = convert_arguments(P, exp.t, exp.data_array)

@recipe(ExperimentPlot, experiment) do scene
     Attributes(
          color = :black,
          linewidth = 5.0,
          subplot_dims = 3,
          test = "NotImplemented"
     )
end

function Makie.plot!(plot::ExperimentPlot)
     println(plot.test)
     exp = plot[:experiment][]
     time = exp.t
     data = exp.data_array[1,:,1]
     lines!(plot, time, data, color = plot.color, linewidth = plot.linewidth)
     plot
end