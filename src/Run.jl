module Run
# module to run LaMEM_jll
using LaMEM_jll,Glob, MPI

export run_lamem, run_lamem_save_grid
export remove_popup_messages_mac, show_paths_LaMEM

include("run_lamem.jl")
include("run_lamem_save_grid.jl")
include("utils_Run.jl")

#setup MPI
if isdefined(LaMEM_jll,:MPICH_jll)
    const mpiexec = LaMEM_jll.MPICH_jll.mpiexec()
    const MPI_LIBPATH = LaMEM_jll.MPICH_jll.LIBPATH
elseif isdefined(LaMEM_jll,:MicrosoftMPI_jll) 
    const mpiexec = LaMEM_jll.MicrosoftMPI_jll.mpiexec()
    const MPI_LIBPATH = LaMEM_jll.MicrosoftMPI_jll.LIBPATH
elseif isdefined(LaMEM_jll,:OpenMPI_jll) 
    const mpiexec = LaMEM_jll.OpenMPI_jll.mpiexec()
    const MPI_LIBPATH = LaMEM_jll.OpenMPI_jll.LIBPATH
elseif isdefined(LaMEM_jll,:MPItrampoline_jll) 
    const mpiexec = LaMEM_jll.MPItrampoline_jll.mpiexec()
    const MPI_LIBPATH = LaMEM_jll.MPItrampoline_jll.LIBPATH
else
    println("Be careful! No MPI library detected; parallel runs won't work")
    const mpiexec = nothing
    const MPI_LIBPATH = Ref{String}("")
end


end