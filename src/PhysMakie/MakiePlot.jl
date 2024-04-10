"""
This function takes the experiment and plots subplots
"""
function experimentplot(exp::Experiment; 
     subplot = :channels, figsize = (800, 400)
     
)    
     n_trials, n_data, n_channels = size(exp)
     fig = Figure(size = figsize)
     axs = Axis[]
     for ch in 1:n_channels
          ch_name = getChannelName(exp, ch)
          ax_i = Axis(fig[ch, 1], ylabel = ch_name)
          experimentplot!(ax_i, exp, channel = ch)
          if ch == n_channels
               ax_i.xlabel = "Time (ms)"
          end
          push!(axs, ax_i)
     end
     return fig, axs
end