module LaMEM

# Functions to read LaMEM output
include("IO.jl")
using .IO
export Read_LaMEM_PVTR_File, Read_LaMEM_PVTS_File, Read_LaMEM_PVTU_File
export Read_LaMEM_simulation, Read_LaMEM_timestep, Read_LaMEM_fieldnames
export clean_directory, changefolder

# Functions 
include("Run.jl")
using .Run
export run_lamem, run_lamem_save_grid, mpiexec
export remove_popup_messages_mac, show_paths_LaMEM

using .Run.LaMEM_jll
export LaMEM_jll        # export LaMEM_jll as well & directories

end # module
