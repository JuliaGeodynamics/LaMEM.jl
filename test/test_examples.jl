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

    # User-defined phase transition, written in julia and compiled into a plugin (needs julia >= 1.12)
    @testset "PhaseTransitionPlugin" begin
        if VERSION < v"1.12"
            @test_skip "building the plugin needs Julia >= 1.12 (juliac --trim)"
        else
            include("../example_scripts/PhaseTransitionPlugin.jl")
            @test isfile(library)
            @test only(model.Materials.PhaseTransitions).library == library
            @test n_molten_initial == 0             # no molten crust in the initial setup ...
            @test n_molten_final > 0                # ... but in the intrusion after running LaMEM
            @test n_molten_final < length(data.fields.phase) ÷ 4   # and only there

            rm(model.Output.out_dir, force=true, recursive=true)
            rm(joinpath(pkg_dir, "example_scripts", "build_melting"), force=true, recursive=true)
            rm(joinpath(pkg_dir, "example_scripts", "LaMEMPlugin.jl"), force=true)   # copied by build_phase_transition_plugin
        end
    end

    cd(curdir)

end