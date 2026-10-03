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
