# Surface processes with FastScape

LaMEM can couple its free surface to [FastScape](https://fastscape.org), a landscape-evolution model that computes river incision, hillslope diffusion, sediment transport and deposition on the surface grid. Instead of the built-in erosion/sedimentation, the topography is then evolved by FastScape every time step, and the deposited sediment is turned into a LaMEM phase of your choice.

This needs a LaMEM binary that was compiled with FastScape, which is the case for `LaMEM_jll` 3.3.0 or newer (it ships `Fastscapelib_jll`). You can check this with

```julia
julia> using LaMEM
julia> println(readchomp(`$(LaMEM.LaMEM_jll.LaMEM()) -fastscape_info`))
```

## Setting it up from Julia

FastScape is switched on with `surf_mode=2` in the [`FreeSurface`](@ref) and configured with a [`FastScape`](@ref) structure, which LaMEM.jl writes as a `<FastScapeStart>`/`<FastScapeEnd>` block of the input file:

```julia
julia> using LaMEM, GeophysicalModelGenerator
julia> model = Model(Grid(nel=(32,8,16), x=[-50,50], y=[-10,10], z=[-50,10]),
                     Scaling(GEO_units(stress=1000MPa, viscosity=1e20Pa*s)),
                     Time(dt=1e-3, dt_min=1e-5, dt_max=1e-2, nstep_max=3, nstep_out=1, time_end=1),
                     FreeSurface(surf_use=1, surf_level=0.0, surf_air_phase=0, surf_mode=2,
                                 FastScape=FastScape(sed_phases=2, max_fs_dt=1e-3, fs_refine=2,
                                                     topo_boundary="1111", vel_boundary="0000")),
                     Output(out_dir="fastscape_example"))

julia> add_box!(model; xlim=(-50, 50), ylim=(-10, 10), zlim=(0, 10),  phase=ConstantPhase(0), T=nothing)   # air
julia> add_box!(model; xlim=(-50, 50), ylim=(-10, 10), zlim=(-50, 0), phase=ConstantPhase(1), T=nothing)   # crust
julia> add_box!(model; xlim=(-10, 10), ylim=(-10, 10), zlim=(-50, 2), phase=ConstantPhase(1), T=nothing)   # a plateau

julia> add_phase!(model, Phase(ID=0, Name="Air",      eta=1e19, rho=50),
                         Phase(ID=1, Name="crust",    eta=1e21, rho=2700),
                         Phase(ID=2, Name="sediment", eta=1e20, rho=2500))

julia> run_lamem(model, 1, logfile="fastscape")
```

The log file then contains the FastScape messages (`Begin FastScape`, ...), and the FastScape surface is written next to the other output as `*_fs.pvd`.

Some points to keep in mind:

- `sed_phases` is the phase ID given to newly deposited sediment. It has to exist in the model.
- If a LaMEM step is longer than `max_fs_dt`, it is split into several FastScape substeps.
- `topo_boundary` and `vel_boundary` have one digit per boundary, in the order bottom (y-min), right (x-max), top (y-max), left (x-min). For `topo_boundary`, `1` means fixed height (sediment can leave the model) and `0` a reflective boundary. For `vel_boundary`, `1` means zero velocity, and `0` that the velocity transferred from LaMEM is kept.
- The marine parameters (`sealevel`, `poroSilt`, ...) are only written if `set_marine=1`.
- For a 2D LaMEM model, use `fs2D=1`: the 1D surface is then extended in the second horizontal direction over `extendedRange`, with `extendedNodes` points.

All parameters, with their defaults, are listed in the docstring of [`FastScape`](@ref).

## Using an existing input file

A parameter file that already has a `<FastScapeStart>` block can be run as it is, as with any other LaMEM input file:

```julia
julia> run_lamem("Collision_FastScape.dat", 4)
```

## Input files from the manuscript

Input files of simulations in which LaMEM was coupled to FastScape are available on [Zenodo](https://zenodo.org/records/21761705). Several keys were renamed in the version of LaMEM that is distributed with `LaMEM_jll`, so these files need a few edits before they run:

| Key in the manuscript files | Key in LaMEM ≥ 3.3.0 (and `FastScape(...)`) |
|:----------------------------|:--------------------------------------------|
| `Max_dt`                    | `max_fs_dt`                                 |
| `setMarine`                 | `set_marine`                                |
| `Lsolve`                    | `depth_siltsand_solve`                      |

Be aware that the manuscript coupled LaMEM (3.0.1) and a modified FastScape separately, whereas `LaMEM_jll` has FastScape built in. Running the renamed input files is therefore not guaranteed to reproduce the published results, and we have not compared them.
