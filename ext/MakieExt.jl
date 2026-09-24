module MakieExt

using Makie
using GeophysicalModelGenerator, Statistics, Printf
import LaMEM
import LaMEM: cross_section, Model, read_LaMEM_timestep, read_LaMEM_simulation, read_phase_diagram
import LaMEM: crosssection, crosssection!, topo, topo!, phasediagram, phasediagram!

# Plotting recipes, that are only loaded when a Makie backend (GLMakie, CairoMakie, ...)
# is available. In contrast to the `plot_*` functions of the Plots extension, these are
# Makie recipes: they plot *into* an axis you created yourself, so a cross-section can be
# combined with other plots in one figure.
println("Adding Makie.jl plotting extensions for LaMEM")

"""
    slice_of(data::CartData, field::Symbol, dim, x, y, z)

Internal helper that cuts a cross-section through `data` and returns the two axes, the 2D
data of `field` and the strings describing them. `dim` selects the component of a vector or
tensor field. If no position is given, the section is taken through the middle in `x`.
"""
function slice_of(data::CartData, field::Symbol, dim, x, y, z)
    if isnothing(x) && isnothing(y) && isnothing(z)
        x = mean(extrema(data.x.val))
    end

    data_tuple, axes_str = cross_section(data, field; x=x, y=y, z=z)

    if isa(data_tuple.data, Tuple)
        # vector or tensor field: pick the requested component
        values = data_tuple.data[dim]
        cb_str = String(field)*"[$dim]"
    else
        values = data_tuple.data
        cb_str = String(field)
    end

    return data_tuple.x, data_tuple.z, values, axes_str, cb_str
end

"""
    model_data(model::Model, timestep, surf)

Internal helper that returns the `CartData` to plot for `model`: the output of `timestep` if
one is given (`:last` for the last one), and otherwise the initial setup of the model, which
is available without having run LaMEM.
"""
function model_data(model::Model, timestep, surf)
    if isnothing(timestep)
        # the initial setup, straight from the model
        return CartData(model.Grid.Grid.X, model.Grid.Grid.Y, model.Grid.Grid.Z,
                        (phase=model.Grid.Phases, temperature=model.Grid.Temp,
                         plast_strain=model.Grid.APS)), nothing
    elseif timestep === :last
        data, time_val = read_LaMEM_timestep(model, last=true, surf=surf)
        return data, time_val
    else
        data, time_val = read_LaMEM_timestep(model, timestep, surf=surf)
        return data, time_val
    end
end

"""
    crosssection(data; field=:phase, dim=1, x=nothing, y=nothing, z=nothing)
    crosssection!(ax, data; ...)

Plot a cross-section through a LaMEM `Model` or a `CartData` set as a heatmap.

`data` is either a `Model` -- in which case `timestep` selects which output to read, and the
initial setup is plotted if it is left out -- or a `CartData` set as returned by
`read_LaMEM_timestep`. `field` is the field to plot and `dim` the component to use if that
field is a vector or tensor. The section is taken at `x`, `y` or `z`; if none is given it
goes through the middle of the model in `x`.

Being a recipe, this plots into an axis of your own, so it composes with other plots:
```julia
julia> using GLMakie, LaMEM          # or CairoMakie
julia> fig = Figure()
julia> ax  = Axis(fig[1,1], aspect=DataAspect())
julia> crosssection!(ax, model, field=:phase, x=0)
```
`crosssection(data; ...)` creates the figure and axis for you and returns the usual Makie
`FigureAxisPlot`, so `display` or saving it works as with any other Makie plot.
"""
Makie.@recipe(CrossSection) do scene
    Makie.Attributes(
        field     = :phase,
        dim       = 1,
        x         = nothing,
        y         = nothing,
        z         = nothing,
        timestep  = nothing,   # Model only: an Int, :last, or nothing for the initial setup
        surf      = false,     # Model only: read the free surface instead of the volume
        colormap  = :roma,
    )
end

function Makie.plot!(p::CrossSection{<:Tuple{<:CartData}})
    data = p[1]

    # recompute the slice whenever the data or any of the slicing attributes change
    values = Makie.lift(data, p.field, p.dim, p.x, p.y, p.z) do d, field, dim, x, y, z
        xs, zs, vals, _, _ = slice_of(d, field, dim, x, y, z)
        (xs, zs, vals)
    end

    Makie.heatmap!(p, (@lift $values[1]), (@lift $values[2]), (@lift $values[3]);
                   colormap = p.colormap)

    return p
end

