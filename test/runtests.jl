using Test
using LaMEM

@testset "run LaMEM" begin
    
    # first test - run a simulation
    ParamFile="input_files/FallingBlock_Multigrid.dat";
    run_lamem(ParamFile, 1,"-time_end 1")       # 1 core
    run_lamem(ParamFile, 4,"-time_end 1")       # 4 cores

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


end



# clean up
clean_directory("./")