module Run
# module to run LaMEM_jll
using LaMEM_jll,Glob

export run_lamem, run_lamem_save_grid, mpiexec
export remove_popup_messages_mac, show_paths_LaMEM

include("run_lamem.jl")
include("run_lamem_save_grid.jl")
include("utils_Run.jl")

# load the correct MPI
const mpiexec = if isdefined(LaMEM_jll,:MPICH_jll)
    LaMEM_jll.MPICH_jll.mpiexec()
elseif isdefined(LaMEM_jll,:MicrosoftMPI_jll) 
    LaMEM_jll.MicrosoftMPI_jll.mpiexec()
else
    nothing
end


end