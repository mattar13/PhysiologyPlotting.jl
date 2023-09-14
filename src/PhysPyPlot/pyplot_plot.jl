"""
    is_cmap(color::Any)

Check if the given `color` is a valid colormap.

# Arguments
- `color`: The color or colormap to check.

# Returns
- `true` if `color` is a valid colormap, `false` otherwise.

# Examples
```julia
is_valid = is_cmap("viridis")
"""
function is_cmap(color)
    try
        plt.get_cmap(color)
        return true
    catch
        return false
    end
end


"""
    plot_experiment(axis::T, exp::Experiment; kwargs...)
    plot_experiment(axis::Vector{T}, exp::Experiment; kwargs...)
    plot_experiment(exp::Experiment; kwargs...)

Plot the experiment data on the given axis or axes.

# Arguments
- `axis`: A single axis or a vector of axes to plot on.
- `exp`: The `Experiment` object containing the data.

#Keyword Arguments
- `channels` DEFAULT[1]: The channels to be plotted 
- `sweeps` DEFAULT[:all]: The sweeps to be plotted
- `yaxes` DEFAULT[true]: Whether or not the yaxes should be plotted 
- `xaxes` DEFAULT[true]: Wether or not the xaxes should be plotted
- `xlims` DEFAULT[nothing] 
- `ylims` DEFAULT[nothing]
- `color` DEFAULT[:black] 
- `cvals` DEFAULT[nothing] 
- `clims` DEFAULT[(0.0, 1.0)]
- `ylabel` DEFAULT[nothing] 
- `xlabel` DEFAULT[nothing]
- `linewidth` DEFAULT[1.0]

- `kwargs`: These are keyword arguments common to PyPlot.jl. 
    Please see: https://github.com/JuliaPy/PyPlot.jl or https://matplotlib.org/stable/index.html
    for further documentation


# Returns
- The plot object.

# Examples
```julia
plot_experiment(axis, my_experiment; channels=1, sweeps=:all)
"""
function plot_experiment(axis::T, exp::Experiment;
    channels=1, sweeps = :all, 
    yaxes=true, xaxes=true, #Change this, this is confusing
    xlims = nothing, ylims = nothing,
    color = :black, cvals = nothing, clims = (0.0, 1.0), #still want to figure out how this wil work
    ylabel = nothing, xlabel = nothing,
    linewidth = 1.0, 
    kwargs...
) where T
    dataX, dataY = plot_prep(exp; channels=channels, sweeps = sweeps)
    if is_cmap(color)
        if isnothing(cvals)
            sweeps_idxs = axes(dataY, 2) |> collect
            cvals = sweeps_idxs./size(dataY, 2) #Normalize the data
        end
        cmapI = plt.get_cmap(color)
        for (swp, cval) in enumerate(cvals)
            axis.plot(dataX, dataY[:, swp], c = cmapI(cval), linewidth = linewidth, kwargs...)
        end
    else
        axis.plot(dataX, dataY; c = color, kwargs...)
    end
    axis.spines["top"].set_visible(false)
    axis.spines["right"].set_visible(false)
    if !(yaxes)
        axis.spines["left"].set_visible(false)
        axis.yaxis.set_visible(false)
    end
    if !(xaxes)
        axis.spines["bottom"].set_visible(false) #We want the spine to fully
        axis.xaxis.set_visible(false)
    end

    if !isnothing(xlabel)
        axis.set_xlabel(xlabel)
    else
        axis.set_xlabel("Time (s)")
    end

    if !isnothing(ylabel)
        axis.set_ylabel(ylabel)
    else
        axis.set_ylabel("$(exp.chNames[channels]) ($(exp.chUnits[channels]))")
    end

    if !isnothing(xlims)
        axis.set_xlim(xlims)
    end

    if !isnothing(ylims)
        axis.set_ylim(ylims)
    end
    #end
end

function plot_experiment(axis::Vector{T}, exp::Experiment; kwargs...) where T #Is going to be a py object
    #This is for if there are multiple axes
    for (ch, axis) in enumerate(axis)
        if ch == 1
            plot_experiment(axis::T, exp::Experiment; channels=ch, include_xlabel = false, kwargs...)
        else
            plot_experiment(axis::T, exp::Experiment; channels=ch, kwargs...)
        end
    end
end

