# Plotting with Makie

Besides the `Plots.jl` routines (`plot_cross_section` and friends), `LaMEM.jl` comes with
plotting recipes for [Makie](https://docs.makie.org). They are loaded automatically as soon
as you load a Makie backend, and nothing of Makie is installed or loaded if you do not:

- [GLMakie](https://docs.makie.org/stable/explanations/backends/glmakie) for interactive
  plots on a machine with a display,
- [CairoMakie](https://docs.makie.org/stable/explanations/backends/cairomakie) on machines
  without an interactive display, such as an HPC login node or a CI runner.

Both are used in the same way, so you can develop a figure interactively with `GLMakie` and
produce the same figure headlessly with `CairoMakie` by swapping the `using` line:

```julia
julia> using LaMEM, GeophysicalModelGenerator, GLMakie   # or CairoMakie
adding Makie.jl plotting extensions for LaMEM
```

## Cross-sections

`crosssection` cuts a section through a model and plots it as a heatmap. It works on a
`Model`, in which case the *initial setup* is plotted without LaMEM having run at all:

```julia
julia> model = Model(Grid(nel=(16,16,16), x=[-2,2], coord_y=[-1,1], coord_z=[-1,1]),
                     Output(out_dir="example"))
julia> add_sphere!(model, cen=(0.0,0.0,0.0), radius=0.5)
julia> crosssection(model, field=:phase, x=0)
```

Once the model has run, `timestep` selects which output to plot; use `:last` for the last
one:

```julia
julia> run_lamem(model, 1)
julia> crosssection(model, field=:velocity, dim=3, x=0, timestep=:last)
```

`dim` picks the component of a vector or tensor field, so `field=:velocity, dim=3` plots
``v_z``. You can equally plot a data set that you read yourself:

```julia
julia> data, time = read_LaMEM_timestep(model, last=true)
julia> crosssection(data, field=:phase, x=0)
```

If you give none of `x`, `y` or `z`, the section is taken through the middle of the model
in `x`.

## Composing figures

These are Makie *recipes*, not functions that return a finished figure. The mutating form
`crosssection!` plots into an axis that you made yourself, so a cross-section can be combined
with anything else in a figure of your own layout:

```julia
julia> fig = Figure(size=(900,380))
julia> for (i,field) in enumerate([:phase, :temperature])
           ax = Axis(fig[1,i], title=String(field), aspect=DataAspect())
           crosssection!(ax, model, field=field, x=0)
       end
julia> fig
```

A recipe cannot label the axis it is drawn into, because the axis belongs to you. Use
`axis_labels` to get the labels that belong to a plot, and pass them to the `Axis` and
`Colorbar`:

```julia
julia> lab = axis_labels(model, :velocity, dim=3, x=0, timestep=:last)
julia> fig = Figure()
julia> ax  = Axis(fig[1,1], xlabel=lab.xlabel, ylabel=lab.ylabel, title=lab.title,
                  aspect=DataAspect())
julia> p   = crosssection!(ax, model, field=:velocity, dim=3, x=0, timestep=:last)
julia> Colorbar(fig[1,2], p, label=lab.colorbar)
julia> fig
```

Saving works as for any Makie figure, which is the usual way to use `CairoMakie`:

```julia
julia> save("crosssection.png", fig)
```

## Topography and phase diagrams

The free surface of a simulation is plotted with `topo`, from a data set read with
`surf=true`:

```julia
julia> topography, time = read_LaMEM_timestep(model, last=true, surf=true)
julia> topo(topography)
```

and a phase diagram with `phasediagram`, which takes the name of the diagram file as used by
`read_phase_diagram`:

```julia
julia> phasediagram("Rhyolite.in", :ρ)
```

`axis_labels` works for these too, so they can be labelled and composed in the same way.
