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

function Makie.plot!(tp::TwoPhotonFrame{<:Tuple{<:Experiment{TWO_PHOTON}, <:Integer}})
     #Extract the 
     exp = tp.experiment[]
     frame_value = tp.frame
     channel = tp.channel
 
     #println("Frame: $frame_value, Channel: $channel")
 
     xlims = exp.HeaderDict["xrng"]
     ylims = exp.HeaderDict["yrng"]
 
    # Use @lift to reactively update image_data
    image_data = @lift(get_frame(exp, $frame)[:, :, 1, $channel])
 
     # Determine color range if not set
     if isnothing(tp.colorrange[])
         tp.colorrange[] = (minimum(image_data), maximum(image_data))
     end
 
     # Plot the image
     image!(tp, 
          (xlims[1], xlims[end]),
          (ylims[1], ylims[end]),
          image_data, 
          colormap = tp.colormap, 
          colorrange = tp.colorrange,
          #aspect = tp.aspect
     )
     tp
 end