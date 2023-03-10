module LaMEM
using LaMEM_jll
using Glob

# load the correct MPI
const mpiexec = if isdefined(LaMEM_jll,:MPICH_jll)
    LaMEM_jll.MPICH_jll.mpiexec()
elseif isdefined(LaMEM_jll,:MicrosoftMPI_jll) 
    LaMEM_jll.MicrosoftMPI_jll.mpiexec()
else
    nothing
end

include("run_lamem.jl")
include("run_lamem_save_grid.jl")
include("read_timestep.jl")
include("utils.jl")

export run_lamem
export run_lamem_save_grid

end # module
