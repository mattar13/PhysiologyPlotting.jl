function plot_experiment(ax, EXP::Experiment; kwargs...)
     line_arr = []
     x = EXP.t
     for (idx_ch, ch) in enumerate(eachchannel(EXP))
          for (idx_swp, trial) in enumerate(eachtrial(ch)) 
               y = trial.data_array[1, :, 1]
               #println(y)
               lin_ax = lines!(ax, x, y; kwargs...)
               push!(line_arr, lin_ax)
          end
     end
     
     #here are some settings
     hidespines!(ax, :t, :r)
     hidedecorations!(ax, grid = true, ticks = false, ticklabels = false)
     return line_arr
end