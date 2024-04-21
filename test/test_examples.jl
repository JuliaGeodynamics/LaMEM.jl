# This tests the example scripts 
using Test

@testset "examples in /scripts" begin

    testing = true

    # Subduction example
    @testset "TM_Subduction_example" begin
        include("../scripts/TM_Subduction_example.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.004419778
        @test sum(data.fields.velocity[3][:,:,:]) ≈ 708.41907f0 rtol=1e-4 # check Vz
    end

    # FB example
    @testset "FB_restart" begin
        clean_directory()
        include("../scripts/FB_restart.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 63.0025
        @test sum(data.fields.velocity[3][:,:,:]) ≈ 0.07041338f0 rtol=1e-4 # check Vz
    end

    # 3D subduction example
    @testset "Subduction3D" begin
        clean_directory()
        include("../scripts/Subduction3D.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.03517227
        @test sum(data.fields.velocity[3][:,:,:]) ≈ -33.77553f0 rtol=1e-4 # check Vz
    end

    # Strength envelop example
    @testset "StrengthEnvelop" begin
        clean_directory()
        include("../scripts/StrengthEnvelop.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.09834706
        @test sum(data.fields.velocity[3][:,:,:]) ≈ 14.305277f0 rtol=1e-4 # check Vz
    end

end