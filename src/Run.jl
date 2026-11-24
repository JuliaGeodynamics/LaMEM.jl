module Run
# module to run LaMEM_jll
using LaMEM_jll, Glob, MPI, OpenBLAS32_jll, Dates

export run_lamem, run_lamem_save_grid
export remove_popup_messages_mac, show_paths_LaMEM
export mpi_available

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
elseif isdefined(LaMEM_jll,:MPIABI_jll)
    # MPIABI_jll has no bundled mpiexec; it expects MPIPreferences to point to a
    # system MPI, so defer to MPI.jl's own mpiexec wrapper instead.
    const mpiexec = MPI.mpiexec()
    const MPI_LIBPATH = LaMEM_jll.MPIABI_jll.LIBPATH
else
    println("Be careful! No MPI library detected; parallel runs won't work")
    const mpiexec = nothing
    const MPI_LIBPATH = Ref{String}("")
end

"""
    mpi_available()

Whether this `LaMEM_jll` can run in parallel, i.e. whether an `mpiexec` was found above.

Windows builds used to be serial, so `run_lamem` silently fell back to one core there. Since
LaMEM_jll 3.1.0 (PETSc_jll 3.25.4) the Windows binaries are built against Microsoft MPI and
run in parallel like every other platform, so the platform is no longer the question.
"""
mpi_available() = mpiexec !== nothing

# `--map-by :OVERSUBSCRIBE` lets OpenMPI (and Hydra, which accepts it) start more ranks than
# the machine has cores. Microsoft MPI rejects options it does not know and oversubscribes by
# default, so it is launched without them.
const oversubscribe_args =
    isdefined(LaMEM_jll, :MicrosoftMPI_jll) ? `` : `--map-by :OVERSUBSCRIBE`


end