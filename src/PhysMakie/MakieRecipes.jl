#Makie.convert_arguments(P::Type{<:Lines}, exp::Experiment) = convert_arguments(P, exp.t, exp.data_array)

"""
    @recipe(ExperimentPlot, experiment)

A recipe for plotting time series data from an Experiment object. This recipe creates a line plot
showing the time series data for each trial in the experiment.

# Attributes
- `color`: The color of the lines (default: :black)
- `linewidth`: The width of the lines (default: 2.0)
- `channel`: The channel to plot (default: 1). Use -1 to plot all channels.

# Example
```julia
fig = Figure()
ax = Axis(fig[1,1])
experiment_plot!(ax, my_experiment, channel=1)
```
"""
@recipe(ExperimentPlot, experiment) do scene
     Attributes(
          color = :black,
          linewidth = 2.0,
          channel = 1 #Also can be -1 for plotting all channels
     )
end

"""
    Makie.plot!(plot::ExperimentPlot)

Internal plotting function for ExperimentPlot recipe. Plots time series data for each trial
in the experiment, with options for channel selection and line styling.
"""
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

"""
    @recipe(TwoPhotonFrame, experiment, frame)

A recipe for plotting a single frame from a two-photon imaging experiment. This recipe creates
an image plot showing the specified frame with customizable colormap and color range.

# Attributes
- `channel`: The channel to display (default: nothing)
- `colormap`: The colormap to use (default: :gist_heat)
- `colorrange`: The range of values to map to colors (default: nothing, will be set to min/max of data)

# Example
```julia
fig = Figure()
ax = Axis(fig[1,1])
two_photon_frame!(ax, my_experiment, frame=1, channel=1)
```
"""
@recipe(TwoPhotonFrame, experiment, frame) do scene
     Attributes(
          channel = nothing,
          colormap = :gist_heat,
          colorrange = Observable{Any}(nothing),
     )
end

"""
    Makie.plot!(tpf::TwoPhotonFrame)

Internal plotting function for TwoPhotonFrame recipe. Creates an image plot of a single frame
from a two-photon imaging experiment, with proper spatial scaling and color mapping.
"""
function Makie.plot!(tpf::TwoPhotonFrame{<:Tuple{<:Experiment{TWO_PHOTON}, <:Integer}})
     #Extract the 
     exp = tpf.experiment[]
     frame = tpf.frame
     channel = tpf.channel
 
     #println("Frame: $frame_value, Channel: $channel")
 
     xlims = exp.HeaderDict["xrng"]
     ylims = exp.HeaderDict["yrng"]
 
    # Use @lift to reactively update image_data
    image_data = @lift(get_frame(exp, $frame)[:, :, 1, $channel])
 
     # Determine color range if not set
     if isnothing(tpf.colorrange[])
         tpf.colorrange[] = (minimum(image_data[]), maximum(image_data[]))
     end
 
     # Plot the image
     image!(tpf, 
          (xlims[1], xlims[end]),
          (ylims[1], ylims[end]),
          image_data, 
          colormap = tpf.colormap, 
          colorrange = tpf.colorrange,
          #aspect = tp.aspect
     )
     tpf
end

"""
    @recipe(TwoPhotonProjection, experiment)

A recipe for plotting projections of two-photon imaging data. This recipe can create either:
1. A frame projection (2D image) showing the maximum intensity across frames
2. A trace projection (line plot) showing the mean intensity over time

# Attributes
- `channel`: The channel to display (default: 1)
- `colormap`: The colormap to use for frame projections (default: :viridis)
- `colorrange`: The range of values to map to colors (default: nothing)
- `color`: The color to use for trace projections (default: :black)
- `linewidth`: The width of lines for trace projections (default: 1.0)
- `dims`: The dimensions to project along (default: 3). Use 3 for frame projection or (1,2) for trace projection.

# Example
```julia
fig = Figure()
ax = Axis(fig[1,1])
# For frame projection
two_photon_projection!(ax, my_experiment, dims=3)
# For trace projection
two_photon_projection!(ax, my_experiment, dims=(1,2))
```
"""
@recipe(TwoPhotonProjection, experiment) do scene
     Attributes(
          channel = 1,
          colormap = :viridis,
          colorrange = Observable{Any}(nothing),
          color = :black,
          linewidth = 1.0, 
          dims = 3
     )
