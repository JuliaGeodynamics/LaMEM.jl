using Test
using LaMEM

@testset "run lamem mode save grid test" begin


    ParamFile="input_files/FallingBlock_Multigrid.dat"
	
	out = run_lamem_save_grid(ParamFile, 1)       # 1 core
	@test isnothing(out)
	
	out = run_lamem_save_grid(ParamFile, 8)       # 8 cores
	@test out == "ProcessorPartitioning_8cpu_2.2.2.bin"


end
