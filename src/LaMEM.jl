module LaMEM

using GeoParams
using .GeoParams
using Requires
export NO_units, GEO_units, SI_units, km, m, Pa, Pas, kg, cm, yr
#export GeoParams

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


# ==
using DocStringExtensions

"""
    help_info::String = get_doc(structure, field::Symbol) 
This returns a string with the documentation for a parameter `field` that is within the `structure`. 
Note that this structure must be a help structure of the current one.
"""
function get_doc(structure, field::Symbol) 
    alldocs       =   Docs.meta(LaMEM.LaMEM_Model);
    #alldocs       =   Docs.meta();
    
    var           =   eval(Meta.parse("Docs.@var($structure)"))
    @show var
    #=
    fields_local  =   alldocs[var].docs[Union{}].data[:fields]
    str = fields_local[field]

    # Add comment to next line (if required)
    str = replace(str, "\n" => "\n #")

    # remove the # at the end of the string
    if str[end]=='#'
        str = str[1:end-1]
    end
=#
    str="#"
    return str
end
# ==

# Functions that help running LaMEM directly from julia
include("LaMEM_ModelGeneration/LaMEM_Model.jl")
using .LaMEM_Model
export  LaMEM_Model, Model, Write_LaMEM_InputFile, create_initialsetup,
        Scaling, Grid, Time, FreeSurface, BoundaryConditions, SolutionParams,
        Solver, ModelSetup, 
        geom_Sphere,
        Output,
        Materials, Phase, Softening, PhaseTransition, Dike, 
        add_phase!, rm_phase!, rm_last_phase!, replace_phase!, add_petsc!, add_softening!,
        add_phasetransition!, add_dike!, add_geom!     


using .Run.LaMEM_jll
export LaMEM_jll        # export LaMEM_jll as well & directories


function __init__()
    #@require GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a" begin 
    @require Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin

        @eval include("MakieExt.jl")
    end
end


end # module
