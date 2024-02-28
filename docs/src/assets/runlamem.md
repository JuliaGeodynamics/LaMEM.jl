# Run LaMEM
Go to the package manager & install it with:
```julia
julia>]
pkg>add LaMEM
```
It will automatically download a binary version of LaMEM which runs in parallel (along with the correct PETSc version). This will work on linux, mac and windows.

### Starting a simulation
If you have a LaMEM (`*.dat`) input file, you can run in parallel (here on 4 cores) with:
```julia
julia> ParamFile="input_files/FallingBlock_Multigrid.dat";
julia> run_lamem(ParamFile, 4,"-time_end 1")
-------------------------------------------------------------------------- 
                   Lithosphere and Mantle Evolution Model                   
     Compiled: Date: Sep 10 2022 - Time: 06:21:30           
-------------------------------------------------------------------------- 
        STAGGERED-GRID FINITE DIFFERENCE CANONICAL IMPLEMENTATION           
-------------------------------------------------------------------------- 
Parsing input file : input_files/FallingBlock_Multigrid.dat 
   Adding PETSc option: -snes_type ksponly
   Adding PETSc option: -js_ksp_monitor
   Adding PETSc option: -crs_pc_type bjacobi
Finished parsing input file : input_files/FallingBlock_Multigrid.dat 
--------------------------------------------------------------------------
Time stepping parameters:
   Simulation end time          : 1. [ ] 
   Maximum number of steps      : 10 
   Time step                    : 10. [ ] 
   Minimum time step            : 1e-05 [ ] 
   Maximum time step            : 100. [ ] 
   Time step increase factor    : 0.1 
   CFL criterion                : 0.5 
   CFLMAX (fixed time steps)    : 0.5 
   Output time step             : 0.2 [ ] 
   Output every [n] steps       : 1 
   Output [n] initial steps     : 1 
--------------------------------------------------------------------------
```
The last parameter are optional PETSc command-line options. By default it runs on one processor.

Please note that you will have to be in the correct directory or indicate where that directory is. If you are in a different directory, the easiest way to change to the correct one is by using the `changefolder` function (on Windows and Mac):
```julia
julia> changefolder()
```

Alternatively, you can use the build-in terminal/shell in julia, which you can access with:
```julia
julia>;
shell>cd ~/LaMEM/input_models/BuildInSetups/
```
use the Backspace key to return to the julia REPL.


Once you have performed a simulation, you can look at the results by opening the `*.pvd` files with Paraview. In this example, that would be `FB_multigrid.pvd` and `FB_multigrid_phase.pvd`.
