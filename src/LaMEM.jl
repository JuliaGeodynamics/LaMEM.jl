module LaMEM

# Functions to read LaMEM output
include("IO.jl")
using .IO
export Read_LaMEM_PVTR_File, Read_LaMEM_PVTS_File, field_names, readPVD, Read_LaMEM_PVTU_File
export Read_LaMEM_simulation, Read_LaMEM_timestep

# Functions 
include("Run.jl")
using .Run
export run_lamem, run_lamem_save_grid, mpiexec
export remove_popup_messages_mac, show_paths_LaMEM



#=
using LaMEM_jll

# load the correct MPI
const mpiexec = if isdefined(LaMEM_jll,:MPICH_jll)
    LaMEM_jll.MPICH_jll.mpiexec()
elseif isdefined(LaMEM_jll,:MicrosoftMPI_jll) 
    LaMEM_jll.MicrosoftMPI_jll.mpiexec()
else
    nothing
end



=#


#include("read_timestep.jl")
#include("utils.jl")


end # module
