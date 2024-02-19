module LaMEM

using GeoParams
using .GeoParams
export NO_units, GEO_units, SI_units, km, m, Pa, Pas, kg, cm, yr
#export GeoParams

# Functions to read LaMEM output
include("IO_functions.jl")
using .IO_functions
export Read_LaMEM_PVTR_File, Read_LaMEM_PVTS_File, Read_LaMEM_PVTU_File
export Read_LaMEM_simulation, Read_LaMEM_timestep, Read_LaMEM_fieldnames
export PassiveTracer_Time
export clean_directory, changefolder, read_phase_diagram, read_LaMEM_logfile
export compress_vtr_file, compress_pvd

# Functions 
include("Run.jl")
using .Run
export run_lamem, run_lamem_save_grid, mpiexec
export remove_popup_messages_mac, show_paths_LaMEM

include("DocUtils.jl")

# Functions that help running LaMEM directly from julia
include("LaMEM_ModelGeneration/LaMEM_Model.jl")
using .LaMEM_Model
export  LaMEM_Model, Model, Write_LaMEM_InputFile, create_initialsetup,
        Scaling, Grid, Time, FreeSurface, BoundaryConditions, VelocityBox, SolutionParams,
        Solver, ModelSetup, 
        geom_Sphere, geom_Ellipsoid, geom_Box, geom_RidgeSeg, geom_Hex, geom_Layer, geom_Cylinder,
        Output,
        Multigrid, print_short, 
        Materials, Phase, Softening, PhaseTransition, PhaseAggregate, Dike, PassiveTracers,
        add_vbox!, rm_vbox!, rm_last_vbox!, 
        add_phase!, rm_phase!, rm_last_phase!, replace_phase!, add_petsc!, add_softening!, add_phaseaggregate!,
        add_phasetransition!, add_dike!, add_geom!, rm_geom!, set_air, copy_phase,
        add_topography!, AboveSurface!, BelowSurface!,
        prepare_lamem, isdefault, hasplasticity,
        add_geoparams_rheologies,
        stress_strainrate_0D    


using .Run.LaMEM_jll
export LaMEM_jll        # export LaMEM_jll as well & directories


# Functions that will only be defined once "Plots" is loaded
function plot_topo end 
function plot_cross_section end 
function plot_phasediagram end 
function plot_cross_section_simulation end
export plot_topo, plot_cross_section, plot_phasediagram, plot_cross_section_simulation


#=
function __init__()
    #@require GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a" begin 
    @require Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin
        @eval include("PlotsExt.jl")
    end
end
=#


end # module
