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

#= function is not working well
function add_border(ax; c = :black, lower_left = (0.5, 0.3), width = 0.2, height = 0.2)
    xmin, xmax, ymin, ymax = ax_lims = ax.axis()
    xrng = abs(xmin) + abs(xmax)
    yrng = abs(ymin) + abs(ymax)
    #println(xrng)
    #println(yrng)
    x = xmin - xrng*lower_left[1]
    y = ymin - yrng*lower_left[2]
    dX = xrng*width
    dY = yrng*height
    #println(ax_lims)
    #println("($x, $(x + dX), $y, $(y + dY)")

    recA = Rectangle((x,y), xrng+dX, yrng+dY, fill=false,lw=2.5, clip_on = false, color = c)
    ax.add_patch(recA)
end
=#