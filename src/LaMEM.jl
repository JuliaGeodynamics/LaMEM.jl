module LaMEM
using LaMEM_jll
using Requires


# load the correct MPI
const mpiexec = if isdefined(LaMEM_jll,:MPICH_jll)
    LaMEM_jll.MPICH_jll.mpiexec()
elseif isdefined(LaMEM_jll,:MicrosoftMPI_jll) 
    LaMEM_jll.MicrosoftMPI_jll.mpiexec()
else
    nothing
end




function __init__()

  @require PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d" begin  
        const pyvtk = PythonCall.pynew()

        #using PythonCall        # in order to be able to use the python VTKtoolbox
        ENV["JULIA_CONDAPKG_BACKEND"] = "MicroMamba"

        pth = (@__DIR__)*"/python"        # Path where the python routines are
        pyimport("sys").path.append(pth)  # append path

        # link vtk. Note that all python dependencies are listed in PythonCallDeps.toml
        PythonCall.pycopy!(pyvtk, pyimport("vtk"))            # used to read VTK files

        include("read_timestep.jl")
        export pyvtk
  end
end


include("run_lamem.jl")

include("utils.jl")

export run_lamem


end # module
