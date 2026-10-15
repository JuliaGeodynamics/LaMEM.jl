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
