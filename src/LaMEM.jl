module LaMEM

using LaMEM_jll

# load the correct mpi
const mpiexec = if isdefined(LaMEM_jll,:MPICH_jll)
    LaMEM_jll.MPICH_jll.mpiexec()
elseif isdefined(LaMEM_jll,:MicrosoftMPI_jll) 
    LaMEM_jll.MicrosoftMPI_jll.mpiexec()
else
    nothing
end


include("run_lamem.jl")

export run_lamem


end # module
