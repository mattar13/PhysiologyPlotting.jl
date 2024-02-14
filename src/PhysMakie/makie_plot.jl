"""
     plot_experiment(ax)
"""
function plot_experiment(ax, exp::Experiment, trial::Int64, channel::Int64; color = :black, kwargs...)
     println("Working with GLMakie")
     line_arr = []
     x = exp.t
     y = exp.data_array[trial, :, channel]
     #println(y)
     lin_ax = lines!(ax, x, y; color = color, kwargs...)
     push!(line_arr, lin_ax)
     hidespines!(ax, :t, :r)
     hidedecorations!(ax, grid = true, ticks = false, ticklabels = false, label = false)
     return line_arr
end

function plot_experiment(ax, exp::Experiment; trials::Union{Int64, Nothing} = nothing, channels::Union{Int64, Nothing} = nothing, kwargs...)
     n_trials, n_data, n_channels = size(exp)
     line_arr = []
     if isnothing(trials) && isnothing(channels) #plot all of the trials and channels
          for t in 1:n_trials, c in 1:n_channels
               line_ax = plot_experiment(ax, exp, t, c; kwargs...)
          end
     elseif isnothing(trials) && !isnothing(channels)
          for t in 1:n_trials
               line_ax = plot_experiment(ax, exp, t, channels; kwargs...)
          end
     elseif !isnothing(trials) && isnothing(channels)
          for c in 1:n_channels
               line_ax = plot_experiment(ax, exp, trials, c; kwargs...)
          end
     else
          line_ax = plot_experiment(ax, exp, trials, channels; kwargs...)
     end
     push!(line_arr, line_ax...)
     return line_arr
end

function plot_experiment(EXP::Experiment{T}; layout = :sweeps, kwargs...) where T<:Real
     println("I think this one is not as important at the moment")
     println(size(EXP))

end