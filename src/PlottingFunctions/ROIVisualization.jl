# using GLMakie
# using Statistics
# using ElectroPhysiology, PhysiologyAnalysis

"""
    plot_roi_analysis(data::Experiment{TWO_PHOTON}; 
        stim_idx::Int=1, channel_idx::Union{Int,Nothing}=nothing)

Create a comprehensive visualization of ROI analysis results for a single stimulus event including:
1. ROI map showing significant ROIs weighted by their amplitude, overlaid on max projection
2. Individual dF/F traces for significant ROIs
3. Mean trace with standard deviation ribbon

If channel_idx is provided, only that channel will be shown. Otherwise, all channels will be displayed.

Returns a Figure object containing all plots.
"""
function plot_roi_analysis(data::Experiment{TWO_PHOTON, T};
    stim_idx::Int=1, channel_idx::Union{Int,Nothing}=nothing) where {T <: Real}
    
    @assert haskey(data.HeaderDict, "ROI_Analysis") "Data must contain ROI analysis results in HeaderDict"

    analysis = data.HeaderDict["ROI_Analysis"]
    delay_time = haskey(analysis.analysis_parameters, :delay_time) ? analysis.analysis_parameters[:delay_time] : nothing
    println("delay_time: ", delay_time)

    # Plot max projection as background
    xlims = data.HeaderDict["xrng"]
    ylims = data.HeaderDict["yrng"]

    # Determine which channels to process
    channels_to_process = isnothing(channel_idx) ? analysis.channels : [channel_idx]
    n_channels = length(channels_to_process)
    
    # Create figure with layout
    fig = Figure(size=(1200 * n_channels, 800))
    
    # Process each channel
    for (ch_idx, channel) in enumerate(channels_to_process)
        # Get significant ROIs for this channel and stimulus
        sig_rois = get_significant_rois(analysis, stim_idx, channel)
        
        # Create a 2x2 grid for this channel
        gl_channel = fig[1, ch_idx] = GridLayout()
        
        # 1. ROI amplitude map with max projection (top left)
        ax1 = Axis(gl_channel[1,1], title="Channel $channel Response Map (Stimulus $stim_idx)",
            xlabel="X Position (μm)", ylabel="Y Position (μm)",
            aspect=DataAspect())
        
        # Get max projection of original data
        max_proj = project(data, dims = (3))[:,:,1,channel]
        max_proj = rotr90(max_proj)
        norm_max_proj = (max_proj .- minimum(max_proj)) ./ (maximum(max_proj) - minimum(max_proj))
        hm1 = heatmap!(ax1, xlims, ylims, norm_max_proj)
        Colorbar(gl_channel[1,2], hm1, label="dF/F", width=15, vertical=true)
        
        # Create a sub-grid for the traces
        gl_traces = gl_channel[1,3] = GridLayout()
        
        # 2. Mean trace with std ribbon (top right, left half)
        ax2 = Axis(gl_traces[1,1], title="Mean Response ± STD (Stimulus $stim_idx)",
            xlabel="Time (s)", ylabel="ΔF/F")
        
        if !isempty(sig_rois)
            # Get all significant traces and calculate statistics
            sig_traces = [filter(t -> t.channel == channel && t.stimulus_index == stim_idx, analysis.rois[roi])[1].dfof for roi in sig_rois]
            t_series = filter(t -> t.channel == channel && t.stimulus_index == stim_idx, analysis.rois[first(sig_rois)])[1].t_series
            
            mean_trace = mean(sig_traces)
            std_trace = std(sig_traces)
            
            # Plot mean and standard deviation
            band!(ax2, t_series, 
                mean_trace .- std_trace, 
                mean_trace .+ std_trace,
                color=(:blue, 0.3))
            lines!(ax2, t_series, mean_trace, 
                color=:blue, linewidth=2,
                label="Mean (n=$(length(sig_rois)))")
        end
        
        # 3. Individual traces (top right, right half)
        ax3 = Axis(gl_traces[2,1], title="Individual ROI Traces (Stimulus $stim_idx)",
            xlabel="Time (s)", ylabel="ΔF/F")
        
        if !isempty(sig_rois)
            # Plot each significant ROI trace
            colors = cgrad(:viridis, length(sig_rois), categorical=true)
            for (i, roi_id) in enumerate(sig_rois)
                traces = filter(t -> t.channel == channel && t.stimulus_index == stim_idx, analysis.rois[roi_id])
                trace = traces[1]
                lines!(ax3, trace.t_series, trace.dfof, 
                    color=colors[i], alpha=0.5)
            end
        end
        
        # Link y-axes of the traces
        linkyaxes!(ax2, ax3)
        
        # Get ROI mask and create weighted map
        roi_mask = getROImask(data)
        roi_mask = rotr90(roi_mask)
        weighted_mask = zeros(size(roi_mask))
        tau_off_mask = zeros(size(roi_mask))
        
        for roi_id in keys(analysis.rois)
            if roi_id in sig_rois
                traces = filter(t -> t.channel == channel && t.stimulus_index == stim_idx, analysis.rois[roi_id])
                trace = traces[1]
                max_response = maximum(trace.dfof)
                weighted_mask[roi_mask .== roi_id] .= max_response
                if !isnothing(trace.fit_parameters) && length(trace.fit_parameters) >= 3
                    tau_off_mask[roi_mask .== roi_id] .= trace.fit_parameters[3]
                end
            end
        end
        
        # 4. Weighted response map (bottom left)
        ax_weighted = Axis(gl_channel[2,1], title="Channel $channel Weighted Response (Stimulus $stim_idx)",
            xlabel="X Position (μm)", ylabel="Y Position (μm)",
            aspect=DataAspect())
        
        if !isempty(sig_rois)
            hm_weighted = heatmap!(ax_weighted, xlims, ylims, weighted_mask,
                colormap=:viridis,
                colorrange=(0, maximum(weighted_mask)))
            Colorbar(gl_channel[2,2], hm_weighted, label="dF/F", width=15, vertical=true)
        else
            text!(ax_weighted, "No significant ROIs found", 
                position=(mean(xlims), mean(ylims)),
                align=(:center, :center),
                color=:red)
        end
        
        # 5. Tau Off map (bottom right)
        ax_tau = Axis(gl_channel[2,3], title="Channel $channel Tau Off (Stimulus $stim_idx)",
            xlabel="X Position (μm)", ylabel="Y Position (μm)",
            aspect=DataAspect())
        
        if !isempty(sig_rois)
            hm_tau = heatmap!(ax_tau, xlims, ylims, tau_off_mask,
                colormap=:viridis,
                colorrange=(0, maximum(filter(!iszero, tau_off_mask))))
            Colorbar(gl_channel[2,4], hm_tau, label="Tau Off (s)", width=15, vertical=true)
        else
            text!(ax_tau, "No significant ROIs found", 
                position=(mean(xlims), mean(ylims)),
                align=(:center, :center),
                color=:red)
        end
        
        # Add stimulus time indicator if available
        if haskey(analysis.analysis_parameters, :delay_time)
            delay_time = analysis.analysis_parameters[:delay_time]
            vlines!(ax2, [delay_time], color=:red, linestyle=:dash, label="Stimulus")
            vlines!(ax3, [delay_time], color=:red, linestyle=:dash, label="Stimulus")
        end
        
        # Add legend only for mean response
        axislegend(ax2, position=:rt)
    end
    
    return fig
