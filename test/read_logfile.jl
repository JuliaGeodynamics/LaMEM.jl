# This tests running the full code from julia

using Test
using LaMEM
using GeophysicalModelGenerator

@testset "Read logfile" begin

    Filename = "input_files/128_cores_104812.txt"
    out = read_LaMEM_logfile(Filename);
    @test  isnothing(out)

end