# This tests the example scripts 
using Test

const testing = true
@testset "examples in /scripts" begin


    # Subduction example
    @testset "TM_Subduction_example" begin
        clean_directory()
        include("../scripts/TM_Subduction_example.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.0021
        @test sum(data.fields.velocity[3][:,:,:]) ≈ 420.10352f0 rtol=1e-4 # check Vz
    end

    # 3D subduction example
    @testset "Subduction3D" begin
        clean_directory()
        include("../scripts/Subduction3D.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.05504613
        @test sum(data.fields.velocity[3][:,:,:]) ≈ -51.314083f0 rtol=1e-4 # check Vz
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