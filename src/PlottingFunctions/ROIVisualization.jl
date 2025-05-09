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
    plot_roi_analysis_averaged(data::Experiment{TWO_PHOTON}; 
        channel_idx::Union{Int,Nothing}=nothing)

Create a visualization showing the ROI traces in two ways:
1. All stimulus traces stitched together for each ROI
2. Individual stimulus traces for each ROI, with each channel in a separate subplot

If channel_idx is provided, only that channel will be shown. Otherwise, all channels will be displayed.

Returns a Figure object containing all plots.
"""
function plot_roi_analysis_averaged(data::Experiment{TWO_PHOTON, T};
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
    fig = Figure(size=(1200, 400 * n_channels))
    
    # Process each channel
    for (ch_idx, channel) in enumerate(channels_to_process)
        # Create a grid for this channel
        gl_channel = fig[ch_idx, 1] = GridLayout()
        
        # Create both axes
        ax_stitched = Axis(gl_channel[1,1], 
            title="Channel $channel - All Stimuli Stitched",
            xlabel="Time (s)", 
            ylabel="ΔF/F")
        
        ax_stims = Axis(gl_channel[1,2], 
            title="Channel $channel - Individual Stimuli",
            xlabel="Time (s)", 
            ylabel="ΔF/F")
        
        # Get significant ROIs for this channel
        sig_rois = unique([id for (id, traces) in analysis.rois 
            if any(t -> t.channel == channel && t.is_significant, traces)])
        
        # Initialize arrays to store all ROI data
        all_stitched_times = Float64[]
        all_stitched_traces = Float64[]
        all_individual_times = Float64[]
        all_individual_traces = Float64[]
        
        # Collect all ROI data
        for roi_id in sig_rois
            traces = filter(t -> t.channel == channel, analysis.rois[roi_id])
            if isempty(traces)
                continue
            end
            
            # Sort traces by stimulus index
            sort!(traces, by=t -> t.stimulus_index)
            
            # Collect traces
            for trace in traces
                # For stitched traces
                if isempty(all_stitched_times)
                    append!(all_stitched_times, trace.t_series)
                    append!(all_stitched_traces, trace.dfof)
                else
                    overlap_time = analysis.analysis_parameters[:delay_time]
                    overlap_idx = findfirst(t -> t >= overlap_time, trace.t_series)
                    if isnothing(overlap_idx)
                        overlap_idx = length(trace.t_series)
                    end
                    append!(all_stitched_times, trace.t_series[overlap_idx+1:end] .+ all_stitched_times[end] .- overlap_time)
                    append!(all_stitched_traces, trace.dfof[overlap_idx+1:end])
                end
                
                # For individual traces
                append!(all_individual_times, trace.t_series)
                append!(all_individual_traces, trace.dfof)
            end
        end
        
        # Calculate means across all ROIs
        # For stitched traces
        unique_times = unique(all_stitched_times)
        mean_stitched = zeros(length(unique_times))
        counts = zeros(length(unique_times))
        
        for (t, val) in zip(all_stitched_times, all_stitched_traces)
            idx = findfirst(isequal(t), unique_times)
            mean_stitched[idx] += val
            counts[idx] += 1
        end
        mean_stitched ./= counts
        
        # For individual traces
        n_points = length(traces[1].t_series)
        individual_traces_matrix = reshape(all_individual_traces, n_points, :)
        mean_individual = mean(individual_traces_matrix, dims=2)[:]
        
        # Plot means
        lines!(ax_stitched, unique_times, mean_stitched, 
            color=:blue, alpha=0.5)
        
        lines!(ax_stims, traces[1].t_series, mean_individual,
            color=:blue, alpha=0.5)
        
        # Add stimulus time indicators if available
        if haskey(analysis.analysis_parameters, :delay_time)
            delay_time = analysis.analysis_parameters[:delay_time]
            vlines!(ax_stitched, [delay_time], color=:red, linestyle=:dash)
            vlines!(ax_stims, [delay_time], color=:red, linestyle=:dash)
        end
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