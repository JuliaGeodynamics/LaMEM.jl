using Test
using LaMEM

@testset "run LaMEM" begin
    
    # first test - run a simulation
    ParamFile="input_files/FallingBlock_Multigrid.dat";
    out = run_lamem(ParamFile, 1,"-nstep_max 1")       # 1 core
    @test isnothing(out)
    out = run_lamem(ParamFile, 4,"-nstep_max 1")       # 4 cores
    @test isnothing(out)

    # Create a setup using GMG
    include("CreateMarkers_Subduction_Linear_FreeSlip_parallel.jl")
    out = run_lamem(ParamFile_2, 1, "-nstep_max 2")    # 1 core
    @test isnothing(out)

    # Try direct solvers 
    ParamFile="input_files/FallingBlock_DirectSolver.dat";
    out = run_lamem(ParamFile, 1, "-nstep_max 2")    # 1 core
    @test isnothing(out)

    if !Sys.iswindows()
        out = run_lamem(ParamFile, 2, "-nstep_max 2")    # 2 cores (mumps)
        @test isnothing(out)
    end
    
    if !Sys.isapple()
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

    # run test with passive tracers
    out = run_lamem("input_files/Passive_tracer_ex2D.dat", 1, "-nstep_max 10")    # 1 core
    @test isnothing(out)

end


#=
@testset "read LaMEM output" begin

    # Read a timestep
    FileName="FB_multigrid.pvtr"
    DirName = "Timestep_00000001_6.72970343e+00"

    data    = Read_VTR_File(DirName, FileName)
    @test  sum(data.fields.phase) ≈ 736.36414f0
    @test  sum(data.fields.strain_rate[1]) ≈ -0.019376338f0

    fields = field_names(DirName, FileName)

    # with cell-data 
    FileName="FB_multigrid_phase.pvtr"
    DirName = "Timestep_00000001_6.72970343e+00"
    data    = Read_VTR_File(DirName, FileName)
    @test sum(data.fields.phase) == 19822

    # read subduction setup
    data    = Read_VTR_File("Timestep_00000001_5.50000000e-02", "Subduction2D_FreeSlip_direct.pvtr")
    @test sum(data.fields.density) ≈ 1.60555f8

    # Read PVD file 
    FileNames, Time = readPVD("Subduction2D_FreeSlip_direct.pvd")
    @test Time[2] ≈ 0.055
    
    # Read passive tracers 
    data    = Read_VTU_File("Timestep_00000010_1.09635548e+00", "PlumeLithosphereInteraction_passive_tracers.pvtu")
    @test data.z[100] ≈ -298.5178f0
    @test data.fields.Temperature[100] ≈ 1350.0f0
    
end
=#


if !Sys.iswindows()
    # clean up
    clean_directory("./")
end