end

"""
    Makie.plot!(tpp::TwoPhotonProjection)

Internal plotting function for TwoPhotonProjection recipe. Creates either a frame projection
or trace projection based on the dims parameter, with appropriate visualization settings.
"""
function Makie.plot!(tpp::TwoPhotonProjection{<:Tuple{<:Experiment{TWO_PHOTON}}})
     exp = tpp.experiment[]
     dims = tpp.dims[]
     channel = tpp.channel[]
     # Compute the projection
     if dims == 3 #This should be frame
          xlims = exp.HeaderDict["xrng"]
          ylims = exp.HeaderDict["yrng"]
          #Extract the projected array
          project_arr = project(exp, dims = dims)[:,:,1,channel]
          
          if isnothing(tpp.colorrange[])
               tpp.colorrange[] = (minimum(project_arr), maximum(project_arr))
          end

          image!(tpp, 
               (xlims[1], xlims[end]),
               (ylims[1], ylims[end]),
               project_arr, 
               colormap = tpp.colormap, 
               colorrange = tpp.colorrange,
               #aspect = tp.aspect
          )
     else dims == (1,2) #This is a trace and needs to be a line
          color = tpp.color[]
          lw = tpp.linewidth[]
          x = exp.t
          #extract the projected array
          project_arr = project(exp, dims = dims)[1,1,:,channel]

          lines!(tpp, x, project_arr; color = color, linewidth = lw)
     end
     tpp
end

"""
    @recipe(StimulusTiming, experiment)

A recipe for visualizing stimulus timing in an experiment. This recipe adds:
1. Vertical dotted lines at stimulus start times
2. Vertical dotted lines at stimulus end times
3. A semi-transparent span covering the entire stimulus duration

# Attributes
- `show_start`: Whether to show start time lines (default: true)
- `show_end`: Whether to show end time lines (default: true)
- `show_span`: Whether to show stimulus span (default: true)
- `start_color`: Color for start time lines (default: :blue)
- `end_color`: Color for end time lines (default: :red)
- `span_color`: Color for the stimulus span (default: :gray)
- `span_alpha`: Transparency of the stimulus span (default: 0.25)
- `line_style`: Style of the vertical lines (default: :dash)
- `line_width`: Width of the vertical lines (default: 1.0)

# Example
```julia
fig = Figure()
ax = Axis(fig[1,1])
# First plot your data
lines!(ax, experiment.t, experiment.data)
# Then add stimulus timing visualization
stimulus_timing!(ax, experiment)
# Or customize which elements to show
stimulus_timing!(ax, experiment, show_start=false, show_span=true)
```
"""
@recipe(StimulusTiming, experiment) do scene
    Attributes(
        show_start = true,
        show_end = true,
        show_span = true,
        start_color = :blue,
        end_color = :red,
        span_color = :gray,
        span_alpha = 0.25,
        line_style = :dash,
        line_width = 1.0
    )
end

"""
    Makie.plot!(st::StimulusTiming)

Internal plotting function for StimulusTiming recipe. Adds stimulus timing visualization
to the current plot if a stimulus protocol exists in the experiment.
"""
function Makie.plot!(st::StimulusTiming)
    exp = st.experiment[]
    
    # Check if stimulus protocol exists
    if !haskey(exp.HeaderDict, "StimulusProtocol")
        @warn "StimulusProtocol not found in experiment.HeaderDict. Cannot plot stimulus timing."
        return st # Return the plot object early
    end
    
    stim_protocol = getStimulusProtocol(exp)
    
    # Get stimulus start and end times
    # Ensure these functions are available and work with stim_protocol object
    start_times = getStimulusStartTime(stim_protocol)
    end_times = getStimulusEndTime(stim_protocol)
    # println("Start times: $start_times")
    # println("End times: $end_times")
    # Plot start time lines if enabled
    if st.show_start[]
        vlines!(st, start_times, 
            color = st.start_color[],
            linestyle = st.line_style[],
            linewidth = st.line_width[]
        )
    end
    
    # Plot end time lines if enabled
    if st.show_end[]
        vlines!(st, end_times,
            color = st.end_color[],
            linestyle = st.line_style[],
            linewidth = st.line_width[]
        )
    end
    
    # Plot stimulus span if enabled
    if st.show_span[]
        for i in eachindex(start_times)
            vspan!(st, [start_times[i], end_times[i]],
                color = st.span_color[],
                alpha = st.span_alpha[]
            )
        end
    end
    
    st
