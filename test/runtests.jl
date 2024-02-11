using Test
using LaMEM

include("test_julia_setups.jl")
include("runLaMEM.jl")
include("read_timestep.jl")
include("run_lamem_save_grid_test.jl")
include("mesh_refinement_test.jl")
include("read_logfile.jl")

if !Sys.iswindows()
    # clean up
    clean_directory("./")
end
