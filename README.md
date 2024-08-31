# LaMEM.jl
[![Build Status](https://github.com/JuliaGeodynamics/LaMEM.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeodynamics/LaMEM.jl/actions)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliageodynamics.github.io/LaMEM.jl/dev/)
[![DOI](https://zenodo.org/badge/531427568.svg)](https://zenodo.org/doi/10.5281/zenodo.10211627)

This is the Julia interface to [LaMEM](https://github.com/UniMainzGeo/LaMEM/)) (Lithosphere and Mantle Evolution Model), which is the easiest way to install LaMEM on any system. It allows you to start a (parallel) LaMEM simulation, and read back the output files to julia for further processing. Below we give some brief steps in how to use it. More examples can be found in the [user guide](https://juliageodynamics.github.io/LaMEM.jl/dev/).

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

### 2. Create a model setup & run LaMEM
You can directly create a LaMEM setup in julia with: 
```Julia
julia> using LaMEM, GeophysicalModelGenerator
julia> model  = Model(Grid(nel=(16,16,16), x=[-1,1], y=[-1,1], z=[-1,1]))
LaMEM Model setup
|
|-- Scaling             :  GeoParams.Units.GeoUnits{GEO}
|-- Grid                :  nel=(16, 16, 16); xϵ(-1.0, 1.0), yϵ(-1.0, 1.0), zϵ(-1.0, 1.0) 
|-- Time                :  nstep_max=50; nstep_out=1; time_end=1.0; dt=0.05
|-- Boundary conditions :  noslip=[0, 0, 0, 0, 0, 0]
|-- Solution parameters :  eta_min=1.0e18; eta_max=1.0e25; eta_ref=1.0e20; act_temp_diff=0
|-- Solver options      :  direct solver; superlu_dist; penalty term=10000.0
|-- Model setup options :  Type=files; 
|-- Output options      :  filename=output; pvd=1; avd=0; surf=0
|-- Materials           :  0 phases; 
```
Add materials to the setup:
```Julia
julia> matrix = Phase(ID=0,Name="matrix",eta=1e20,rho=3000);
julia> sphere = Phase(ID=1,Name="sphere",eta=1e23,rho=3200)
Phase 1 (sphere): 
  rho    = 3200.0 
  eta    = 1.0e23 
julia> add_phase!(model, sphere, matrix)
```

Create an initial geometry using the [GeophysicalModelGenerator](https://github.com/JuliaGeodynamics/GeophysicalModelGenerator.jl/tree/main) interface:
```Julia
julia> add_sphere!(model,cen=(0.0,0.0,0.0), radius=(0.5, ))
```
and run the simulation with:
```julia
julia> run_lamem(model,1)
Saved file: Model3D.vts
Writing LaMEM marker file -> ./markers/mdb.00000000.dat
-------------------------------------------------------------------------- 
                   Lithosphere and Mantle Evolution Model                   
     Compiled: Date: Apr  7 2023 - Time: 22:11:23           
     Version : 1.2.4 
-------------------------------------------------------------------------- 
        STAGGERED-GRID FINITE DIFFERENCE CANONICAL IMPLEMENTATION           
-------------------------------------------------------------------------- 
Parsing input file : output.dat 
Finished parsing input file : output.dat 
--------------------------------------------------------------------------
...
```
Note that if you have a linux/mac machine you can run it in parallel (change 1 to 2 or 4, for example). On windows you would have to install Linux for Windows first, using [WSL](https://learn.microsoft.com/en-us/windows/wsl/install).
Once the simulation is done, you can open it with Paraview, or directly plot it within julia (see the documentation).


### 3. Starting a simulation
If you have an existing LaMEM (`*.dat`) input file, you can run that in parallel (here on 4 cores) with:
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

### 4. Reading LaMEM output back into julia
If you want to quantitatively do something with the results, there is an easy way to read the output of a LaMEM timestep back into julia. All routines related to that are part of the `LaMEM.IO` module.

```julia
julia> using LaMEM
```
You can first read the `*.pvd` file in the directory to see which timesteps are available. If you used julia to run the simulation (as under 2 above ), this is done with:
```julia
julia> Timestep, Filenames, t = read_LaMEM_simulation(model)
([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], ["Timestep_00000000_0.00000000e+00/output.pvtr", "Timestep_00000001_4.40000000e-02/output.pvtr", "Timestep_00000002_9.24000000e-02/output.pvtr", "Timestep_00000003_1.45640000e-01/output.pvtr", "Timestep_00000004_2.04204000e-01/output.pvtr", "Timestep_00000005_2.68624400e-01/output.pvtr", "Timestep_00000006_3.39486840e-01/output.pvtr", "Timestep_00000007_4.17435524e-01/output.pvtr", "Timestep_00000008_5.03179076e-01/output.pvtr", "Timestep_00000009_5.97496984e-01/output.pvtr", "Timestep_00000010_7.01246682e-01/output.pvtr", "Timestep_00000011_8.15371351e-01/output.pvtr", "Timestep_00000012_9.40908486e-01/output.pvtr", "Timestep_00000013_1.07899933e+00/output.pvtr"], [0.0, 0.044, 0.0924, 0.14564, 0.204204, 0.2686244, 0.3394868, 0.4174355, 0.5031791, 0.597497, 0.7012467, 0.8153714, 0.9409085, 1.078999])
```

If you instead have an existing LaMEM simulation, you can specify the `*.pvd` file:
```julia
julia> pvdname="output"
julia> Timestep, Filenames, t = read_LaMEM_simulation(pvdname)
```

We can read a particular timestep (say 1) with:
```julia
julia> data, time = read_LaMEM_timestep(model, 1)
(CartData 
    size    : (17, 17, 17)
    x       ϵ [ -1.0 : 1.0]
    y       ϵ [ -1.0 : 1.0]
    z       ϵ [ -1.0 : 1.0]
    fields  : (:phase, :density, :visc_total, :visc_creep, :velocity, :pressure, :temperature, :j2_dev_stress, :j2_strain_rate)
  attributes: ["note"]
, [0.044])
```
The output is in a `CartData` structure (as defined in GeophysicalModelGenerator).
More details are given in the [documentation](https://juliageodynamics.github.io/LaMEM.jl/dev/).

### 5. Dependencies
We rely on the following packages:
- [GeophysicalModelGenerator](https://github.com/JuliaGeodynamics/GeophysicalModelGenerator.jl) - Data structure in which we store the info of a LaMEM timestep. The package can also be used to generate setups for LaMEM.
- [LaMEM_jll](https://github.com/JuliaBinaryWrappers/LaMEM_jll.jl) - this contains the LaMEM binaries, precompiled for most systems. It also contains a precompiled version of PETSc, along with MPI. Note that on windows, MPI does not work, so you can only use one processor. We therefore recommend that you install linux on windows (using WSL) and run LaMEM through that.
- [ReadVTK](https://github.com/JuliaVTK/ReadVTK.jl) - This reads the LaMEM `*.vtk` files (or the rectilinear and structured grid versions of it)  baxck into julia. 


### 6. Funding
Funding for this julia interface has been provided by the European Research Council (ERC CoG [MAGMA # 771143](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwi8rN_Iy7SEAxX8SfEDHfd3AzkQFnoECB4QAQ&url=https%3A%2F%2Fcordis.europa.eu%2Fproject%2Fid%2F771143&usg=AOvVaw1G1LUjR9t9KtX6pcE2ozr2&opi=89978449)), and by the EuroHPC-JU Center of Excellence [CHEESE-2P](https://cheese2.eu).
