# LaMEM.jl
[![Build Status](https://github.com/JuliaGeodynamics/LaMEM.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeodynamics/LaMEM.jl/actions)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliageodynamics.github.io/LaMEM.jl/dev/)

This is the Julia interface to [LaMEM](https://github.com/UniMainzGeo/LaMEM/)) (Lithosphere and Mantle Evolution Model), which is the easiest way to install LaMEM on any system. It allows you to start a (parallel) LaMEM simulation, and read back the output files to julia for further processing.

### 1. Installation
Go to the package manager & install it with:
```julia
julia>]
pkg>add LaMEM
```
It will automatically download a binary version of LaMEM which runs in parallel (along with the correct PETSc version). This will work on linux, mac and windows.
If you want to check that it works on your machine type:
```julia
pkg>test LaMEM
```
which will run the build-in testsuite.

### 2. Starting a simulation
As usual, you need a LaMEM (`*.dat`) input file, which you can run in parallel (here on 4 cores) with:
```julia
julia> using LaMEM
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

### 3. Reading LaMEM output back into julia
If you want to quantitatively do something with the results, there is an easy way to read the output of a LaMEM timestep back into julia. All routines related to that are part of the `LaMEM.IO` module.

```julia
julia> using LaMEM
```
You can first read the `*.pvd` file in the directory to see which timesteps are available:
```julia
julia> FileName="FB_multigrid"
julia> DirName ="test"
julia> Timestep, Filenames, Time = Read_LaMEM_simulation(FileName, DirName)
([0, 1], ["Timestep_00000000_0.00000000e+00/FB_multigrid.pvtr", "Timestep_00000001_6.72970343e+00/FB_multigrid.pvtr"], [0.0, 6.729703])
```
We can read a particular timestep (say 1) with:
```julia
julia> data, time = Read_LaMEM_timestep(FileName, 1, DirName)
(CartData 
    size    : (33, 33, 33)
    x       ϵ [ 0.0 : 1.0]
    y       ϵ [ 0.0 : 1.0]
    z       ϵ [ 0.0 : 1.0]
    fields  : (:phase, :visc_total, :visc_creep, :velocity, :pressure, :strain_rate, :j2_dev_stress, :j2_strain_rate)
  attributes: ["note"]
, [6.729703])
```
The output is in a `CartData` structure (as defined in GeophysicalModelGenerator).
More details are given in the documentation.

### 4. Dependencies
We rely on the following packages:
- [GeophysicalModelGenerator](https://github.com/JuliaGeodynamics/GeophysicalModelGenerator.jl) - Data structure in which we store the info of a LaMEM timestep. The package can also be used to generate setups for LaMEM.
- [LaMEM_jll](https://github.com/JuliaRegistries/General/tree/master/L/LaMEM_jll) - this contains the LaMEM binaries, precompiled for most systems. Note that on windows, the MUMPS parallel direct solver is not available.
- [ReadVTK](https://github.com/JuliaVTK/ReadVTK.jl) - This reads the LaMEM `*.vtk` files (or the rectilinear and structured grid versions of it)  baxck into julia.
