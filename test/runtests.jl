using Test
using LaMEM

# first test - run a code
ParamFile="FallingBlock_Multigrid.dat";
run_lamem(ParamFile, 4,"-time_end 1")

