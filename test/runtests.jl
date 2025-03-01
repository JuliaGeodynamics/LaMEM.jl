using Test
using LaMEM

@testset verbose = true "LaMEM.jl" begin

    include("test_julia_setups.jl")
    include("runLaMEM.jl")
    include("read_timestep.jl")
    include("run_lamem_save_grid_test.jl")
    include("mesh_refinement_test.jl")
    include("read_logfile.jl")
    include("test_compression.jl")
    include("test_GeoParams_integration.jl")
    include("test_examples.jl")
    include("test_erosion.jl")
    include("test_sedimentation.jl")
end

if !Sys.iswindows()
    # clean up
    clean_directory("./")
end
