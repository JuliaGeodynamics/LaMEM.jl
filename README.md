# LaMEM.jl
[![Build Status](https://github.com/JuliaGeodynamics/LaMEM.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeodynamics/LaMEM.jl/actions)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliageodynamics.github.io/LaMEM.jl/dev/)

This is the Julia interface to [LaMEM](https://bitbucket.org/bkaus/lamem) (Lithosphere and Mantle Evolution Model), which is the easiest way to install LaMEM on any system, allows you to start a (parallel) LaMEM simulation, and read back the output files to julia for further processing.

### 1. Installation
Go to the package manager & install it with:
```julia
julia>]
pkg>add LaMEM
```
It will automatically download a binary version of LaMEM which runs in parallel (along with the correct PETSc version). This will work on linux, mac and windows.

### 2. Starting a simulation
As usual, you need a LaMEM (`*.dat`) input file, which you can run in parallel (here on 4 cores) with:
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

Please note that you will have to be in the correct directory (the same one as where the LaMEM parameter file is located). If you are in a different directory, the easiest way to change to the correct one is by using the `changefolder` function (on Windows and Mac):
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

### 3. Reading LaMEM output back into julia
If you want to quantitatively do something with the results, there is an easy way to read the output of a LaMEM timestep back into julia. Yet, first you have to install the `PythonCall` package as we rely on a python package to read the LaMEM (`*.vtr`) output files:
If you want to quantitatively do something with the results, there is an easy way to read the output of a LaMEM timestep back into julia. 
```julia
julia> using LaMEM
Adding PythonCall dependencies to read LaMEM timesteps
```
Make sure you are in the directory where the simulation was run and read a timestep with:
```julia
julia> FileName="FB_multigrid.pvtr"
julia> DirName = "Timestep_00000001_6.72970343e+00"
julia> data    = Read_VTR_File(DirName, FileName)
CartData 
    size    : (33, 33, 33)
    x       ϵ [ 0.0 : 1.0]
    y       ϵ [ 0.0 : 1.0]
    z       ϵ [ 0.0 : 1.0]
    fields  : (:phase, :visc_total, :visc_creep, :velocity, :pressure, :strain_rate, :j2_dev_stress, :j2_strain_rate)
  attributes: ["note"]
```
The output is in a `CartData` structure (as defined in GeophysicalModelGenerator).

Please note that you will have to be in the correct directory (see above).
Once you have performed a simulation, you can look at the results by opening the `*.pvd` files with Paraview. In this example, that would be `FB_multigrid.pvd` and `FB_multigrid_phase.pvd`.

### 3. Reading LaMEM output back into julia
If you want to quantitatively do something with the results, there is an easy way to read the output of a LaMEM timestep back into julia.  Make sure you are in the directory where the simulation was run and read a timestep with:
```julia
julia> FileName="FB_multigrid.pvtr"
julia> DirName = "Timestep_00000001_6.72970343e+00"
julia> data    = Read_VTR_File(DirName, FileName)
CartData 
    size    : (33, 33, 33)
    x       ϵ [ 0.0 : 1.0]
    y       ϵ [ 0.0 : 1.0]
    z       ϵ [ 0.0 : 1.0]
    fields  : (:phase, :visc_total, :visc_creep, :velocity, :pressure, :strain_rate, :j2_dev_stress, :j2_strain_rate)
  attributes: ["note"]
```
The output is in a `CartData` structure (as defined in GeophysicalModelGenerator).

### 4. Dependencies
We rely on the following packages:
- [GeophysicalModelGenerator](https://github.com/JuliaGeodynamics/GeophysicalModelGenerator.jl) - Data structure in which we store the info of a LaMEM timestep. The package can also be used to generate setups for LaMEM.
- [LaMEM_jll](https://github.com/JuliaRegistries/General/tree/master/L/LaMEM_jll) - this contains the LaMEM binaries, precompiled for most systems. Note that on windows, the MUMPS parallel direct solver is not available.

And for reading files, we rely on the optional package
- [PythonCall](https://github.com/cjdoris/PythonCall.jl) - installs a local python version and the VTK toolbox, used to read the output files. We make this an optional dependency as this involves installing quite a few additional packages, which have been broken at some times in the past. If you experience problems, you can try installing an earlier version of [MicroMamba](https://github.com/cjdoris/MicroMamba.jl) first (e.g. `pkg> add MicroMambe@0.1.9`), before installing `PythonCall` .  
 