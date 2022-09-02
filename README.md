# LaMEM.jl
This is the Julia interface to [LaMEM](https://bitbucket.org/bkaus/lamem) (Lithosphere and Mantle Evolution Model), which allows you to start a (parallel) LaMEM simulation from julia, and read back the output files to julia for further processing.

See [GeophysicalModelGenerator](https://github.com/JuliaGeodynamics/GeophysicalModelGenerator.jl) for tools to create input models for LaMEM, from data.

### 1. Installation
Go to the package manager & install it with:
```julia
julia>]
pkg>add LaMEM
```
It will automatically download a binary version of LaMEM which runs in parallel (along with the correct PETSc version).
### 2. Starting a simulation
As usual, you need a LaMEM (`*.dat`) input file, which you can run in parallel (here on 4 cores) with:
```julia
julia> ParamFile="input_files/FallingBlock_Multigrid.dat";
julia> run_lamem(ParamFile, 4,"-time_end 1")
```
The last parameter are optional PETSc command-line options. By default it runs on one processor
### 3. Reading output files back into julia
There is an easy way to read the output of a LaMEM timestep back into julia:
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
- PythonCall - installs a local python version and the VTK toolbox, used to read the outout files
- GeophysicalModelGenerator - Data structure in which we store the info of a LaMEM timestep 
