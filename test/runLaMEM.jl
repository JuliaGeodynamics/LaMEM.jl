using Test, Base.Sys

pkg_dir = pkgdir(LaMEM)
@testset "run LaMEM" begin
 
    # first test - run a simulation
    ParamFile=joinpath(pkg_dir,"test","input_files/FallingBlock_Multigrid.dat");
    try
        out = run_lamem(ParamFile, 1,"-nstep_max 1")       # 1 core
        @test isnothing(out)
    catch 
        println("Falling Block test on 1 core failed")
    end
    
    try
        out = run_lamem(ParamFile, 4,"-nstep_max 2")       # 4 cores
        @test isnothing(out)
    catch 
        println("Falling Block test on 4 cores failed")
    end

    # Create a setup using GMG
    #include("CreateMarkers_Subduction_Linear_FreeSlip_parallel.jl")
    #out = run_lamem(ParamFile_2, 1, "-nstep_max 1")    # 1 core
    #@test isnothing(out)

    # Try direct solvers 
    ParamFile = "input_files/FallingBlock_DirectSolver.dat";
    ParamFile = joinpath(pkg_dir,"test", ParamFile);
    out = run_lamem(ParamFile, 1, "-nstep_max 2")    # 1 core
    @test isnothing(out)

    out = run_lamem(ParamFile, 2, "-nstep_max 5")    # 2 cores (mumps)
    @test isnothing(out)

    # Try free surface 
    ParamFile = "input_files/Subduction2D_FreeSurface_DirectSolver.dat";
    ParamFile = joinpath(pkg_dir,"test", ParamFile);
    out = run_lamem(ParamFile, 1, "-nstep_max 5")    # 4 core
    @test isnothing(out)
    
    if !Sys.isapple() && 1==0
        # Note: superlu_dist uses a combination of openMP parallelization on a node and MPI between nodes.
        # If you have a server with a lot of cores AND run this with >1 core, this may clash
        # In that case it is better to run it with 1 MPI task but set the environmental variables below accordingly
        # You'll need to do some benchmarking to find the sweet spot
        ENV["OMP_NUM_THREADS"] = "1"
        ENV["GOTO_NUM_THREADS"] = "1"
        ENV["OPENBLAS_NUM_THREADS"] = "1"
        out = run_lamem(ParamFile, 2, "-nstep_max 1 -jp_pc_factor_mat_solver_type superlu_dist")    
        @test isnothing(out)        
    end

    # optional logfile: output should be shown in the REPL *and* saved to file
    ParamFile = "input_files/FallingBlock_DirectSolver.dat";
    ParamFile = joinpath(pkg_dir,"test", ParamFile);
    logfile   = joinpath(tempdir(), "LaMEM_logfile_test")
    rm(logfile*".log", force=true)
    out = run_lamem(ParamFile, 1, "-nstep_max 1", logfile=logfile)   # "test" -> "test.log"
    @test isnothing(out)
    @test isfile(logfile*".log")
    lines = readlines(logfile*".log")
    @test any(contains.(lines, "SOLUTION IS DONE"))                  # the full output ended up in the file
    rm(logfile*".log", force=true)

    # an explicit extension is kept as-is
    out = run_lamem(ParamFile, 1, "-nstep_max 1", logfile=logfile*".out")
    @test isnothing(out)
    @test isfile(logfile*".out")
    rm(logfile*".out", force=true)

    # a normal rerun replaces the logfile, a restart adds to it
    run_lamem(ParamFile, 1, "-nstep_max 1", logfile=logfile)
    n_first = length(readlines(logfile*".log"))
    run_lamem(ParamFile, 1, "-nstep_max 1", logfile=logfile)
    @test length(readlines(logfile*".log")) == n_first             # replaced, not appended

    run_lamem(ParamFile, 1, "-nstep_max 1", logfile=logfile, append=true)
    lines = readlines(logfile*".log")
    @test length(lines) > n_first                                  # appended
    @test count(l -> occursin("SOLUTION IS DONE", l), lines) == 2  # both runs are in there
    rm(logfile*".log", force=true)

    # the restart flag switches to appending by itself
    @test LaMEM.Run.is_restart("-mode restart")
    @test LaMEM.Run.is_restart("-nstep_max 5 -mode restart")
    @test !LaMEM.Run.is_restart("-nstep_max 5")
    @test !LaMEM.Run.is_restart("-mode save_grid")

    # run test with passive tracers
    ParamFile = "input_files/Passive_tracer_ex2D.dat";
    ParamFile = joinpath(pkg_dir,"test", ParamFile);
    out = run_lamem(ParamFile, 1, "-nstep_max 10")    # 1 core
    @test isnothing(out)

end
