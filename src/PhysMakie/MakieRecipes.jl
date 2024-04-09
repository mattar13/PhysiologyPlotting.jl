using GLMakie
@recipe(PlotExperiment) do scene
     Theme(
          plot_color = :red,
          linewidth = 10.0
     )
end

function GLMakie.plot!(plot_experiment::PlotExperiment)
     lines!(plot_experiment, rand(10), color = myplot.plot_color, linewidth = myplot.linewidth)
     plot_experiment
end

fig = Figure()
ax1 = Axis(fig[1,1])
plot_experiment!(ax1)
