# This tests the example scripts 
using Test

const testing = true
@testset "examples in /scripts" begin
    curdir = pwd()
    pkg_dir = pkgdir(LaMEM)
    cd(pkg_dir)
    #cd(joinpath(pkg_dir,"test"))
    
    # 3D subduction example
    if !Sys.iswindows()
        @testset "Subduction3D" begin
            clean_directory()
            include("../example_scripts/Subduction3D.jl")
            data,time = read_LaMEM_timestep(model,last=true);
            @test time ≈ 0.05504613
            @test sum(data.fields.velocity[3][:,:,:]) ≈ -51.314083f0 rtol=1e-4 # check Vz
        end
    end

    # Strength envelop example
    @testset "StrengthEnvelop" begin
        clean_directory()
        include("../example_scripts/StrengthEnvelop.jl")
        data,time = read_LaMEM_timestep(model,last=true);
        @test time ≈ 0.09834706
        @test sum(data.fields.velocity[3][:,:,:]) ≈ 14.305277f0 rtol=1e-4 # check Vz
    end

    # Subduction example
    if !Sys.iswindows()
        @testset "TM_Subduction_example" begin
            clean_directory()
            include("../example_scripts/TM_Subduction_example.jl")
            data,time = read_LaMEM_timestep(model,last=true);
            @test time ≈ 0.0021
            @test sum(data.fields.velocity[3][:,:,:]) ≈ 420.10352f0 rtol=1e-4 # check Vz
        end
    
    end

    # PassiveTracers example
    if !Sys.iswindows()
        @testset "PassiveTracers" begin
            clean_directory()
            include("../example_scripts/PassiveTracers.jl")
            data,time = read_LaMEM_timestep(model,last=true);
            @test time ≈ 1.078999
            @test sum(data.fields.velocity[3][:,:,:]) ≈ 0.1642956f0 rtol=1e-4 # check Vz
        end
    
    end

    cd(curdir)

end