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
    twod_window_size(data::CartData; width=1000, controls=230)

Internal helper giving a window size that suits a 2D model: the plot area follows the aspect
ratio of the model, next to the fixed-width control panel. Very flat or very tall models are
kept within bounds so the window stays usable.
"""
function twod_window_size(data::CartData; panel=215, plot_width=760, margin=90,
                          panel_height=560)
    axis = thin_axis(data)
    # the two directions that are actually resolved
    ext(v) = abs(-(extrema(v)...))
    w, h = axis === :y ? (ext(data.x.val), ext(data.z.val)) :
           axis === :z ? (ext(data.x.val), ext(data.y.val)) :
                         (ext(data.y.val), ext(data.z.val))

    # the axis is a DataAspect one, so its height follows the model's proportions; the
    # control panel needs a certain height of its own, and the window has to satisfy both
    inner  = plot_width - 170                       # the two colorbars and the labels
    height = h > 0 && w > 0 ? inner*h/w : 400
    height = clamp(height + margin, panel_height, 760)

    return (panel + plot_width, round(Int, height))
end

"""
    slice_outline(xs, ys, zs, axis::Symbol, pos)

Internal helper giving the closed outline of the cross-section's plane inside the 3D box, so
that the 3D view shows where the section on the left is taken.
"""
function slice_outline(xs, ys, zs, axis::Symbol, pos)
    corners = if axis === :x
        [Makie.Point3f(pos, ys[1], zs[1]), Makie.Point3f(pos, ys[2], zs[1]),
         Makie.Point3f(pos, ys[2], zs[2]), Makie.Point3f(pos, ys[1], zs[2])]
    elseif axis === :y
        [Makie.Point3f(xs[1], pos, zs[1]), Makie.Point3f(xs[2], pos, zs[1]),
         Makie.Point3f(xs[2], pos, zs[2]), Makie.Point3f(xs[1], pos, zs[2])]
    else
        [Makie.Point3f(xs[1], ys[1], pos), Makie.Point3f(xs[2], ys[1], pos),
         Makie.Point3f(xs[2], ys[2], pos), Makie.Point3f(xs[1], ys[2], pos)]
    end

    # `[corners; corners[1]]` would splat the trailing point, since a `Point3f` is itself
    # iterable, and hand Makie a `Vector{Any}` of coordinates rather than points
    return push!(copy(corners), corners[1])
end

"""
    w_over_h(data::CartData, axis::Symbol)

Internal helper giving the height-to-width ratio of a cross-section perpendicular to `axis`,
which is what an `Aspect` row size needs so the plot row is exactly as tall as the plot.
"""
function w_over_h(data::CartData, axis::Symbol)
    ext(v) = abs(-(extrema(v)...))
    w, h = axis === :y ? (ext(data.x.val), ext(data.z.val)) :
           axis === :z ? (ext(data.x.val), ext(data.y.val)) :
                         (ext(data.y.val), ext(data.z.val))
    return (w > 0 && h > 0) ? h/w : 0.5
end

"""
    is_2d(model::Model)
    is_2d(data::CartData)

Internal helper telling whether this is a 2D LaMEM model. A `Model` says so itself: LaMEM
needs at least two elements in every direction, so `nel_y == 2` is exactly what
`Grid(nel=(nx,nz))` produces and is the authoritative test.

Given only the data, it has to be inferred. LaMEM needs at least two elements
in every direction, so a 2D setup is never flat: it has three grid points across in its
output, and six in the marker grid of the setup. What marks it as 2D is that one direction
is far coarser than the others. Such a model has nothing to show in 3D, so the viewer leaves
the 3D panel out.
"""
is_2d(model::Model) = first(model.Grid.nel_y) == 2

function is_2d(data::CartData)
    dims = Base.size(data.x.val)
    thin = minimum(dims)
    # Without the model this has to be read off the grid, and an absolute threshold does not
    # do it: LaMEM output has three points across a 2D model, but the marker grid of the
    # same setup has three per cell, so six. What marks a model as 2D is that one direction
    # is far coarser than the others, rather than any particular count.
    return thin <= 3 || thin*8 <= maximum(dims)
end

"""
    thin_axis(data::CartData)

