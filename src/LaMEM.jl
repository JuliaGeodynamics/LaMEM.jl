module LaMEM
using LaMEM_jll
using PythonCall
using Glob

ENV["JULIA_CONDAPKG_BACKEND"] = "MicroMamba"

# load the correct MPI
const mpiexec = if isdefined(LaMEM_jll,:MPICH_jll)
    LaMEM_jll.MPICH_jll.mpiexec()
elseif isdefined(LaMEM_jll,:MicrosoftMPI_jll) 
    LaMEM_jll.MicrosoftMPI_jll.mpiexec()
else
    nothing
end

# Reading files back into julia
const pyvtk = PythonCall.pynew()

function __init__()

    println("Adding PythonCall dependencies to read LaMEM timesteps")
    pth = (@__DIR__)*"/python"        # Path where the python routines are
    pyimport("sys").path.append(pth)  # append path
  
    # link vtk. Note that all python dependencies are listed in PythonCallDeps.toml
    PythonCall.pycopy!(pyvtk, pyimport("vtk"))            # used to read VTK files
end


include("run_lamem.jl")
include("run_lamem_save_grid.jl")
include("read_timestep.jl")
include("utils.jl")

export run_lamem
export run_lamem_save_grid
export pyvtk

end # module