end

# Export the function
export stimulustiming!

"""
    @recipe(ScaleBar)

A recipe for adding scale bars to plots. This recipe adds:
1. An optional x-scale bar (horizontal)
2. An optional y-scale bar (vertical)

# Attributes
- `start_x`: Starting x-position for the x-scale bar (default: nothing, meaning no x-scale bar)
- `length_x`: Length of the x-scale bar in data units (default: 1.0)
- `start_y`: Starting y-position for the y-scale bar (default: nothing, meaning no y-scale bar)
- `length_y`: Length of the y-scale bar in data units (default: 1.0)
- `color`: Color of the scale bars (default: :black)
- `linewidth`: Width of the scale bars (default: 2.0)
- `text_color`: Color of the scale bar labels (default: :black)
- `fontsize`: Size of the scale bar labels (default: 12)
- `x_label`: Label for the x-scale bar (default: nothing, will use length_x value)
- `y_label`: Label for the y-scale bar (default: nothing, will use length_y value)
- `offset_ratio`: Ratio of axis range to use for text offset (default: 0.02)

# Example
```julia
fig = Figure()
ax = Axis(fig[1,1])
# First plot your data
lines!(ax, x, y)
# Then add scale bars
scale_bar!(ax, start_x=0.1, length_x=10.0, start_y=0.1, length_y=5.0)
```
"""
@recipe(ScaleBar) do scene
    Attributes(
        start_x = nothing,
        length_x = 1.0,
        start_y = nothing,
        length_y = 1.0,
        color = :black,
        linewidth = 2.0,
        text_color = :black,
        fontsize = 12,
        x_label = nothing,
        y_label = nothing,
        offset_ratio = 0.02
    )
end

"""
    Makie.plot!(sb::ScaleBar)

Internal plotting function for ScaleBar recipe. Adds scale bars to the current plot
based on the specified positions and lengths.
"""
function Makie.plot!(sb::ScaleBar)
    # Get the parent axis
    ax = sb.parent
    
    # Get current axis limits
    xlims = ax.finallimits[].origin[1], ax.finallimits[].origin[1] + ax.finallimits[].widths[1]
    ylims = ax.finallimits[].origin[2], ax.finallimits[].origin[2] + ax.finallimits[].widths[2]
    
    # Calculate offsets based on axis ranges
    x_range = xlims[2] - xlims[1]
    y_range = ylims[2] - ylims[1]
    offset = sb.offset_ratio[] * min(x_range, y_range)
    
    # Plot x-scale bar if start_x is specified
    if !isnothing(sb.start_x[])
        x_start = sb.start_x[]
        x_end = x_start + sb.length_x[]
        y_pos = sb.start_y[] === nothing ? ylims[1] + offset : sb.start_y[]
        
        lines!(sb, [x_start, x_end], [y_pos, y_pos],
            color = sb.color[],
            linewidth = sb.linewidth[]
        )
        
        x_label_text = isnothing(sb.x_label[]) ? "$(sb.length_x[])" : sb.x_label[]
        text!(sb, x_label_text,
            position = (x_start + sb.length_x[]/2, y_pos - offset),
            align = (:center, :top),
            color = sb.text_color[],
            fontsize = sb.fontsize[]
        )
    end
    
    # Plot y-scale bar if start_y is specified
    if !isnothing(sb.start_y[])
        y_start = sb.start_y[]
        y_end = y_start + sb.length_y[]
        x_pos = sb.start_x[] === nothing ? xlims[1] + offset : sb.start_x[]
        
        lines!(sb, [x_pos, x_pos], [y_start, y_end],
            color = sb.color[],
            linewidth = sb.linewidth[]
        )
        
        y_label_text = isnothing(sb.y_label[]) ? "$(sb.length_y[])" : sb.y_label[]
        text!(sb, y_label_text,
            position = (x_pos - offset, y_start + sb.length_y[]/2),
            align = (:right, :center),
            color = sb.text_color[],
            fontsize = sb.fontsize[],
            rotation = -pi/2 # Makie uses radians for rotation
        )
    end
    
    return sb
end