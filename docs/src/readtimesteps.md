# Read timesteps back into LaMEM
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

If you do not indicate a directory name (`DirName`) it'll look in your current directory. The default above will load the main LaMEM simulation output. Alternatively, you can also load the `phase` information by specify the optional keyword `phase=true`:
```julia
julia> data, time = Read_LaMEM_timestep(FileName, 1, DirName, phase=true)
(CartData 
    size    : (96, 96, 96)
    x       ϵ [ 0.0052083334885537624 : 0.9947916269302368]
    y       ϵ [ 0.0052083334885537624 : 0.9947916269302368]
    z       ϵ [ 0.0052083334885537624 : 0.9947916269302368]
    fields  : (:phase,)
  attributes: ["note"]
, [6.729703])
```
In the same way, you can load the internal free surface with `surf=true` (if that was saved), or passive tracers (`passive_tracers=true`).
If you don't want to load all the fields in the file back to julia, you can check which fields are available:

```julia
julia> Read_LaMEM_fieldnames(FileName, DirName)
("phase [ ]", "visc_total [ ]", "visc_creep [ ]", "velocity [ ]", "pressure [ ]", "strain_rate [ ]", "j2_dev_stress [ ]", "j2_strain_rate [ ]")
```
and load only part of those:
```julia
julia> data, time = Read_LaMEM_timestep(FileName, 1, DirName, fields=("phase [ ]", "visc_total [ ]","velocity [ ]"))
(CartData 
    size    : (33, 33, 33)
    x       ϵ [ 0.0 : 1.0]
    y       ϵ [ 0.0 : 1.0]
    z       ϵ [ 0.0 : 1.0]
    fields  : (:phase, :visc_total, :velocity)
  attributes: ["note"]
, [6.729703])
```
