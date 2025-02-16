module PlotsExt

using Plots
using GeophysicalModelGenerator, Statistics, DelimitedFiles
import LaMEM: cross_section, Model, read_LaMEM_timestep, read_LaMEM_simulation, read_phase_diagram
import LaMEM: plot_topo, plot_cross_section, plot_phasediagram, plot_cross_section_simulation
export plot_topo, plot_cross_section, plot_phasediagram, plot_cross_section_simulation

# Plotting extensions, that are only loaded when Plots is available
println("Adding Plots.jl plotting extensions for LaMEM")

"""
    plot_cross_section(model::Model, args...; field::Symbol=:phase,  
                        timestep::Union{Nothing, Int64}=nothing,
                        dim=1, x=nothing, y=nothing, z=nothing, 
                        aspect_ratio::Union{Real, Symbol}=:equal,
                        surf=false)
   
This plots a cross-section through the LaMEM `model`, of the field  `field`. If that is a vector or tensor field, specify `dim` to indicate which of the fields you want to see.
If the keyword `timestep` is specified, it will load a timestep 
"""
function plot_cross_section(model::Model, args...; field::Symbol=:phase, 
        timestep::Union{Nothing, Int64}=nothing, 
        dim=1, 
        x=nothing, 
        y=nothing, 
        z=nothing, 
        aspect_ratio::Union{Real, Symbol}=:equal,
        surf=false)

    if !isnothing(timestep)
        # load a particular timestep
        data_cart, time_val = read_LaMEM_timestep(model,timestep, surf=surf)
    else
        # Create a CartData set from initial model setup
        data_cart = CartData(model.Grid.Grid.X, model.Grid.Grid.Y, model.Grid.Grid.Z, 
                                (phase=model.Grid.Phases,temperature=model.Grid.Temp))
    end
    
    if isnothing(x) && isnothing(y) && isnothing(z)
        x = mean(extrema(model.Grid.Grid.X))
    end

    title_str = ""
    if !isnothing(timestep)
        title_str=title_str*" time=$(time_val[1])"
    end

    hm = plot_cross_section(data_cart, args...; field=field, dim=dim,x=x, y=y, z=z, title_str=title_str, aspect_ratio=aspect_ratio)

    return hm
end

"""
    plot_cross_section(data::CartData, args...; field::Symbol=:phase,  
                        title_str="",
                        dim=1, 
                        x=nothing, 
                        y=nothing, 
                        z=nothing, 
                        aspect_ratio::Union{Real, Symbol}=:equal
                        surf=false)
   
This plots a cross-section through a `CartData` dataset `data` of the field  `field`, typically read in from a LaMEM simulation.
If that is a vector or tensor field, specify `dim` to indicate which of the fields you want to see.
"""
function plot_cross_section(data::CartData , args...; field::Symbol=:phase, 
        dim=1, 
        x=nothing, y=nothing, z=nothing, 
        title_str="",
        aspect_ratio::Union{Real, Symbol}=:equal,
        surf=false)

   
    if isnothing(x) && isnothing(y) && isnothing(z)
        x = mean(extrema(data.x.val))
    end
    
    data_tuple, axes_str = cross_section(data, field; x=x, y=y, z=z)
    
    if isa(data_tuple.data, Array)
        data_field = data_tuple.data
        cb_str = String(field)
    elseif isa(data_tuple.data, Tuple)
        data_field = data_tuple.data[dim]
        cb_str = String(field)*"[$dim]"
    end
    title_str *= " "*axes_str.title_str
 
    hm = Plots.heatmap(data_tuple.x, data_tuple.z, data_field', 
                aspect_ratio=aspect_ratio, 
                xlabel=axes_str.x_str,
                ylabel=axes_str.z_str,
                title=title_str,
                colorbar_title=cb_str,
                args...)
                
    return hm
end

"""
    plot_cross_section_simulation(model::Model, args...; field::Symbol=:phase,  
                        dim=1, x=nothing, y=nothing, z=nothing, aspect_ratio::Union{Real, Symbol}=:equal)
   
As `plot_cross_section`, but for the entire simulation instead of a single timestep.
"""
function plot_cross_section_simulation(model::Model, args...; field::Symbol=:phase, 
        dim=1, x=nothing, y=nothing, z=nothing, aspect_ratio::Union{Real, Symbol}=:equal)

    Timesteps,_,_ = read_LaMEM_simulation(model);
    for timestep_val in Timesteps
        plot_cross_section(model, args, field=field, timestep=timestep_val, dim=dim, x=x, y=y, z=z, aspect_ratio=aspect_ratio)
    end

    return nothing
end


"""
    plot_topo(topo::CartData; kwargs...)

Simple function to plot the topography 
"""
function plot_topo(topo::CartData; kwargs...)
   
    hm = Plots.heatmap( topo.x.val[:,1,1], 
                        topo.y.val[1,:,1], 
                        topo.fields.topography[:,:,1]'; 
                        aspect_ratio=:equal, 
                        xlabel="x",
                        ylabel="y",
                        title="topography [km]",
                        colormap=:oleron,
                        kwargs...)
                
    return hm
end




""" 
    hm = plot_phasediagram(name::String="Rhyolite", field=:ρ;  colormap=:batlow, kwargs...)

This creates a plot of a LaMEM phase diagram (computed by MAGEMin or Perple_X).
Typical available `fields`:
- `:ρ_solid` (solid density)
- `:ρ_melt` (melt density)
- `:ρ` (average density)
- `:ϕ` (melt fraction)

"""
function plot_phasediagram(name::String="Rhyolite", field=:ρ;  colormap=:batlow, kwargs...)
    # read phase diagram
    PD = read_phase_diagram(name)

    T_C     = PD.T_K[:,1] .- 273.15   
    P_kbar  = PD.P_bar[1,:] ./ 1e3
    val     = PD[field]     # field

    # plot
    hm = heatmap(T_C, P_kbar, val'; 
                xlabel="T [Celcius]",
                ylabel="Pressure [kbar]",
                title="Phase diagram [$field]",
                colormap=colormap,
                kwargs...)

    return hm
end


end