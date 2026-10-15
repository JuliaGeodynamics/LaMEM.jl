# This tests the example scripts 
using Test

const testing = true
@testset "examples in /scripts" begin
    curdir = pwd()
    pkg_dir = pkgdir(LaMEM)
    cd(pkg_dir)
    #cd(joinpath(pkg_dir,"test"))
    
    # 3D subduction example (8 cores; Windows LaMEM_jll is MPI-enabled since 3.1.0)
    @testset "Subduction3D" begin
        clean_directory()
        include("../example_scripts/Subduction3D.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.0924
        @test sum(data.fields.velocity[3][:,:,:]) ≈ -4.2464476f0 rtol=1e-4 # check Vz
    end

    # Strength envelop example
    @testset "StrengthEnvelop" begin
        clean_directory()
        include("../example_scripts/StrengthEnvelop.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.09834706
        @test sum(data.fields.velocity[3][:,:,:]) ≈ 22.587292f0 rtol=1e-4 # check Vz
    end

    # Subduction example (8 cores)
    @testset "TM_Subduction_example" begin
        clean_directory()
        include("../example_scripts/TM_Subduction_example.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.0021
        @test sum(data.fields.velocity[3][:,:,:]) ≈ 596.7986f0 rtol=1e-4 # check Vz
    end

    # PassiveTracers example
    @testset "PassiveTracers" begin
        clean_directory()
        include("../example_scripts/PassiveTracers.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 1.078999
        @test sum(data.fields.velocity[3][:,:,:]) ≈ 0.16775283f0 rtol=1e-4 # check Vz
    end

    cd(curdir)

end