Internal helper naming the axis a 2D model is flat in.
"""
function thin_axis(data::CartData)
    return (:x, :y, :z)[argmin(Base.size(data.x.val))]
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
        return LaMEM.view_model(data; title_prefix="initial setup", twod=is_2d(model), kwargs...)
    end

    # read every timestep once, up front: the animation has to be able to jump between
    # them without re-reading, and a LaMEM run that fits in memory as one field fits as all
    frames = [first(read_LaMEM_timestep(model, ts)) for ts in timesteps]
    fig, _ = build_viewer(frames, times; twod=is_2d(model), kwargs...)
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
    bind_slider_box!(slider, box, fmt)

Internal helper tying a text box to a slider, so a value can be typed exactly rather than
only dragged to. Moving the slider rewrites the box, and submitting the box moves the slider
to the nearest value in its range. A flag breaks the loop between the two, and the typed
value is clamped to the slider's range, so a number outside it snaps to the closest end
instead of being ignored.
"""
function bind_slider_box!(slider, box, fmt)
    updating = Ref(false)

    show_value(v) = fmt == "%d" ? string(round(Int, v)) :
                                  Printf.format(Printf.Format(fmt), v)
    # start from the slider's current value rather than the placeholder
    box.displayed_string[] = show_value(slider.value[])

    Makie.on(slider.value) do v
        updating[] && return
        updating[] = true
        box.displayed_string[] = show_value(v)
        updating[] = false
    end

    Makie.on(box.stored_string) do str
        updating[] && return
        isnothing(str) && return
        value = tryparse(Float64, str)
        isnothing(value) && return

        rng = slider.range[]
        # snap to the nearest value the slider can actually take
        idx = argmin(abs.(collect(rng) .- value))

        updating[] = true
        Makie.set_close_to!(slider, collect(rng)[idx])
        updating[] = false
    end

    return box
end

