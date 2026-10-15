# User-defined phase transitions (Julia plugins)

LaMEM has built-in phase transitions (`Constant`, `Clapeyron`, `Box`, ..., see [`PhaseTransition`](@ref) and [`add_phasetransition!`](@ref)). When you need a rule they cannot express — one that depends on several marker quantities at once, a lookup table, a time-dependent threshold — you can write the rule in Julia instead. It is compiled once, with [JuliaC](https://github.com/JuliaLang/JuliaC.jl), into a shared library (a *plugin*) that LaMEM loads at startup and calls every time step for all markers, after the built-in phase transitions. At run time no Julia session is involved: the plugin is native code.

The full description of the feature — every marker and cell field a rule can read, which fields it may change, the units, constraints on the code and troubleshooting — is in the LaMEM manual, on the page [Julia phase-transition plugins](https://unimainzgeo.github.io/LaMEM/dev/man/JuliaPlugins/) (`doc/src/man/JuliaPlugins.md` in the LaMEM repository). This page shows how to use plugins from LaMEM.jl.

## Writing a rule

A rule is a single Julia file. It `include`s the helper module `LaMEMPlugin.jl`, defines a function that receives one marker (a `MarkerView`, with all values in the units of the model) and returns it either unchanged or with some fields replaced by `update(m; phase=..., T=..., ...)`, and ends with a few lines of boilerplate that are the same in every plugin. The plugin is named after the file, without the extension and a leading `ptlib_`.

This rule (`example_scripts/ptlib_melting.jl`) turns crust (phase 1) that is hotter than 800 °C into molten crust (phase 2):

```julia
# A user-defined phase transition for LaMEM, written in Julia.
# Crust (phase 1) that is heated above 800 °C turns into partially molten crust (phase 2).
# The change is irreversible: molten crust that cools down again keeps phase 2.
#
# This file is compiled into a shared library with `build_phase_transition_plugin`
# (see PhaseTransitionPlugin.jl in this directory), which LaMEM then calls every time step.
module PTLibMelting                                 # any module name will do

include(joinpath(@__DIR__, "LaMEMPlugin.jl"))       # helper module; build_phase_transition_plugin puts it here
using .LaMEMPlugin                                  # MarkerView, update, lamem_pt_wrapper, ...

const PHASE_CRUST  = Cint(1)                        # phase ID of the solid crust (as in the model)
const PHASE_MOLTEN = Cint(2)                        # phase ID of the partially molten crust
const T_MELT       = 800.0                          # melting temperature, in °C (the units of the model)

# The rule: called for every marker, every time step. It returns the marker `m` unchanged,
# or a copy in which some fields are replaced with `update(m; field = value)`.
function melting_rule(m::MarkerView)
    if m.phase == PHASE_CRUST && m.T > T_MELT       # solid crust that is hotter than the melting temperature ...
        return update(m; phase = PHASE_MOLTEN)      # ... becomes molten crust (T and all other fields unchanged)
    end
    return m                                        # every other marker is left alone
end

# Boilerplate, the same in every plugin (only the name of the rule changes): the function LaMEM calls
Base.@ccallable function lamem_phase_transition(markers::Ptr{LaMEMPluginMarkers}, cells::Ptr{LaMEMPluginCells},
        step::Ptr{LaMEMPluginStep}, scaling::Ptr{LaMEMPluginScaling})::Int32
    return lamem_pt_wrapper(melting_rule, markers, cells, step, scaling)
end

end # module
```

`LaMEMPlugin.jl` is shipped with LaMEM.jl ([`LaMEMPlugin_path`](@ref) gives its location) and matches the plugin interface of the LaMEM version that LaMEM.jl runs. The rule is compiled in a separate Julia process in which LaMEM.jl is not loaded, so it includes the helper by path, from its own directory; [`build_phase_transition_plugin`](@ref) copies it there if it is not there yet.

Because the plugin is compiled with `--trim=safe`, the rule cannot print or do other I/O and should be type-stable (use `const` for parameters, as above).

## Building the plugin

```julia
julia> library = build_phase_transition_plugin("ptlib_melting.jl")
```
compiles the rule and returns the absolute path of the library, which is part of the bundle directory `build_melting` next to the rule file (the keyword `output_dir` changes where it goes): `build_melting/lib/libptlib_melting.so` on Linux, `.../lib/libptlib_melting.dylib` on macOS and `.../bin/libptlib_melting.dll` on Windows. The library needs the other files of the bundle, so keep the `build_<name>` directory together. JuliaC is installed into a temporary environment (once per Julia session); use the keyword `julia_env` to give your own environment, for example `julia_env="@juliac"`.

## Using the plugin in a model

The plugin is a phase transition of `Type="dylib"`, with the path of the library:

```julia
julia> add_phasetransition!(model, PhaseTransition(Type="dylib", library=library))
```

Unlike the built-in phase transitions, this is not written as a `<PhaseTransitionStart>` block, but as two lines in the LaMEM input file (`dylib_plugin` loads the library, `phase_transitions = dylib` calls the rule every time step):

```
   # User-defined phase transition (Julia plugin)
    dylib_plugin       =  /path/to/build_melting/lib/libptlib_melting.so     # [only for Type=dylib] path of the compiled phase transition plugin ...
    phase_transitions  =  dylib     # call the rule of the plugin every time step, after the built-in phase transitions
```

- A model can use one plugin, together with any number of built-in phase transitions. All other fields of a `Type="dylib"` entry, including `ID`, are ignored; the built-in phase transitions keep their own IDs `0, 1, ...`.
- The plugin does not need `SolutionParams.Phasetrans`, which only switches the built-in phase transitions on.
- A relative `library` path is relative to the directory in which LaMEM runs, which is `model.Output.out_dir`; the path returned by `build_phase_transition_plugin` is absolute. LaMEM cannot read paths that contain spaces or `#`.

In the output of LaMEM, a `Dylib plugin parameters` block confirms that the plugin was loaded, and every time step reports how many markers it changed:

```
Dylib plugin  : 496 marker(s) changed phase, 0 marker(s) changed temperature, 0 marker(s) changed other fields
```

## Example

The complete example is in `example_scripts/PhaseTransitionPlugin.jl` (it uses the rule above, from the same directory, and runs in a few seconds once the plugin is built):

```julia
# User-defined phase transitions (Julia plugin): a hot intrusion melts the crust around it.
#
# The phase transition rule is in ptlib_melting.jl, next to this file. It is compiled into a
# shared library, which LaMEM loads and calls every time step. Needs julia >= 1.12; building the
# plugin can take a few minutes.

using LaMEM, GeophysicalModelGenerator

# 1) compile the rule into a plugin; returns the path of the library
library = build_phase_transition_plugin(joinpath(@__DIR__, "ptlib_melting.jl"))

# 2) a small 2D model (16 x 16 cells)
model = Model(Grid(nel=(16,16), x=[-50,50], z=[-50,0]),
              Time(nstep_max=3, dt=0.001, dt_max=0.001),
              Output(out_dir="PhaseTransitionPlugin_example", write_VTK_setup=false))

add_phase!(model, Phase(ID=0, Name="mantle",       eta=1e22, rho=3300),
                  Phase(ID=1, Name="crust",        eta=1e21, rho=2800),
                  Phase(ID=2, Name="molten crust", eta=1e19, rho=2600))

model.Grid.Temp .= 400.0                                                    # background temperature [°C]
add_box!(model, xlim=(-50,50), zlim=(-30,0), phase=ConstantPhase(1))        # 30 km thick crust
add_sphere!(model, cen=(0,0,-20), radius=8, phase=ConstantPhase(1), T=ConstantTemp(1000))   # hot intrusion in the crust

# the plugin is added like any other phase transition
add_phasetransition!(model, PhaseTransition(Type="dylib", library=library))

# 3) run LaMEM; the rule turns the crust inside the intrusion (T > 800 °C) into molten crust
run_lamem(model, 1)

# 4) read the result back: the initial setup has no molten crust, the last timestep does
data, t = read_LaMEM_timestep(model, last=true)
n_molten_initial = count(model.Grid.Phases .== 2)
n_molten_final   = count(data.fields.phase .> 1.5)                          # cells that are (mostly) molten crust
println("cells with molten crust: $n_molten_initial initially, $n_molten_final at t = $t Myr")
```

## Limitations

- Building a plugin needs Julia 1.12 or later.
- The plugin embeds its own Julia runtime, so it only works when LaMEM runs as its own process, as with [`run_lamem`](@ref) (on any number of cores), not in a LaMEM that is loaded as a library into a running Julia session. Only one plugin can be loaded per LaMEM run.
- The plugin must have been built with the `LaMEMPlugin.jl` of the LaMEM version that runs it; otherwise LaMEM stops with an ABI or struct-layout mismatch. Rebuild plugins after updating LaMEM.jl.
