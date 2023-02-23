using Test
using LaMEM
using PythonCall

@testset "LaMEM" begin
    include("runLaMEM.jl")
    include("read_timestep.jl")
end


if !Sys.iswindows()
    # clean up
    clean_directory("./")
end
