#We need an auxillary function 
function is_cmap(color)
    try
        plt.get_cmap(color)
        return true
    catch
        return false
    end
end

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

function waveplot(axis, exp::Experiment; spacing = 100)
    for (idx, trial) in enumerate(eachtrial(exp))
        data_trial = trial + ((idx-1) * spacing)
        plot_experiment(axis, data_trial)
    end
end