import ElectroPhysiology.Experiment
#Makie.convert_arguments(P::Type{<:Lines}, exp::Experiment) = convert_arguments(P, exp.t, exp.data_array)

@recipe(ExperimentPlot, experiment) do scene
     Attributes(
          color = :black,
          linewidth = 2.0,
          channel = 1 #Also can be -1 for plotting all channels
     )
end

function Makie.plot!(plot::ExperimentPlot)
     exp = plot.experiment[]
     time = exp.t
     data = exp.data_array
     ch = plot.channel[]
     if ch > 0
          for trial in axes(exp,1)
               lines!(plot, time, data[trial,:,ch], 
                    color = plot.color, linewidth = plot.linewidth,
               )
          end
     else
          #still working this one out
          
     end
     plot
end