function plot_experiment(exp::Experiment; layout = nothing, channels = nothing, st = :trace, kwargs...)
    if st == :trace
        if !isnothing(layout)
            plot_layout = layout
        elseif !isnothing(channels)
            if isa(channels, Vector{Int64}) || isa(channels, Vector{String})
                plot_layout = (length(channels))
            elseif isa(channels, Int64) || isa(channels, String)
                plot_layout = 1
            end
        else
            plot_layout = (size(exp, 3))
        end
        fig, axis = plt.subplots(plot_layout)
        if plot_layout == 1 || plot_layout == (1)
            plot_experiment(axis, exp::Experiment; channels=1, kwargs...)
        else
            for (ch, axis) in enumerate(axis)
                plot_experiment(axis, exp::Experiment; 
                    channels=ch, 
                    xlabel = ch == length(exp.chNames),
                    kwargs...
                )
            end
        end
        return fig
    elseif st == :waveplot
        return nothing
    elseif st == :trace3D
        return nothing
    end
end

"""
    waveplot(axis, exp::Experiment; kwargs...)

Plot the waveform of the experiment data on the given axis.

# Arguments
- `axis`: The axis to plot on.
- `exp`: The `Experiment` object containing the data.
- Various keyword arguments to customize the plot.

# Returns
- The plot object.

# Examples
```julia
waveplot(axis, my_experiment; spacing=100, color=:black)

"""
function waveplot(axis, exp::Experiment; spacing = 100, color = :black, cvals = nothing, kwargs...)
    sweep_size = size(exp,1)
    for (idx, trial) in enumerate(eachtrial(exp))
        data_trial = trial + ((idx-1) * spacing)
        if !is_cmap(color)
            plot_experiment(axis, data_trial; color = color, kwargs...)
        elseif isnothing(cvals)
            plot_experiment(axis, data_trial; color = color, cvals = [idx/sweep_size], kwargs...)
        else
            plot_experiment(axis, data_trial; color = color, cvals = [cvals[idx]], kwargs...)
        end
    end
end

"""
    default_violin(ax, x::Union{Int64, UnitRange, Vector}, yvals::Union{Vector, Matrix}; kwargs...)

Create a violin plot on the given axis.

# Arguments
- `ax`: The axis to plot on.
- `x`: The x-coordinate(s) for the violin plot.
- `yvals`: The y-values for the violin plot.
- Various keyword arguments to customize the plot.

# Returns
- The violin plot object.

# Examples
```julia
default_violin(ax, 1, [1.0, 2.0, 3.0])

"""
function default_violin(ax, x::Int64, yvals::Vector; color = :black, alpha = 0.3, plot_jitter = true, s = 15.0, kwargs...)
    vp = ax.violinplot(yvals, [x]; showmeans = true, kwargs...)
    for pc in vp["bodies"]
         pc.set_facecolor(color)
         pc.set_edgecolor("black")
         pc.set_alpha(alpha)
    end
    vp["cbars"].set(colors = color)
    vp["cmeans"].set(colors = color)
    vp["cmins"].set(colors = color)
    vp["cmaxes"].set(colors = color)
    if plot_jitter
        # Extract the density values from the violin plot
        body = vp["bodies"][1]
        paths = body.get_paths()[1]
        vertices = paths.vertices
        x_values = vertices[:, 1]
        y_values = vertices[:, 2]
        
        # Generate jittered x-values for scatter points based on the violin plot density
        xs = map(y -> begin
            # Find the index of the y-value in the violin plot that is closest to the current y-value
            idx = argmin(abs.(y_values .- y))
            
            # Get the x-value (density) at that index from the violin plot
            x_jitter = x_values[idx]
            
            # Calculate the jittered x-value:
            # 1. (x_jitter - x): Distance from the center of the violin to the edge at this y-value
            # 2. (rand() - 0.5): Random factor for jitter, ranges from -0.5 to 0.5
            # 3. * 2: Amplifies the jitter to make it more noticeable
            x + (x_jitter - x) * (rand() - 0.5) * 2  # Calculate and scale the jitter
        end, yvals)
        
        ax.scatter(xs, yvals, color = color, s = s)
    end
    return vp
end

function default_violin(ax, x::Union{UnitRange, Vector}, yvals::Matrix; kwargs...)
    for (i, val) in enumerate(x)
        default_violin(ax, val, yvals[:, i])
    end
end

# utilities