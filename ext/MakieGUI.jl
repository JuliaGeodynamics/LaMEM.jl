# The interactive viewer. Included from MakieExt.jl, so Makie is available here.
#
# This is deliberately written against `Makie` rather than `GLMakie`: it works with any
# backend, so the same code produces an interactive window under GLMakie and a static
# figure (or a movie) under CairoMakie on a machine without a display.

"""
    field_menu_entries(data::CartData)

Internal helper listing the fields of `data` as they should appear in the field menu, as
`(label, (field, dim))` tuples. Scalars appear under their own name, while a vector field is
expanded into one entry per component, so that `velocity` becomes `velocity[1]`, `[2]`, `[3]`.
"""
function field_menu_entries(data::CartData)
    entries = Tuple{String,Tuple{Symbol,Int}}[]
    for (name, values) in pairs(data.fields)
        if values isa Tuple
            for d in eachindex(values)
                push!(entries, ("$(name)[$d]", (name, d)))
            end
        else
            push!(entries, (String(name), (name, 1)))
        end
    end
    return entries
end

"""
    scalar_field(data::CartData, field::Symbol, dim::Int)

Internal helper returning one 3D scalar array out of `data`: the field itself if it is a
scalar, and component `dim` if it is a vector or tensor.
"""
function scalar_field(data::CartData, field::Symbol, dim::Int)
    values = getproperty(data.fields, field)
    return values isa Tuple ? values[dim] : values
end

"""
    timesteps_of(model::Model)

Internal helper returning the timesteps of a finished simulation and the physical time of
each, as `(timesteps, times)`. Returns empty vectors if the model has no output yet, which
lets the viewer open on a setup that has not been run.
"""
function timesteps_of(model::Model)
    try
        timesteps, _, times = read_LaMEM_simulation(model)
        return collect(timesteps), collect(times)
    catch
        return Int[], Float64[]
    end
end

"""
    view_model(model::Model; kwargs...)
    view_model(data::CartData; kwargs...)

Open an interactive viewer on a LaMEM simulation, as an alternative to loading the output
into Paraview. Pass a `Model` to step through the timesteps of a finished run, or a single
`CartData` set to look at one timestep.

The window shows a cross-section on the left and a 3D view on the right, with controls for:

- the **field** to display, chosen from the fields present in the output (a vector field such
  as the velocity is listed per component),
- the **timestep**, as a slider, with a play button that animates the simulation,
- the **slice position**, which moves the cross-section through the model,
- **isocontours** of the displayed field in the cross-section, and an **isosurface** in the
  3D view, with a slider for the level,
- **velocity arrows**, drawn on top of the cross-section on demand,
- the **colormap**.

It returns the figure, so it can be displayed, saved, or used further:

```julia
julia> using GLMakie, LaMEM          # an interactive window
julia> view_model(model)
```

Use [`save_movie`](@ref) to write an animation of the simulation to disk.

# Keyword arguments
- `field`: the field shown initially (default: the first one, usually `:phase`)
- `dim`: the component shown initially for a vector field
- `x`, `y`, `z`: the position of the cross-section; leaving all three out slices through the
  middle of the thinnest direction, which for a quasi-2D setup is the plane worth seeing
- `colormap`: the initial colormap
- `isosurface`: whether the isosurface and the isocontours start switched on (default `true`,
  since the volume rendering shows little of a phase field)
- `arrows`: whether the velocity arrows start switched on (default `false`)
- `size`: the size of the window
"""
function LaMEM.view_model(model::Model; kwargs...)
    timesteps, times = timesteps_of(model)

    if isempty(timesteps)
        # nothing has been run yet: show the initial setup, which needs no output files
        data, _ = model_data(model, nothing, false)
        return LaMEM.view_model(data; title_prefix="initial setup", kwargs...)
    end

    # read every timestep once, up front: the animation has to be able to jump between
    # them without re-reading, and a LaMEM run that fits in memory as one field fits as all
    frames = [first(read_LaMEM_timestep(model, ts)) for ts in timesteps]
    fig, _ = build_viewer(frames, times; kwargs...)
    return fig
end

function LaMEM.view_model(data::CartData; title_prefix="", kwargs...)
    fig, _ = build_viewer([data], [NaN]; title_prefix=title_prefix, kwargs...)
    return fig
end

"""
    bind_visible!(plot, toggle)

Internal helper tying the visibility of `plot` to a toggle. Makie's `connect!` does not apply
to a plot attribute, so set it directly and follow the toggle from then on.
"""
function bind_visible!(plot, toggle)
    plot.visible = toggle[]
    Makie.on(toggle) do on
        plot.visible = on
    end
    return plot