end

"""
    plot_roi_analysis_stitched(data::Experiment{TWO_PHOTON}; 
        channel_idx::Union{Int,Nothing}=nothing)

Create a visualization showing ROI traces organized by channel (rows), with:
1. Stitched stimulus traces for each ROI
2. Averaged traces across ROIs for each stimulus

If channel_idx is provided, only that channel will be shown. Otherwise, all channels will be displayed.

Returns a Figure object containing all plots.
"""
function plot_roi_analysis_stitched(data::Experiment{TWO_PHOTON, T};
    channel_idx::Union{Int,Nothing}=nothing) where {T <: Real}
    
    @assert haskey(data.HeaderDict, "ROI_Analysis") "Data must contain ROI analysis results in HeaderDict"

    analysis = data.HeaderDict["ROI_Analysis"]
    
    # Determine which channels to process
    channels_to_process = isnothing(channel_idx) ? analysis.channels : [channel_idx]
    n_channels = length(channels_to_process)
    
    # Get all stimulus indices
    stim_indices = unique([t.stimulus_index for traces in values(analysis.rois) for t in traces])
    n_stims = length(stim_indices)
    
    # Create figure with layout
    fig = Figure(size=(800, 400 * n_channels))
    
    # Process each channel
    for (ch_idx, channel) in enumerate(channels_to_process)
        println("Creating grid for channel $channel")
        gl_channel = fig[ch_idx, 1] = GridLayout()
        ax_stitched = Axis(gl_channel[1,1], 
            title="Channel $channel - Stitched Stimuli (Mean ± STD)",
            xlabel="Time (s)", 
            ylabel="ΔF/F")
        
        # Second column: mean ± std for each stimulus (not stitched)
        ax_stimulus = Axis(gl_channel[1,2],
            title="Channel $channel - Per-Stimulus Mean ± STD",
            xlabel="Time (s)",
            ylabel="ΔF/F")
        
        # Get significant ROIs for this channel
        sig_rois = unique([id for (id, traces) in analysis.rois 
            if any(t -> t.channel == channel && t.is_significant, traces)])
        
        # For each ROI, create a stitched trace
        all_stitched_times = Vector{Vector{Float64}}()
        all_stitched_traces = Vector{Vector{Float64}}()
        min_length = typemax(Int)
        # New: store all individual ROI traces and times (not stitched)
        all_traces = Vector{Vector{Float64}}()  # just dfof
        all_times = Vector{Vector{Float64}}()   # just t_series
        
        for roi_id in sig_rois
            println("Processing ROI $roi_id")
            traces = filter(t -> t.channel == channel, analysis.rois[roi_id])
            if isempty(traces)
                continue
            end
            sort!(traces, by=t -> t.stimulus_index)
            stitched_times = Float64[]
            stitched_values = Float64[]
            for (i, trace) in enumerate(traces)
                println("Processing trace $i")
                # Store each ROI/stimulus trace (not stitched)
                push!(all_traces, trace.dfof)
                push!(all_times, trace.t_series)
                if i == 1
                    append!(stitched_times, trace.t_series)
                    append!(stitched_values, trace.dfof)
                else
                    overlap_time = analysis.analysis_parameters[:delay_time]
                    overlap_idx = findfirst(t -> t >= overlap_time, trace.t_series)
                    if isnothing(overlap_idx)
                        overlap_idx = length(trace.t_series)
                    end
                    append!(stitched_times, trace.t_series[overlap_idx+1:end] .+ stitched_times[end] .- overlap_time)
                    append!(stitched_values, trace.dfof[overlap_idx+1:end])
                end
            end
            push!(all_stitched_times, stitched_times)
            push!(all_stitched_traces, stitched_values)
            min_length = min(min_length, length(stitched_times))
        end
        
        # Truncate all traces to the minimum length for averaging
        if !isempty(all_stitched_traces)
            stitched_matrix = hcat([trace[1:min_length] for trace in all_stitched_traces]...)
            mean_trace = mean(stitched_matrix, dims=2)[:]
            std_trace = std(stitched_matrix, dims=2)[:]
            mean_time = all_stitched_times[1][1:min_length]
            band!(ax_stitched, mean_time, mean_trace .- std_trace, mean_trace .+ std_trace, color=(:blue, 0.3))
            lines!(ax_stitched, mean_time, mean_trace, color=:blue, linewidth=2, label="Mean (n=$(length(sig_rois)))")
        end
        
        # Calculate mean ± std of all traces for the second plot (no per-stimulus separation)
        if !isempty(all_traces)
            # Find the minimum length of all traces
            min_trace_length = minimum(length.(all_traces))
            # Create a matrix with all traces
            trace_matrix = hcat([tr[1:min_trace_length] for tr in all_traces]...)
            # Calculate mean and std
            all_mean_trace = mean(trace_matrix, dims=2)[:]
            all_std_trace = std(trace_matrix, dims=2)[:]
            # Use the first time vector for x-axis (they should all be the same)
            mean_time_axis = all_times[1][1:min_trace_length]
            # Plot mean with std ribbon
            band!(ax_stimulus, mean_time_axis, all_mean_trace .- all_std_trace, all_mean_trace .+ all_std_trace, color=(:blue, 0.3))
            lines!(ax_stimulus, mean_time_axis, all_mean_trace, color=:blue, linewidth=2, label="Mean (n=$(length(all_traces)))")
        end
        
        # Add stimulus time indicator if available
        if haskey(analysis.analysis_parameters, :delay_time)
            delay_time = analysis.analysis_parameters[:delay_time]
            vlines!(ax_stitched, [delay_time], color=:red, linestyle=:dash)
            vlines!(ax_stimulus, [delay_time], color=:red, linestyle=:dash)
        end
        # axislegend(ax_stitched, position=:rt)
    end
    return fig
