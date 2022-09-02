using Test
using LaMEM

# first test - run a simulation
ParamFile="input_files/FallingBlock_Multigrid.dat";
run_lamem(ParamFile, 4,"-time_end 1")

# Read a timestep
FileName="FB_multigrid.pvtr"
DirName = "Timestep_00000001_6.72970343e+00"

data    = Read_VTR_File(DirName, FileName)

@test  sum(data.fields.phase) ≈ 736.36414f0
@test  sum(data.fields.strain_rate[1]) ≈ -0.019376338f0

fields = field_names(DirName, FileName)
@show names

# clean up
clean_directory("./")