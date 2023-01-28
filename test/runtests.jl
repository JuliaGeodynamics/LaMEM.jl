using Test
using LaMEM
using PythonCall

include("runLaMEM.jl")
include("read_timestep.jl")
include("run_lamem_save_grid_test.jl")

if !Sys.iswindows()
    # clean up
    clean_directory("./")
end
