module Run
# module to run LaMEM_jll
using LaMEM_jll,Glob, MPI

export run_lamem, run_lamem_save_grid
export remove_popup_messages_mac, show_paths_LaMEM

include("run_lamem.jl")
include("run_lamem_save_grid.jl")
include("utils_Run.jl")

const mpiexec = MPI.mpiexec()


end