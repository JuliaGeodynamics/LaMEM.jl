# Plotting extensions, that are only loaded when GLMakie is available
println("adding Plots.jl plotting extensions for LaMEM")

using LaMEM, GeophysicalModelGenerator
using .Plots
 
export plot_initial_setup, cross_section

"""
    plot_initial_setup(model::LaMEM.Model, field=:phases; x=nothing, y=nothing, z=nothing, phases=true)

Plots a 2D setup through the LaMEM model setup `model`. if `phases=true` we plot phases; otherwise temperature
"""
function plot_initial_setup(model::LaMEM.Model, field::Symbol=:phases; x=nothing, y=nothing, z=nothing)

    # retrieve cross-section

    x_vec, z_vec, data, axes_str = cross_section(model::LaMEM.Model, field=field; x=x, y=y, z=z)
    #=
    fig = Figure()
    ax = Axis(fig[1, 1], aspect = DataAspect(), title = title_str, xlabel=x_str, ylabel=z_str)
    hm = heatmap(ax, x_vec, z_vec, data)
   
    Colorbar(fig[:, end+1], hm)

    display(fig)
    =#
    
    # using Plots
    h = heatmap(x_vec, z_vec, data, xlabel=axes_str.x_str, ylabel=axes_str.z_str, title=axes_str.title_str, aspect_ratio=:equal)
    display(h)

    return h
end
