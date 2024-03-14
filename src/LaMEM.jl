module LaMEM

using GeoParams
using .GeoParams
export NO_units, GEO_units, SI_units, km, m, Pa, Pas, kg, cm, yr
#export GeoParams

# Functions to read LaMEM output
include("IO_functions.jl")
using .IO_functions
export read_LaMEM_PVTR_file, read_LaMEM_PVTS_file, read_LaMEM_PVTU_file
export read_LaMEM_simulation, read_LaMEM_timestep, read_LaMEM_fieldnames
export passivetracer_time
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
export  LaMEM_Model, Model, write_LaMEM_inputFile, create_initialsetup,
        Scaling, Grid, Time, FreeSurface, BoundaryConditions, VelocityBox, BCBlock, VelCylinder, SolutionParams,
        Solver, ModelSetup, 
        GeomSphere, GeomEllipsoid, GeomBox, GeomRidgeSeg, GeomHex, GeomLayer, GeomCylinder ,
        Output,
        Multigrid, print_short, 
        Materials, Phase, Softening, PhaseTransition, PhaseAggregate, Dike, PassiveTracers,
        add_vbox!, rm_vbox!, rm_last_vbox!, 
        add_phase!, rm_phase!, rm_last_phase!, replace_phase!, add_petsc!, add_softening!, add_phaseaggregate!,
        add_phasetransition!, add_dike!, add_geom!, rm_geom!, set_air, copy_phase,
        add_topography!, above_surface!, below_surface!,
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
