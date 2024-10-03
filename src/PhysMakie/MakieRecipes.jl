#Makie.convert_arguments(P::Type{<:Lines}, exp::Experiment) = convert_arguments(P, exp.t, exp.data_array)

@recipe(ExperimentPlot, experiment) do scene
     Attributes(
          color = :black,
          linewidth = 2.0,
          channel = 1 #Also can be -1 for plotting all channels
     )
end

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

@recipe(TwoPhotonFrame, experiment, frame) do scene
     Attributes(
          channel = nothing,
          colormap = :gist_heat,
          colorrange = Observable{Any}(nothing),
     )
end

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