"""
    build_viewer(frames::Vector{<:CartData}, times; ...)

Internal helper that assembles the viewer for the already-read `frames`. Kept separate from
[`view_model`](@ref) so that both a `Model` and a single `CartData` set reach the same code,
and so that [`save_movie`](@ref) can drive the same observables.
"""
function build_viewer(frames::Vector{<:CartData}, times;
                      field=nothing, dim=1, x=nothing, y=nothing, z=nothing,
                      colormap=:roma, size=nothing, title_prefix="",
                      isosurface=nothing, arrows=false, contours=nothing,
                      contour_colormap=:managua, threed=nothing, twod=nothing)

    entries  = field_menu_entries(first(frames))
    selected = isnothing(field) ? first(entries)[2] : (field, dim)

    # a 2D model has nothing to show in three dimensions, so leave that panel out and give
    # the cross-section the whole window
    over_colormap = contour_colormap
    twod = (isnothing(twod) ? is_2d(first(frames)) : twod) || threed === false
    isnothing(isosurface) && (isosurface = !twod)
    # A 2D window is sized to the model, so that the `DataAspect` axis fills it instead of
    # leaving a band of empty figure under a wide, flat model.
    isnothing(size) && (size = twod ? twod_window_size(first(frames)) : (1420,700))

    # CairoMakie has no 3D rasterizer, so `volume!` and the 3D `contour!` below draw
    # nothing and the 3D panel comes out empty. That is easy to mistake for a broken
    # viewer, so say it rather than leave the user guessing.
    if !twod && nameof(Makie.current_backend()) !== :GLMakie
        @warn """The 3D view needs GLMakie; with $(nameof(Makie.current_backend())) that \
                 panel stays empty. Run `using GLMakie; GLMakie.activate!()` before \
                 `view_model`, or pass `threed=false` to leave the panel out."""
    end

    fig = Makie.Figure(size=size, backgroundcolor=:white)

    # --- layout ---------------------------------------------------------------------
    # The controls sit in a panel down the left side, grouped under headings, and the plots
    # take the rest of the window. Keeping them out of the plot area means the window does
    # not have to grow a strip of widgets across the top, and the sections make it clear
    # what belongs to what.
    panel_width = 215

    # the name of the window, which also lands in a saved image, and is set on the GLMakie
    # window itself where that is possible
    Makie.Label(fig[1, 1:2], "LaMEM Model Viewer", font=:bold, fontsize=17,
                color=:gray20, halign=:left, padding=(6, 0, 2, 6), tellwidth=false)

    Makie.Box(fig[2,1], color=(:gray92, 0.6), strokecolor=(:gray70, 0.5), strokewidth=1,
              cornerradius=10)
    panel = Makie.GridLayout(fig[2,1], tellheight=false, halign=:center, valign=:top)
    Makie.colsize!(fig.layout, 1, Makie.Fixed(panel_width))

    plots = Makie.GridLayout(fig[2,2])

    section(row, text) = Makie.Label(panel[row, 1:2], text, font=:bold, fontsize=13,
                                     halign=:left, color=:gray25, tellwidth=false)
    row = 0

    # --- what to show ----------------------------------------------------------------
    section(row += 1, "Field")
    field_menu = Makie.Menu(panel[row += 1, 1:2], options=entries, default=nothing,
                            width=Makie.Relative(1.0))
    field_menu.i_selected[] = findfirst(e -> e[2] == selected, entries)

    colormaps = [:roma, :vik, :batlow, :oleron, :lipari, :viridis, :thermal]
    colormap in colormaps || pushfirst!(colormaps, colormap)
    cmap_menu = Makie.Menu(panel[row += 1, 1:2],
        options = [(String(c), c) for c in colormaps],
        default = String(colormap), width=Makie.Relative(1.0))

    # --- overlays ---------------------------------------------------------------------
    section(row += 1, "Overlays")

    iso_toggle = Makie.Toggle(panel[row += 1, 1], active=isosurface)
    Makie.Label(panel[row, 2], twod ? "isolines" : "isolines / surface",
                halign=:left, fontsize=12)

    vel_toggle = Makie.Toggle(panel[row += 1, 1], active=arrows)
    Makie.Label(panel[row, 2], "velocity arrows", halign=:left, fontsize=12)

    # contours of a *second* field, e.g. the temperature over the phases. "none" is the
    # default; components are left out, since a contour of one velocity component is rarely
    # what is wanted.
    scalar_entries = [("none", nothing); [(e[1], e[2]) for e in entries]]
    Makie.Label(panel[row += 1, 1:2], "contours of", halign=:left, fontsize=12,
                color=:gray40, tellwidth=false)
    over_menu = Makie.Menu(panel[row += 1, 1:2], options=scalar_entries,
                           default="none", width=Makie.Relative(1.0))
    if !isnothing(contours)
        idx = findfirst(e -> e[2] isa Tuple && e[2][1] === contours, scalar_entries)
        isnothing(idx) || (over_menu.i_selected[] = idx)
    end

    # --- the cross-section ------------------------------------------------------------
    section(row += 1, "Cross-section")

    n = length(frames)
    axis0, slice_range = slice_axis_and_range(first(frames), x, y, z)

    Makie.Label(panel[row += 1, 1], "along", halign=:left, fontsize=12, color=:gray40)
    axis_menu = Makie.Menu(panel[row, 2],
        options=[("x", :x), ("y", :y), ("z", :z)], default=String(axis0),
        width=Makie.Relative(1.0))

    pos_slider = Makie.Slider(panel[row += 1, 1:2], range=slice_range,
                              startvalue=initial_slice(slice_range, x, y, z))
    pos_box = Makie.Textbox(panel[row += 1, 1:2], validator=Float64,
                            width=Makie.Relative(1.0))
    bind_slider_box!(pos_slider, pos_box, "%.4g")

    iso_slider = Makie.Slider(panel[row += 1, 1:2], range=range(0, 1, 101), startvalue=0.5)
    Makie.Label(panel[row += 1, 1], "iso level", halign=:left, fontsize=12, color=:gray40)
    iso_box = Makie.Textbox(panel[row, 2], validator=Float64, width=Makie.Relative(1.0))
    bind_slider_box!(iso_slider, iso_box, "%.3g")

    # --- the timestep ------------------------------------------------------------------
    section(row += 1, "Timestep")

    step_slider = Makie.Slider(panel[row += 1, 1:2], range=1:n, startvalue=n)
    step_box = Makie.Textbox(panel[row += 1, 1], validator=Int, width=Makie.Relative(1.0))
    bind_slider_box!(step_slider, step_box, "%d")
    play_button = Makie.Button(panel[row, 2], label="▶ play", width=Makie.Relative(1.0))

    Makie.Label(panel[row += 1, 1:2],
        Makie.lift(i -> time_label(times, i, n), step_slider.value),
        halign=:left, fontsize=11, color=:gray40, tellwidth=false)

    Makie.rowgap!(panel, 6)
    for r in 1:row                      # a little more air above each section heading
        Makie.rowsize!(panel, r, Makie.Auto(false))
    end
    Makie.colgap!(panel, 8)

    # moving to another axis rescales the position slider to that axis' extent
    axis_sym = axis_menu.selection
    Makie.on(axis_sym) do a
        isnothing(a) && return
        _, rng = slice_axis_and_range(first(frames), a === :x ? 1.0 : nothing,
                                                     a === :y ? 1.0 : nothing,
                                                     a === :z ? 1.0 : nothing)
        pos_slider.range[] = rng
        pos_slider.value[] = (first(rng) + last(rng))/2
    end

    # --- the data behind the plots --------------------------------------------------
    # everything below is derived, so moving a slider or picking a field updates the plots
    frame = Makie.lift(i -> frames[i], step_slider.value)
    sel   = Makie.lift(i -> entries[i][2], field_menu.i_selected)

    slice = Makie.lift(frame, sel, pos_slider.value, axis_sym) do d, (f, dm), pos, ax
        xs, zs, vals, axes_str, cb = slice_of_at(d, f, dm, ax, pos)
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
    # `tellwidth=false` on the colorbar's column would let it drift to the far side of the
    # cell; instead the colorbar is pinned to the axis, so it follows the plot as the
    # DataAspect axis resizes
    plot_grid = Makie.GridLayout(plots[1,1])
    ax2d = Makie.Axis(plot_grid[1,1],
        xlabel = Makie.lift(s -> s.labels.x_str, slice),
        ylabel = Makie.lift(s -> s.labels.z_str, slice),
        title  = Makie.lift((s,i) -> viewer_title(title_prefix, s, times, i, n), slice, step_slider.value),
        aspect = Makie.DataAspect())

    hm = Makie.heatmap!(ax2d,
        Makie.lift(s -> s.x, slice),
        Makie.lift(s -> s.z, slice),
        Makie.lift(s -> s.values, slice),
        colormap = Makie.lift(identity, cmap_menu.selection))

    # A slim colorbar directly beside the cross-section. `height=Relative(1)` ties it to the
    # axis rather than the row, so it does not stretch over the whole window.
    Makie.Colorbar(plot_grid[1,2], hm, label=Makie.lift(s -> s.colorbar, slice),
                   width=12, ticklabelsize=11, labelsize=12,
                   height=Makie.Relative(1.0), halign=:left)
    Makie.colsize!(plot_grid, 1, Makie.Auto(true))
    Makie.colgap!(plot_grid, 1, 10)

    # isocontours of the displayed field
    isolines = Makie.contour!(ax2d,
        Makie.lift(s -> s.x, slice),
        Makie.lift(s -> s.z, slice),
        Makie.lift(s -> s.values, slice),
        levels = Makie.lift(l -> [l], iso_level),
        color = :black, linewidth = 2)
    bind_visible!(isolines, iso_toggle.active)

    # contours of a second field on top, e.g. the temperature over the phases
    overlay = Makie.lift(frame, over_menu.selection, pos_slider.value, axis_sym) do d, choice, pos, ax
        isnothing(choice) && return nothing
        f, dm = choice
        xs, zs, vals, _, _ = slice_of_at(d, f, dm, ax, pos)
        (x=xs, z=zs, values=vals)
    end

    # the range the contour colours span, so that the contours and their colorbar agree
    over_range = Makie.lift(overlay, slice) do o, sl
        vals = isnothing(o) ? sl.values : o.values
        lo, hi = extrema(vals)
        lo == hi ? (lo - 1, hi + 1) : (lo, hi)      # a constant field has no range to map
    end

    # `contour!` cannot take `nothing`, so when no field is chosen keep the coordinates of
    # the displayed slice and hide the plot instead. The contours are coloured by their own
    # value, on a colormap of their own so they stay legible over the heatmap.
    over_lines = Makie.contour!(ax2d,
        Makie.lift((o,sl) -> isnothing(o) ? sl.x      : o.x,      overlay, slice),
        Makie.lift((o,sl) -> isnothing(o) ? sl.z      : o.z,      overlay, slice),
        Makie.lift((o,sl) -> isnothing(o) ? sl.values : o.values, overlay, slice),
        levels = 8, linewidth = 2,
        colormap = over_colormap, colorrange = over_range)
    # set it from the current value first: `on` only fires on later changes
    over_lines.visible = !isnothing(overlay[])
    Makie.on(overlay) do o
        over_lines.visible = !isnothing(o)
    end

    # a second colorbar for those contours, which only makes sense once a field is chosen.
    # It lives in its own column of the plot grid; that column is given no width when
    # nothing is selected, so the plot takes the space back.
    over_cb = Makie.Colorbar(plot_grid[1,3],
        colormap = over_colormap, limits = over_range,
        label = Makie.lift(c -> isnothing(c) ? "" : String(c[1]), over_menu.selection),
        width = 12, ticklabelsize = 11, labelsize = 12,
        height = Makie.Relative(1.0), halign = :left)

    function show_overlay_colorbar!(on)
        over_cb.blockscene.visible[] = on
        Makie.colsize!(plot_grid, 3, on ? Makie.Auto() : Makie.Fixed(0))
        Makie.colgap!(plot_grid, 2, on ? 10 : 0)
    end
    show_overlay_colorbar!(!isnothing(over_menu.selection[]))
    Makie.on(over_menu.selection) do choice
        show_overlay_colorbar!(!isnothing(choice))
    end

    # velocity arrows, subsampled so the plot stays readable
    arrows_data = Makie.lift(frame, pos_slider.value, axis_sym) do d, pos, ax
        velocity_arrows(d, ax, pos)
    end
    arr = Makie.arrows2d!(ax2d,
        Makie.lift(a -> a.x, arrows_data),
        Makie.lift(a -> a.z, arrows_data),
        Makie.lift(a -> a.u, arrows_data),
        Makie.lift(a -> a.w, arrows_data),
        lengthscale = Makie.lift(a -> a.scale, arrows_data),
        color = :black)
    bind_visible!(arr, vel_toggle.active)

    # --- the 3D view, for a 3D model only -------------------------------------------------
    # A 2D model is flat in one direction and has nothing to show here, so it gets the
    # cross-section alone and the window stays uncluttered.
    #
    # Note: `volume!` and the 3D `contour!` need a real 3D rasterizer, which CairoMakie does
    # not have -- under CairoMakie this panel stays empty while the cross-section renders
    # fine. Use GLMakie for the 3D view.
    if !twod
        # `aspect=:data` keeps the three axes in proportion to the model, so a sphere looks
        # like a sphere; the default stretches each axis to fill the cell
        ax3d = Makie.Axis3(plots[1,2],
            xlabel="x", ylabel="y", zlabel="z",
            aspect = :data,
            title = Makie.lift(s -> "3D: "*s.colorbar, slice))

        # `volume!` and the 3D `contour!` take the extent of each axis as an interval, not
        # the coordinate vectors; the LaMEM grid is regular, so its extrema describe it fully
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

        # show where the cross-section is taken: a translucent rectangle in the 3D box at
        # the position of the slider, so the two panels can be read together
        outline = Makie.lift(pos_slider.value, axis_sym) do pos, ax
            slice_outline(xs3, ys3, zs3, ax, pos)
        end
        # a shaded quad, so the plane reads as a surface, with its border drawn on top
        quad = Makie.lift(outline) do pts
            Makie.GeometryBasics.Mesh(pts[1:4],
                [Makie.GeometryBasics.GLTriangleFace(1,2,3),
                 Makie.GeometryBasics.GLTriangleFace(1,3,4)])
        end
        Makie.mesh!(ax3d, quad, color = (:dodgerblue, 0.20), transparency = true,
                    shading = Makie.NoShading)
        Makie.lines!(ax3d, outline, color = (:dodgerblue, 0.9), linewidth = 3)
        # the volume rendering only gets in the way once an isosurface is shown
        vol.visible = !iso_toggle.active[]
        Makie.on(iso_toggle.active) do on
            vol.visible = !on
        end
    end

    # --- the play button ----------------------------------------------------------------
    Makie.on(play_button.clicks) do _
        n == 1 && return
        @async for i in 1:n
            step_slider.value[] = i
            sleep(1/8)
        end
    end

    if !twod
        # cross-section and 3D view share the plot area. The 3D cell is made square, since
        # `aspect=:data` keeps the box in proportion *within its cell* -- in a cell that is
        # much wider than tall the whole box, and everything in it, comes out stretched.
        # the 3D cell is square, so `aspect=:data` is not fighting a stretched cell; the
        # cross-section keeps whatever is left, which is why the row is not squeezed
        Makie.colsize!(plots, 2, Makie.Aspect(1, 1.0))
        Makie.colgap!(plots, 1, 24)
    else
        # a DataAspect axis is as tall as the data makes it; without this the colorbars
        # beside it stretch over the whole window instead of matching the plot
        Makie.rowsize!(plots, 1, Makie.Aspect(1, w_over_h(first(frames), axis0)))
    end
    Makie.colgap!(fig.layout, 1, 12)

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
range is finely sampled, so that a position typed into the box next to the slider is met
closely rather than snapping to a coarse step. The
caller pins an axis by giving `x`, `y` or `z`; by default the section moves along `x`.
"""
function slice_axis_and_range(data::CartData, x, y, z)
    !isnothing(x) && return :x, range(extrema(data.x.val)..., 401)
    !isnothing(y) && return :y, range(extrema(data.y.val)..., 401)
    !isnothing(z) && return :z, range(extrema(data.z.val)..., 401)

    # Nothing pinned: slice along the *thinnest* axis, so that a quasi-2D setup (which LaMEM
    # models often are, with only a few elements in y) shows its interesting plane rather
    # than a sliver of it.
    widths = (abs(-(extrema(data.x.val)...)),
              abs(-(extrema(data.y.val)...)),
              abs(-(extrema(data.z.val)...)))
    axis = (:x, :y, :z)[argmin(widths)]
    values = axis === :x ? data.x.val : axis === :y ? data.y.val : data.z.val
    return axis, range(extrema(values)..., 401)
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
    fig, slider = build_viewer(frames, times; twod=is_2d(model), kwargs...)

    Makie.record(fig, filename, eachindex(frames); framerate=framerate) do i
        slider.value[] = i
    end

    return filename
end
