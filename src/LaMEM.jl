module LaMEM

using GeoParams
using .GeoParams
export NO_units, GEO_units, SI_units

# Functions to read LaMEM output
include("IO_functions.jl")
using .IO_functions
export Read_LaMEM_PVTR_File, Read_LaMEM_PVTS_File, Read_LaMEM_PVTU_File
export Read_LaMEM_simulation, Read_LaMEM_timestep, Read_LaMEM_fieldnames
export clean_directory, changefolder

# Functions 
include("Run.jl")
using .Run
export run_lamem, run_lamem_save_grid, mpiexec
export remove_popup_messages_mac, show_paths_LaMEM

include("LaMEM_ModelGeneration/LaMEM_ModelGeneration.jl")
using .LaMEM_Model
export  Model, Write_LaMEM_InputFile, 
        Scaling, Grid, Time, FreeSurface, BoundaryConditions, SolutionParams,
        Solver, ModelSetup, 
        geom_Sphere


using .Run.LaMEM_jll
export LaMEM_jll        # export LaMEM_jll as well & directories



end # module