end

"""
    build_viewer(frames::Vector{<:CartData}, times; ...)

Internal helper that assembles the viewer for the already-read `frames`. Kept separate from
[`view_model`](@ref) so that both a `Model` and a single `CartData` set reach the same code,
and so that [`save_movie`](@ref) can drive the same observables.
"""
function build_viewer(frames::Vector{<:CartData}, times;
                      field=nothing, dim=1, x=nothing, y=nothing, z=nothing,
                      colormap=:roma, size=(1200,650), title_prefix="",
                      isosurface=true, arrows=false)

    entries  = field_menu_entries(first(frames))
    selected = isnothing(field) ? first(entries)[2] : (field, dim)

    fig = Makie.Figure(size=size)

    # --- controls -------------------------------------------------------------------
    controls = Makie.GridLayout(fig[1, 1:3], tellwidth=false)

    field_menu = Makie.Menu(controls[1,1], options=entries, default=nothing, width=180)
    field_menu.i_selected[] = findfirst(e -> e[2] == selected, entries)

    colormaps = [:roma, :vik, :batlow, :oleron, :lipari, :viridis, :thermal]
    colormap in colormaps || pushfirst!(colormaps, colormap)
    cmap_menu = Makie.Menu(controls[1,2],
        options = [(String(c), c) for c in colormaps],
        default = String(colormap), width=140)

    iso_toggle = Makie.Toggle(controls[1,3], active=isosurface)
    Makie.Label(controls[1,4], "isolines/surface", halign=:left)

    vel_toggle = Makie.Toggle(controls[1,5], active=arrows)
    Makie.Label(controls[1,6], "velocity arrows", halign=:left)

    # sliders: timestep (with a play button) and the slice position
    n = length(frames)
    slider_grid = Makie.GridLayout(fig[2, 1:3], tellwidth=false)

    step_slider = Makie.Slider(slider_grid[1,2], range=1:n, startvalue=n)
    Makie.Label(slider_grid[1,1], "timestep", halign=:right)
    Makie.Label(slider_grid[1,3],
        Makie.lift(i -> time_label(times, i, n), step_slider.value), halign=:left, width=190)

    play_button = Makie.Button(slider_grid[1,4], label="▶ play", width=80)

    # the slice runs along x by default, or along whichever axis the caller pinned
    axis_sym, slice_range = slice_axis_and_range(first(frames), x, y, z)
    pos_slider = Makie.Slider(slider_grid[2,2], range=slice_range,
                              startvalue=initial_slice(slice_range, x, y, z))
    Makie.Label(slider_grid[2,1], "slice ($axis_sym)", halign=:right)
    Makie.Label(slider_grid[2,3],
        Makie.lift(v -> Printf.@sprintf("%.3g", v), pos_slider.value), halign=:left, width=190)

    iso_slider = Makie.Slider(slider_grid[3,2], range=range(0, 1, 101), startvalue=0.5)
    Makie.Label(slider_grid[3,1], "iso level", halign=:right)

    # --- the data behind the plots --------------------------------------------------
    # everything below is derived, so moving a slider or picking a field updates the plots
    frame = Makie.lift(i -> frames[i], step_slider.value)
    sel   = Makie.lift(i -> entries[i][2], field_menu.i_selected)

    slice = Makie.lift(frame, sel, pos_slider.value) do d, (f, dm), pos
        xs, zs, vals, axes_str, cb = slice_of_at(d, f, dm, axis_sym, pos)
        (x=xs, z=zs, values=vals, labels=axes_str, colorbar=cb)
    end

    volume_field = Makie.lift(frame, sel) do d, (f, dm)
        scalar_field(d, f, dm)
    end

    # a level in data units, from the 0-1 slider, so one slider fits every field
    iso_level = Makie.lift(volume_field, iso_slider.value) do vals, frac
        lo, hi = extrema(vals)
        lo + frac*(hi - lo)
    end

    # --- the cross-section ------------------------------------------------------------
    ax2d = Makie.Axis(fig[3,1],
        xlabel = Makie.lift(s -> s.labels.x_str, slice),
        ylabel = Makie.lift(s -> s.labels.z_str, slice),
        title  = Makie.lift((s,i) -> viewer_title(title_prefix, s, times, i, n), slice, step_slider.value),
        aspect = Makie.DataAspect())

    hm = Makie.heatmap!(ax2d,
        Makie.lift(s -> s.x, slice),
        Makie.lift(s -> s.z, slice),
        Makie.lift(s -> s.values, slice),
        colormap = Makie.lift(identity, cmap_menu.selection))

    # its own column, rather than a sublayout inside the axis cell, so that it cannot
    # overlap either the cross-section or the 3D view
    Makie.Colorbar(fig[3,2], hm, label=Makie.lift(s -> s.colorbar, slice),
                   flipaxis=false, labelrotation=Float32(pi/2))

    # isocontours on top of the cross-section
    contours = Makie.contour!(ax2d,
        Makie.lift(s -> s.x, slice),
        Makie.lift(s -> s.z, slice),
        Makie.lift(s -> s.values, slice),
        levels = Makie.lift(l -> [l], iso_level),
        color = :black, linewidth = 2)
    bind_visible!(contours, iso_toggle.active)

    # velocity arrows, subsampled so the plot stays readable
    arrows_data = Makie.lift(frame, pos_slider.value) do d, pos
        velocity_arrows(d, axis_sym, pos)
    end
    arr = Makie.arrows2d!(ax2d,
        Makie.lift(a -> a.x, arrows_data),
        Makie.lift(a -> a.z, arrows_data),
        Makie.lift(a -> a.u, arrows_data),
        Makie.lift(a -> a.w, arrows_data),
        lengthscale = Makie.lift(a -> a.scale, arrows_data),
        color = :black)
    bind_visible!(arr, vel_toggle.active)

    # --- the 3D view -------------------------------------------------------------------
    # Note: `volume!` and the 3D `contour!` below need a real 3D rasterizer, which CairoMakie
    # does not have -- under CairoMakie this panel stays empty, while the cross-section on the
    # left renders fine. Use GLMakie for the 3D view.
    ax3d = Makie.Axis3(fig[3,3],
        xlabel="x", ylabel="y", zlabel="z",
        title = Makie.lift(s -> "3D: "*s.colorbar, slice))

    # `volume!` and the 3D `contour!` take the extent of each axis as an interval, not the
    # coordinate vectors; the LaMEM grid is regular, so its extrema describe it fully
    grid  = first(frames)
    xs3   = extrema(grid.x.val)
    ys3   = extrema(grid.y.val)
    zs3   = extrema(grid.z.val)

    vol = Makie.volume!(ax3d, xs3, ys3, zs3, volume_field,
                        algorithm = :absorption, absorption = 4.0f0,
                        colormap = Makie.lift(identity, cmap_menu.selection))

    iso = Makie.contour!(ax3d, xs3, ys3, zs3, volume_field,
                         levels = Makie.lift(l -> [l], iso_level),
                         alpha = 0.6,
                         colormap = Makie.lift(identity, cmap_menu.selection))
    bind_visible!(iso, iso_toggle.active)
    # the volume rendering only gets in the way once an isosurface is shown
    vol.visible = !iso_toggle.active[]
    Makie.on(iso_toggle.active) do on
        vol.visible = !on
    end

    # --- the play button ----------------------------------------------------------------
    Makie.on(play_button.clicks) do _
        n == 1 && return
        @async for i in 1:n
            step_slider.value[] = i
            sleep(1/8)
        end
    end

    Makie.colsize!(fig.layout, 1, Makie.Relative(0.44))
    Makie.colsize!(fig.layout, 3, Makie.Relative(0.44))
    Makie.colgap!(fig.layout, 1, 30)
    Makie.colgap!(fig.layout, 2, 40)

    return fig, step_slider