end 

"""
    plot_analysis(data::Experiment{TWO_PHOTON}; 
        channel_idx::Union{Int,Nothing}=nothing)

A simple visualization showing the raw z-profile traces for each channel.
This represents the mean intensity over time for the entire field of view.

If channel_idx is provided, only that channel will be shown. Otherwise, all channels will be displayed.

Returns a Figure object containing the plots.
"""
function plot_analysis(data::Experiment{TWO_PHOTON, T};
    channel_idx::Union{Int,Nothing}=nothing) where {T <: Real}
    @assert haskey(data.HeaderDict, "ROI_Analysis") "Data must contain ROI analysis results in HeaderDict"
    analysis = data.HeaderDict["ROI_Analysis"]

    # Determine which channels to process
    if isnothing(channel_idx)
        channels_to_process = collect(1:size(data, 3))
    else
        channels_to_process = [channel_idx]
    end
    n_channels = length(channels_to_process)
    
    # Create figure with layout
    fig = Figure(size=(1000, 300 * n_channels))
    
    sig_traces = get_significant_traces(analysis)
    # Process each channel
    for (ch_idx, channel) in enumerate(channels_to_process)
        # Create an axis for this channel
        ax = Axis(fig[ch_idx, 1], 
            title="Channel $channel - Z-Profile Trace",
            xlabel="Time (s)", 
            ylabel="Signal Intensity")

        ax_average = Axis(fig[ch_idx, 2], 
            title="Channel $channel - Average of Significant Traces",
            xlabel="Time (s)", 
            ylabel="Signal Intensity")
        #ax average should be 1/4 the width of ax
        colsize!(fig.layout, 2, Relative(0.25))
        
        # Link y-axes
        linkyaxes!(ax, ax_average)
        
        # Remove grid and axes
        # hidespines!(ax)
        # hidedecorations!(ax)
        # hidespines!(ax_average)
        # hidedecorations!(ax_average)
        
        # Get z-profile trace for this channel (mean intensity over time)
        z_profile = project(data, dims=(1,2))[1,1,:,channel]
        baseline_trace = PhysiologyAnalysis.baseline_trace(z_profile, 
            window = 5, 
            lam = 1e4,
            niter = 100
            )
        time_axis = data.t
        
        #Calculate the mean of the significant traces for this channel
        sig_traces_matrix = sig_traces[:,:,channel]
        mean_sig_trace = mean(sig_traces_matrix, dims=1)[1,:]
        time_axis_segment = collect(1:length(mean_sig_trace)) * data.dt
        # Plot the trace
        if channel == 1
            #lines!(ax, time_axis, z_profile, color=:green, linewidth=2.5)
            lines!(ax, time_axis, baseline_trace, color=:green, linewidth=2.5)
            lines!(ax_average, time_axis_segment, mean_sig_trace, color=:green, linewidth=2.5)
        else
            lines!(ax, time_axis, baseline_trace, color=:red, linewidth=2.5)
            lines!(ax_average, time_axis_segment, mean_sig_trace, color=:red, linewidth=2.5)
        end
        delay_time = haskey(analysis.analysis_parameters, :delay_time) ? analysis.analysis_parameters[:delay_time] : nothing
        vlines!(ax_average, [delay_time], color=:black, linestyle=:dash)

        # Add x and y scale bars to lower left of raw trace axis
        if channel == 1
            xbar_length = 25.0  # seconds
            ybar_length = 0.1   # adjust to your data's scale

            x0 = 40.0#minimum(time_axis) + 0.05 * (maximum(time_axis) - minimum(time_axis))
            y0 = 0.005#minimum(baseline_trace) + 0.1 * (maximum(baseline_trace) - minimum(baseline_trace))
            # x scale bar
            lines!(ax, [x0, x0 + xbar_length], [y0, y0], color=:black, linewidth=3)
            text!(ax, "$xbar_length s", position=(x0 + xbar_length/2, y0 - 0.1*ybar_length), align=(:center, :center), color=:black)
        
            lines!(ax_average, [x0, x0 + xbar_length], [y0, y0], color=:black, linewidth=3)
            text!(ax_average, "$xbar_length s", position=(x0 + xbar_length/2, y0 - 0.1*ybar_length), align=(:center, :center), color=:black)

            lines!(ax, [x0, x0], [y0, y0 + ybar_length], color=:black, linewidth=3)
            text!(ax, "$ybar_length", position=(x0 - 0.1*xbar_length, y0 + ybar_length/2), align=(:center, :center), color=:black)
        else# y scale bar
            xbar_length = 25.0  # seconds
            ybar_length = 0.01   # adjust to your data's scale

            x0 = 40.0#minimum(time_axis) + 0.05 * (maximum(time_axis) - minimum(time_axis))
            y0 = 0.005#minimum(baseline_trace) + 0.1 * (maximum(baseline_trace) - minimum(baseline_trace))
            
            lines!(ax, [x0, x0 + xbar_length], [y0, y0], color=:black, linewidth=3)
            text!(ax, "$xbar_length s", position=(x0 + xbar_length/2, y0 - 0.1*ybar_length), align=(:center, :center), color=:black)
        
            lines!(ax_average, [x0, x0 + xbar_length], [y0, y0], color=:black, linewidth=3)
            text!(ax_average, "$xbar_length s", position=(x0 + xbar_length/2, y0 - 0.1*ybar_length), align=(:center, :center), color=:black)

            lines!(ax, [x0, x0], [y0, y0 + ybar_length], color=:black, linewidth=3)
            text!(ax, "$ybar_length", position=(x0 - 0.1*xbar_length, y0 + ybar_length/2), align=(:center, :center), color=:black)
        end

        # Add stimulus lines if available
        if haskey(data.HeaderDict, "StimulusProtocol")
            stim_protocol = data.HeaderDict["StimulusProtocol"]
            stim_end_times = getStimulusEndTime(stim_protocol)
            vlines!(ax, stim_end_times, color=:black, linestyle=:dash, alpha = 0.5)
        end
    end
    
    return fig
end 


"""
    get_significant_traces(analysis)

Return a 3D array (n_ROIs, n_datapoints, n_channels) of all significant ROI traces.
All traces are truncated to the global minimum length for consistency.
"""
function get_significant_traces(analysis)
    # Gather all significant traces and their channels
    traces_list = Vector{Tuple{Int, Vector{Float64}}}()
    min_length = typemax(Int)
    n_channels = length(analysis.channels)
    
    for (roi_id, traces) in analysis.rois
        for trace in traces
            if trace.is_significant
                push!(traces_list, (trace.channel, trace.dfof))
                min_length = min(min_length, length(trace.dfof))
            end
        end
    end
    
    # If no significant traces, return empty array
    n_rois = length(traces_list)
    if n_rois == 0 || min_length == 0
        return zeros(0, 0, n_channels)
    end
    
    # Allocate output array
    result = zeros(n_rois, min_length, n_channels)
    for (i, (ch, dfof)) in enumerate(traces_list)
        result[i, :, ch] = dfof[1:min_length]
    end
    return result
end 