# Plotting extensions, that are only loaded when GLMakie is available
println("Adding Plots.jl plotting extensions for LaMEM")

using LaMEM, GeophysicalModelGenerator, Statistics, DelimitedFiles
using .Plots
import .Plots: heatmap
export plot_topo, plot_cross_section, plot_phasediagram
 
"""
    plot_cross_section(model::Union{Model,CartData}, args...; field::Symbol=:phase,  
                        timestep::Union{Nothing, Int64}=nothing,
                        dim=1, x=nothing, y=nothing, z=nothing, aspect_ratio::Union{Real, Symbol}=:equal)
   
This plots a cross-section through the LaMEM `model`, of the field  `field`. If that is a vector or tensor field, specify `dim` to indicate which of the fields you want to see.
If the keyword `timestep` is specified, it will load a timestep 
"""
function plot_cross_section(model::Union{Model,CartData}, args...; field::Symbol=:phase, 
        timestep::Union{Nothing, Int64}=nothing, dim=1, 
        x=nothing, y=nothing, z=nothing, 
        aspect_ratio::Union{Real, Symbol}=:equal)

    if !isnothing(timestep)
        # load a particular timestep
        data_cart, time = Read_LaMEM_timestep(model,timestep)
        model = data_cart
    end

    if isnothing(x) && isnothing(y) && isnothing(z)
        x = mean(extrema(model.Grid.Grid.X))
    end
    
    data_tuple, axes_str = cross_section(model, field; x=x, y=y, z=z)
    
    if isa(data_tuple.data, Array)
        data_field = data_tuple.data
        cb_str = String(field)
    elseif isa(data_tuple.data, Tuple)
        data_field = data_tuple.data[dim]
        cb_str = String(field)*"[$dim]"
    end

    title_str = axes_str.title_str
    if !isnothing(timestep)
        title_str=title_str*"; time=$(time[1])"
    end

    hm = heatmap(data_tuple.x, data_tuple.z, data_field', 
                aspect_ratio=aspect_ratio, 
                xlabel=axes_str.x_str,
                ylabel=axes_str.z_str,
                title=title_str,
                colorbar_title=cb_str,
                args...)
                
    return hm
end

#=
"""
    plot_cross_section(model::Union{Model,CartData}, args...; field::Symbol=:phase,  
                        timestep::Symbol=:all,
                        dim=1, x=nothing, y=nothing, z=nothing, aspect_ratio::Union{Real, Symbol}=:equal)
   
This allows plotting all timesteps if you specify `timestep=:all`
"""
function plot_cross_section(model::Union{Model,CartData}, args...; field::Symbol=:phase, 
        timestep::Symbol=:all, dim=1, x=nothing, y=nothing, z=nothing, aspect_ratio::Union{Real, Symbol}=:equal)

        if timestep==:all
            Timesteps,_,_ = Read_LaMEM_simulation(model);
            for timestep_val in Timesteps
                plot_cross_section(model, args, field=field, timestep=timestep_val, dim=dim, x=x, y=y, z=z, aspect_ratio=aspect_ratio)
            end

        else
            error("unknown timestep: $timestep")
        end 


        return nothing
end
=#

"""
    plot_topo(topo::CartData, args...)

Simple function to plot the topography 
"""
function plot_topo(topo::CartData; kwargs...)
   
    hm = heatmap(topo.x.val[:,1,1], topo.y.val[1,:,1], topo.fields.Topography[:,:,1]'; 
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