end

"""
    time_label(times, i, n)

Internal helper for the label next to the timestep slider.
"""
function time_label(times, i, n)
    t = times[min(i, length(times))]
    isnan(t) && return "  (single step)"
    return Printf.@sprintf("  %d/%d   t = %.4g", i, n, t)
end

"""
    viewer_title(prefix, slice, times, i, n)

Internal helper for the title above the cross-section.
"""
function viewer_title(prefix, slice, times, i, n)
    # the title from `cross_section` carries the raw slider position, e.g.
    # "x = -0.03389830508474576"; round it so the title stays readable
    title_str = replace(slice.labels.title_str,
                        r"(-?\d+\.\d+)" => m -> Printf.@sprintf("%.3g", parse(Float64, m)))
    base = isempty(prefix) ? title_str : prefix*"  "*title_str
    t = times[min(i, length(times))]
    return isnan(t) ? base : base*Printf.@sprintf("   t = %.4g", t)
end

"""
    slice_axis_and_range(data, x, y, z)

Internal helper picking the axis the slice runs along and the positions it can take. The
caller pins an axis by giving `x`, `y` or `z`; by default the section moves along `x`.
"""
function slice_axis_and_range(data::CartData, x, y, z)
    !isnothing(x) && return :x, range(extrema(data.x.val)..., 60)
    !isnothing(y) && return :y, range(extrema(data.y.val)..., 60)
    !isnothing(z) && return :z, range(extrema(data.z.val)..., 60)

    # Nothing pinned: slice along the *thinnest* axis, so that a quasi-2D setup (which LaMEM
    # models often are, with only a few elements in y) shows its interesting plane rather
    # than a sliver of it.
    widths = (abs(-(extrema(data.x.val)...)),
              abs(-(extrema(data.y.val)...)),
              abs(-(extrema(data.z.val)...)))
    axis = (:x, :y, :z)[argmin(widths)]
    values = axis === :x ? data.x.val : axis === :y ? data.y.val : data.z.val
    return axis, range(extrema(values)..., 60)
