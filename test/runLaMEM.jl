using Test
using LaMEM

@testset "run LaMEM" begin
    
    @testset "FallingBlock_Multigrid" begin
        # first test - run a simulation
        ParamFile="input_files/FallingBlock_Multigrid.dat";
        out = run_lamem(ParamFile, 1,"-nstep_max 1")       # 1 core
        @test isnothing(out)
        out = run_lamem(ParamFile, 4,"-nstep_max 1")       # 4 cores
        @test isnothing(out)
    end

    # Create a setup using GMG
    @testset "Subduction_Parallel_GMG" begin
        include("CreateMarkers_Subduction_Linear_FreeSlip_parallel.jl")
        out = run_lamem(ParamFile_2, 1, "-nstep_max 2")    # 1 core
        @test isnothing(out)
    end

    # Try direct solvers 
    @testset "FallingBlock_DirectSolver" begin
        ParamFile="input_files/FallingBlock_DirectSolver.dat";
        out = run_lamem(ParamFile, 1, "-nstep_max 2")    # 1 core
        @test isnothing(out)
    end

    if !Sys.iswindows()
        @testset "FallingBlock_ParallelDirectSolver" begin
            out = run_lamem(ParamFile, 2, "-nstep_max 2")    # 2 cores (mumps)
            @test isnothing(out)
        end
    end
    
    if !Sys.isapple()
        @testset "FallingBlock_Parallel_SuperLU_dist" begin
            # Note: superlu_dist uses a combination of openMP parallelization on a node and MPI between nodes.
            # If you have a server with a lot of cores AND run this with >1 core, this may clash
            # In that case it is better to run it with 1 MPI task but set the environmental variables below accordingly
            # You'll need to do some benchmarking to find the sweet spot
            ENV["OMP_NUM_THREADS"] = "1"
            ENV["GOTO_NUM_THREADS"] = "1"
            ENV["OPENBLAS_NUM_THREADS"] = "1"
            out = run_lamem(ParamFile, 1, "-nstep_max 1 -jp_pc_factor_mat_solver_type superlu_dist")    
            @test isnothing(out)       
        end 
    end

    # run test with passive tracers
    @testset "PassiveTracers" begin
        out = run_lamem("input_files/Passive_tracer_ex2D.dat", 1, "-nstep_max 10")    # 1 core
        @test isnothing(out)
    end

end
