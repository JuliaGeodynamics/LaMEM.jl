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
        out = run_lamem(ParamFile, 2, "-nstep_max 2 -jp_pc_factor_mat_solver_type superlu_dist")    # 2 cores (superlu_dist)
        @test isnothing(out)
    end



end

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

    

end



# clean up
clean_directory("./")