function Makie.plot!(p::CrossSection{<:Tuple{<:Model}})
    model = p[1]

    values = Makie.lift(model, p.field, p.dim, p.x, p.y, p.z, p.timestep, p.surf) do m, field, dim, x, y, z, timestep, surf
        d, _ = model_data(m, timestep, surf)
        xs, zs, vals, _, _ = slice_of(d, field, dim, x, y, z)
        (xs, zs, vals)
    end

    Makie.heatmap!(p, (@lift $values[1]), (@lift $values[2]), (@lift $values[3]);
                   colormap = p.colormap)

    return p
end

"""
    axis_labels(data, field; dim=1, x=nothing, y=nothing, z=nothing)

The axis and colorbar labels that belong to a [`crosssection`](@ref) of `data`, as a named
tuple `(xlabel, ylabel, title, colorbar)`. A recipe cannot set these itself -- they belong to
the axis, which you own -- so use them to label the axis you plot into:
```julia
julia> lab = axis_labels(data, :phase, x=0)
julia> ax  = Axis(fig[1,1], xlabel=lab.xlabel, ylabel=lab.ylabel, title=lab.title)
```
"""
function LaMEM.axis_labels(data::CartData, field::Symbol=:phase; dim=1, x=nothing, y=nothing, z=nothing)
    _, _, _, axes_str, cb_str = slice_of(data, field, dim, x, y, z)
    return (xlabel=axes_str.x_str, ylabel=axes_str.z_str, title=axes_str.title_str, colorbar=cb_str)
end

"""
    axis_labels(topo::CartData, ::Val{:topo})

The axis and colorbar labels for a [`topo`](@ref) plot of a free-surface data set.
"""
LaMEM.axis_labels(::CartData, ::Val{:topo}) =
    (xlabel="x [km]", ylabel="y [km]", title="topography [km]", colorbar="topography [km]")

"""
    axis_labels(name::AbstractString, field::Symbol=:ρ)

The axis and colorbar labels for a [`phasediagram`](@ref) of the diagram `name`.
"""
function LaMEM.axis_labels(::AbstractString, field::Symbol=:ρ)
    return (xlabel="T [Celcius]", ylabel="Pressure [kbar]",
            title="Phase diagram [$field]", colorbar=String(field))
end

function LaMEM.axis_labels(model::Model, field::Symbol=:phase; dim=1, x=nothing, y=nothing, z=nothing,
                           timestep=nothing, surf=false)
    data, time_val = model_data(model, timestep, surf)
    lab = LaMEM.axis_labels(data, field; dim=dim, x=x, y=y, z=z)
    title = isnothing(time_val) ? lab.title : lab.title*" time=$(time_val[1])"
    return (xlabel=lab.xlabel, ylabel=lab.ylabel, title=title, colorbar=lab.colorbar)
end

"""
    topo(topography)
    topo!(ax, topography)

Plot the topography of a `CartData` set (as returned by `read_LaMEM_timestep(...; surf=true)`)
as a heatmap in the `x`-`y` plane.
"""
Makie.@recipe(Topo) do scene
    Makie.Attributes(colormap = :oleron)
end

"""
    topography_of(fields)

Internal helper that picks the topography out of a free-surface data set. LaMEM writes the
field as `topography`, but older files (and `GeophysicalModelGenerator` setups) call it
`Topography`, so accept both.
"""
function topography_of(fields)
    hasproperty(fields, :topography) && return fields.topography
    hasproperty(fields, :Topography) && return fields.Topography
    error("no topography found in this data set; its fields are $(keys(fields)). " *
          "Read it with `read_LaMEM_timestep(model, ...; surf=true)`.")
end

function Makie.plot!(p::Topo{<:Tuple{<:CartData}})
    t = p[1]

    Makie.heatmap!(p,
        (@lift $t.x.val[:,1,1]),
        (@lift $t.y.val[1,:,1]),
        (@lift topography_of($t.fields)[:,:,1]);
        colormap = p.colormap)

    return p
end

"""
    phasediagram(name, field=:ρ)
    phasediagram!(ax, name, field)

Plot a phase diagram as a heatmap of `field` over temperature (in Celsius) and pressure (in
kbar). `name` is the name of the diagram file, as used by `read_phase_diagram`, e.g.
`phasediagram("Rhyolite.in", :ρ)`.
"""
Makie.@recipe(PhaseDiagram) do scene
    Makie.Attributes(colormap = :batlow)
end

function Makie.plot!(p::PhaseDiagram{<:Tuple{<:AbstractString, <:Symbol}})
    name, field = p[1], p[2]

    values = Makie.lift(name, field) do n, f
        pd = read_phase_diagram(n)
        # T_K/P_bar are 2D grids; the heatmap axes are their first row/column
        (pd.T_K[:,1] .- 273.15, pd.P_bar[1,:] ./ 1e3, pd[f])
    end

    Makie.heatmap!(p, (@lift $values[1]), (@lift $values[2]), (@lift $values[3]);
                   colormap = p.colormap)

    return p
end

include("MakieGUI.jl")

end # module
