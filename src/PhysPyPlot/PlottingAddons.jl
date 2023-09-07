function add_scalebar(axis, loc::Tuple{T,T}, dloc::Tuple{T,T};
    fontsize=10.0, lw=3.0,
    xlabeldist=30.0, ylabeldist=15.0,
    xunits="ms", yunits="μV",
    xconvert=1000.0, yconvert=1.0, #this converts the units from x and y labels. x should be in ms
    xround=true, yround=true,
    kwargs...
) where {T<:Real}
    x, y = loc
    dx, dy = dloc
    x0, xmax = plt.xlim()
    data_width = (xmax - x0)
    y0, ymax = plt.ylim()
    data_height = abs(ymax - y0)

    #println(data_width / xlabeldist) #debug options 
    #println(data_height / ylabeldist) #debug options
    axis.plot([x, x + dx], [y, y], c=:black, lw=lw; kwargs...) #add a vertical line
    axis.plot([x, x], [y, y + dy], c=:black, lw=lw; kwargs...)
    if yround
        yscale = round(Int64, dy * yconvert)
    else
        yscale = dy * yconvert
    end
    if xround
        xscale = round(Int64, dx * xconvert)
    else
        xscale = dx * xconvert
    end
    axis.annotate("$yscale $yunits", (x - (data_width / xlabeldist), y + dy / 2), va="center", ha="center", rotation="vertical", fontsize=fontsize)
    axis.annotate("$xscale $xunits", (x + dx / 2, y - (data_height / ylabeldist)), va="center", ha="center", rotation="horizontal", fontsize=fontsize)
end

function add_sig_bar(axes, x::Real, y::Real; 
    level = "*", color = :black, 
    pointer = false,
    pointer_dx = 0.5,
    pointer_ylims = [2.0, 3.0], 
    lw = 1.0, fs = 12.0, ls = "solid"
)    
    #println(level)
    if isa(level, Float64)
        println(level)
        println(sig_level(level))

        level = sig_level(level)
        println(level)
    end
    println(level)
    if level != "n.s"
         axes.text(x, y, level, ha = "center", va = "center", fontsize = fs, color = color)
         if pointer
              #draw top bar
              xs_top = (x-pointer_dx, x+pointer_dx)
              ys_top = (y, y)
              axes.plot(xs_top, ys_top, color = color, lw = lw, linestyle = ls)

              xs_left = (x-pointer_dx, x-pointer_dx)
              ys_left = (y, pointer_ylims[1])
              axes.plot(xs_left, ys_left, color = color, lw = lw, linestyle = ls)
              
              xs_right = (x+pointer_dx, x+pointer_dx)
              ys_right = (y, pointer_ylims[2])
              axes.plot(xs_right, ys_right, color = color, lw = lw, linestyle = ls)
         end
    end
end

function add_sig_bar(axis, xs::Vector{T}, ys::Vector{T}; kwargs...) where T <: Real
    for i in axes(xs, 1)
         add_sig_bar(axis, xs[i], ys[i]; kwargs...)
    end
end

#==# 
#function is not working well
function add_border(ax; c = :black, xpad_ratio = 0.2, ypad_ratio = 0.2)
    xmin, xmax, ymin, ymax = ax.axis()

    xrng = xmax - xmin
    yrng = ymax - ymin
    xpad = xpad_ratio*xrng
    ypad = ypad_ratio*yrng
    println(xpad) 
    x1 = xmin - xpad_ratio
    y1 = ymin - ypad_ratio
    dx = xpad*2 + xrng
    dy = ypad*2 + yrng
    recA = plt.Rectangle((x1, y1), dx, dy, fill=false, lw=2.5, clip_on = false, color = c)
    ax.add_patch(recA)
end

function draw_axes_border(ax; lw = 2.5, color = :black)
    for location in ["left", "right", "top", "bottom"]
         ax.spines[location].set_visible(true)
         ax.spines[location].set_linewidth(lw)
         ax.spines[location].set_color(color)
    end
    ax.yaxis.set_visible(false)
    ax.xaxis.set_visible(false)
end

"""
This function draws a bordered box in the data with a gradient. Useful for some figures
"""
function draw_gradient_box(ax, xy, dxy; 
     color = "Greys", cmin = 0.0, cmax = 1.0, n_steps = 100, 
     cspace = nothing, #this is a range
     fontcolor = "white", fontsize = 7, text = "default", fontweight="bold",
     lw = 2.5
)
     x,y = xy
     width, height = dxy

     xmin, xmax, ymin, ymax = plt.axis()
     ymin_unit = (y - ymin) / (ymax - ymin)
     ymax_unit = (y+height - ymin) / (ymax - ymin)
     
     if isnothing(cspace)
          try
               cmap = plt.get_cmap(color)
               for (i, c) in enumerate(LinRange(cmin, cmax, n_steps))  # Increased number of steps for smoother gradient
                    #This means that the ymin and ymax will refer to ratios of the ymin and ymax
                    ax.axvspan(x + (i - 1)*width/n_steps, x + i*width/n_steps, ymin=ymin_unit, ymax=ymax_unit, color=cmap(c), zorder=3)
               end
          catch
               for (i, c) in enumerate(LinRange(0, 1, n_steps))  # Increased number of steps for smoother gradient
                    #This means that the ymin and ymax will refer to ratios of the ymin and ymax
                    ax.axvspan(x + (i - 1)*width/n_steps, x + i*width/n_steps, ymin=ymin_unit, ymax=ymax_unit, color=color, zorder=3)
               end
          end
     else
          cmap = plt.get_cmap(color)
          for (i, c) in enumerate(cspace)  # Increased number of steps for smoother gradient
               #This means that the ymin and ymax will refer to ratios of the ymin and ymax
               ax.axvspan(x + (i - 1)*width/n_steps, x + i*width/n_steps, ymin=ymin_unit, ymax=ymax_unit, color=cmap(c), zorder=3)
          end

     end
     
     gradient_box = plt.Rectangle(xy, width, height, linewidth=lw, edgecolor="black", facecolor="none", zorder=4)
     ax.add_patch(gradient_box)
     ax.text(x+(width/2), y+height/2, text, color = fontcolor, fontsize = fontsize, weight = fontweight, va="center", ha = "center", zorder = 5)
end

#==#