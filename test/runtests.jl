using Test
using LaMEM
using Requires
using PythonCall

include("runLaMEM.jl")
@require PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d" begin  
    include("read_timestep.jl")
end

if !Sys.iswindows()
    # clean up
    clean_directory("./")
end