end

initial_slice(slice_range, x, y, z) =
    something(x, y, z, (first(slice_range)+last(slice_range))/2)

"""
    slice_of_at(data, field, dim, axis, pos)

Internal helper cutting a cross-section perpendicular to `axis` at `pos`, reusing the same
`slice_of` that the plotting recipes use so that both show the same thing.
"""
function slice_of_at(data::CartData, field::Symbol, dim::Int, axis::Symbol, pos)
    if axis === :y
        return slice_of(data, field, dim, nothing, pos, nothing)
    elseif axis === :z
        return slice_of(data, field, dim, nothing, nothing, pos)
    else
        return slice_of(data, field, dim, pos, nothing, nothing)
    end
end

"""
    velocity_arrows(data, axis, pos; every=2)

Internal helper returning the in-plane velocity components on the cross-section, subsampled
by `every` so the arrows stay readable, together with a length scale that keeps them a
sensible fraction of the model. Data without a velocity field gives a single arrow of zero
length, since `arrows2d!` rejects empty input.
"""
function velocity_arrows(data::CartData, axis::Symbol, pos; every=2)
    if !hasproperty(data.fields, :velocity)
        # `arrows2d!` cannot handle empty input, so hand back a single arrow of zero length
        # instead; it is invisible, and the toggle is what the user sees anyway
        return (x=[0.0], z=[0.0], u=[0.0], w=[0.0], scale=1.0)
    end

    # the two in-plane components of a section perpendicular to `axis`
    dims = axis === :y ? (1,3) : axis === :z ? (1,2) : (2,3)

    xs, zs, u, _, _ = slice_of_at(data, :velocity, dims[1], axis, pos)
    _,  _,  w, _, _ = slice_of_at(data, :velocity, dims[2], axis, pos)

    ix = 1:every:length(xs)
    iz = 1:every:length(zs)

    xg = repeat(collect(xs[ix]), 1, length(iz))
    zg = repeat(collect(zs[iz])', length(ix), 1)
    us = u[ix, iz]
    ws = w[ix, iz]

    # scale the arrows to about one grid spacing at the largest velocity
    vmax = maximum(hypot.(us, ws))
    dx = length(xs) > 1 ? abs(xs[2]-xs[1])*every : 1.0
    scale = vmax > 0 ? dx/vmax : 1.0

    return (x=vec(xg), z=vec(zg), u=vec(us), w=vec(ws), scale=scale)
end

"""
    save_movie(filename, model::Model; framerate=8, kwargs...)

Write an animation of a finished simulation to `filename`, stepping through its timesteps.
The format follows the extension, so `"run.mp4"` and `"run.gif"` both work (Makie writes
`mp4`, `gif`, `mkv` and `webm`).

The keyword arguments are those of [`view_model`](@ref): the field, slice position,
colormap, and so on, apply to the movie as they do to the viewer.

```julia
julia> using CairoMakie, LaMEM       # works headlessly, e.g. on an HPC node
julia> save_movie("subduction.mp4", model, field=:temperature, x=0)
```
"""
function LaMEM.save_movie(filename::AbstractString, model::Model; framerate=8, kwargs...)
    timesteps, times = timesteps_of(model)
    isempty(timesteps) && error("this model has no output to animate; run it first with `run_lamem`")

    frames = [first(read_LaMEM_timestep(model, ts)) for ts in timesteps]
    fig, slider = build_viewer(frames, times; kwargs...)

    Makie.record(fig, filename, eachindex(frames); framerate=framerate) do i
        slider.value[] = i
    end

    return filename
end
