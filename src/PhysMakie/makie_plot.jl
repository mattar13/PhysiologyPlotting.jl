"""
     plot_experiment(ax)
"""
function plot_experiment(ax, EXP::Experiment; 
     channels=1, sweeps = :all, 
     yaxes=true, xaxes=true, #Change this, this is confusing
     xlims = nothing, ylims = nothing,
     color = :black, cvals = nothing, clims = (0.0, 1.0), #still want to figure out how this wil work
     ylabel = nothing, xlabel = nothing,
     linewidth = 1.0, kwargs...
)
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

function plot_experiment(EXP::Experiment{T}; layout = :sweeps, kwargs...) where T<:Real
     println(size(EXP))

end