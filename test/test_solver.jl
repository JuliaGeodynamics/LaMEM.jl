using Test, LaMEM

@testset "Solver options (LaMEM >= 3.0)" begin
    # defaults are LaMEM's own; only stokes_solver/direct_solver_type/penalty are always written
    s = Solver()
    @test s.stokes_solver == "coupled_direct"
    @test s.direct_solver_type == "mumps"
    @test s.penalty == 1e3
    @test s.num_mg_levels == -1

    io = IOBuffer(); LaMEM.write_LaMEM_inputFile(io, s); txt = String(take!(io))
    @test occursin("<SolverOptionsStart>", txt) && occursin("<SolverOptionsEnd>", txt)
    @test occursin(r"stokes_solver\s+= coupled_direct", txt)
    @test !occursin("num_mg_levels", txt)
    @test !occursin("SolverType", txt)

    # iteration counts in tolerance vectors are written as integers, atol=-1 as is
    s = Solver(stokes_solver="coupled_mg", num_mg_levels=3, linear_tolerances=[1e-4, -1, 25], monitor_solvers=1)
    io = IOBuffer(); LaMEM.write_LaMEM_inputFile(io, s); txt = String(take!(io))
    @test occursin(r"linear_tolerances\s+= 0\.0001 -1 25", txt)
    @test occursin(r"num_mg_levels\s+= 3", txt)
    @test !occursin("penalty", txt)

    # unknown options are an error
    @test_throws ErrorException Solver(MGLevelz=3)

    # LaMEM 2.x keywords are translated (and warned about)
    s = @test_logs (:warn, r"LaMEM 2.x") match_mode=:any Solver(SolverType="multigrid", MGLevels=4, MGCoarseSolver="mumps", MGSmoother="jacobi", MGJacobiDamp=0.6, MGSweeps=5)
    @test s.stokes_solver == "coupled_mg"
    @test s.num_mg_levels == 4
    @test s.coarse_solver == "direct" && s.direct_solver_type == "mumps"
    @test s.smoother_type == "light" && s.smoother_damping == 0.6 && s.smoother_num_sweeps == 5

    s = Solver(SolverType="direct", DirectSolver="superlu_dist", DirectPenalty=1e5)
    @test s.stokes_solver == "block_direct" && s.direct_solver_type == "superlu_dist" && s.penalty == 1e5

    s = Solver(SolverType="direct", DirectSolver="umfpack")
    @test s.direct_solver_type == "default"

    s = Solver(SolverType="multigrid", MGCoarseSolver="redundant")
    @test s.coarse_solver == "direct" && s.coarse_num_cpu == 1

    # a 2D grid shortcut gives two cells in y (LaMEM >= 3.0 needs at least two)
    g = Grid(nel=(16,16), x=[-2,2], z=[-1,1])
    @test sum(g.nel_y) == 2
end
