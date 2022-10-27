using Test
using LaMEM

include("runLaMEM.jl")
#include("read_timestep.jl")

if !Sys.iswindows()
    # clean up
    clean_directory("./")
end
