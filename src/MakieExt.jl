# Plotting extensions, that are only loaded when GLMakie is available
println("adding Plots.jl plotting extensions for LaMEM")

using LaMEM, GeophysicalModelGenerator
using .Plots
 
export plot_initial_setup

"""
    plot_initial_setup(model::LaMEM.Model; x=nothing, y=nothing, z=nothing, phases=true)

Plots a 2D setup through the LaMEM model setup `model`. if `phases=true` we plot phases; otherwise temperature
"""
function plot_initial_setup(model::LaMEM.Model; x=nothing, y=nothing, z=nothing, phases=true)

    Model3D = CartData(model.Grid.Grid, (Phases=model.Grid.Phases,Temp=model.Grid.Temp));
    
    if !isnothing(z); Depth_level = z*km; else Depth_level=nothing; end
    if !isnothing(x); Lon_level = x; else Lon_level=nothing; end
    if !isnothing(y); Lat_level = y; else Lat_level=nothing; end
    
    Cross = CrossSectionVolume(Model3D, Depth_level=Depth_level, Lat_level=Lat_level, Lon_level=Lon_level)

    # Flatten arrays + coordinates
    if      !isnothing(x)
        Phase2D, Temp2D =   dropdims(Cross.fields.Phases,dims=1), dropdims(Cross.fields.Temp,dims=1)
        X2D, Z2D = dropdims(Cross.y.val,dims=1), dropdims(Cross.z.val,dims=1)
        x_vec, z_vec = X2D[:,1],  Z2D[1,:]
        title_str = "x = $x"
        x_str,z_str = "y","z"
    elseif !isnothing(y)
        Phase2D, Temp2D =   dropdims(Cross.fields.Phases,dims=2), dropdims(Cross.fields.Temp,dims=2)
        X2D, Z2D = dropdims(Cross.x.val,dims=2), dropdims(Cross.z.val,dims=2)
        x_vec, z_vec = X2D[:,1],  Z2D[1,:]
        title_str = "y = $y"
        x_str,z_str = "x","z"
    elseif !isnothing(z)
        Phase2D, Temp2D =   dropdims(Cross.fields.Phases,dims=3), dropdims(Cross.fields.Temp,dims=3)
        X2D, Z2D = dropdims(Cross.x.val,dims=3), dropdims(Cross.y.val,dims=3)

        x_vec, z_vec = X2D[:,1],  Z2D[1,:]
        title_str = "z = $z"
        x_str,z_str = "x","y"
    end
    
    # Create figure
    if phases
        data = Phase2D
        title_str = "Phases; "*title_str
    else
        data = Temp2D
        title_str = "Temperature; "*title_str
    end

    #=
    fig = Figure()
    ax = Axis(fig[1, 1], aspect = DataAspect(), title = title_str, xlabel=x_str, ylabel=z_str)
    hm = heatmap(ax, x_vec, z_vec, data)
   
    Colorbar(fig[:, end+1], hm)

    display(fig)
    =#
    h = heatmap(x_vec, z_vec, data, xlabel=x_str, ylabel=z_str, title=title_str, aspect_ratio=:equal)
    display(h)

    return h
end
