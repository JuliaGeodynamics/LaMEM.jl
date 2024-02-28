# Create & run setups from julia

It is also possible to construct a LaMEM setup directly in julia & run that. You can do the same from within a [Pluto](https://plutojl.org) notebook. The advantage is that it is easier to use, has build-in plotting functions and extensive documentation. 

The main routine to do this is: 

```julia
julia> using LaMEM
julia> model  = Model()
LaMEM Model setup
|
|-- Scaling             :  GeoParams.Units.GeoUnits{GEO}
|-- Grid                :  nel=(16, 16, 16); xϵ(-10.0, 10.0), yϵ(-10.0, 0.0), zϵ(-10.0, 0.0) 
|-- Time                :  nstep_max=50; nstep_out=1; time_end=1.0; dt=0.05
|-- Boundary conditions :  noslip=[0, 0, 0, 0, 0, 0]
|-- Solution parameters :  eta_min=1.0e18; eta_max=1.0e25; eta_ref=1.0e20; act_temp_diff=0
|-- Solver options      :  direct solver; superlu_dist; penalty term=10000.0
|-- Model setup options :  Type=files; 
|-- Output options      :  filename=output; pvd=1; avd=0; surf=0
|-- Materials           :  0 phases;
```

`Model` is a structure that contains all the information about the LaMEM simulation and consists of the following sub-structures that can all be adjusted.
```
BoundaryConditions  FreeSurface         Grid                
Materials           ModelSetup          Output              
Scaling             SolutionParams      Solver              
Time
```

You can, for example, look at the current `Grid`:
```julia
julia> model.Grid
LaMEM grid with constant Δ: 
  nel         : ([16], [16], [16])
  marker/cell : (3, 3, 3)
  x           ϵ [-10.0 : 10.0]
  y           ϵ [-10.0 : 0.0]
  z           ϵ [-10.0 : 0.0]
  Phases      : range ϵ [0 - 0]
  Temp        : range ϵ [0.0 - 0.0]
```
and change the dimensions and number of grid-cells with:
```julia
julia> model.Grid = Grid(nel=[32,32,32], x=[-20,20])
LaMEM grid with constant Δ: 
  nel         : ([32], [32], [32])
  marker/cell : (3, 3, 3)
  x           ϵ [-20.0 : 20.0]
  y           ϵ [-10.0 : 0.0]
  z           ϵ [-10.0 : 0.0]
  Phases      : range ϵ [0 - 0]
  Temp        : range ϵ [0.0 - 0.0]
```
or do it by directly accessing the respectyive data field:
```julia
julia> model.Grid.nel_x = [32]
1-element Vector{Int64}:
 32
```

Every LaMEM model setup needs to specify material properties for the different materials. By default it has nothing:
```
julia> model.Materials
LaMEM Material Properties: 
  Softening       = 
  PhaseTransition =
```

yet, we can specify different materials using the `Phase` structure:
```julia
julia> sphere = Phase(Name="Sphere", ID=1, eta=1e20, rho=2800)
Phase 1 (Sphere): 
  rho    = 2800.0 
  eta    = 1.0e20 
```
and add that to the model with:
```julia
julia> add_phase!(model, sphere)
julia> model
LaMEM Model setup
|
|-- Scaling             :  GeoParams.Units.GeoUnits{GEO}
|-- Grid                :  nel=(32, 32, 32); xϵ(-20.0, 20.0), yϵ(-10.0, 0.0), zϵ(-10.0, 0.0) 
|-- Time                :  nstep_max=50; nstep_out=1; time_end=1.0; dt=0.05
|-- Boundary conditions :  noslip=[0, 0, 0, 0, 0, 0]
|-- Solution parameters :  eta_min=1.0e18; eta_max=1.0e25; eta_ref=1.0e20; act_temp_diff=0
|-- Solver options      :  direct solver; superlu_dist; penalty term=10000.0
|-- Model setup options :  Type=files; 
|-- Output options      :  filename=output; pvd=1; avd=0; surf=0
|-- Materials           :  1 phases; 
```
Note that the model now has 1 phase.

In order to run a simulation, we need to define at least 1 phase and heterogeneities in either the initial temperature field (`model.Grid.Temp`) or the Phases field (`model.Grid.Phases`).
The easiest way to do that is to use routines from the `GeophyicalModelGenerator` package, for which we created simple interfaces to many of the relevant routines:
```julia
julia> using GeophysicalModelGenerator
julia> AddSphere!(model,cen=(0.0,0.0,0.0), radius=(0.5, ))
```

For the sake of this example, lets add another phase:
```julia
julia> matrix = Phase(ID=0,Name="matrix",eta=1e20,rho=3000)
Phase 0 (matrix): 
  rho    = 3000.0 
  eta    = 1.0e20 
julia> add_phase!(model, matrix)
```

At this stage you have a model setup with 2 phases and heterogeneities in the `Phases` field, which you can check with:
```julia 
julia> model
LaMEM Model setup
|
|-- Scaling             :  GeoParams.Units.GeoUnits{GEO}
|-- Grid                :  nel=(32, 32, 32); xϵ(-20.0, 20.0), yϵ(-10.0, 0.0), zϵ(-10.0, 0.0) 
|-- Time                :  nstep_max=50; nstep_out=1; time_end=1.0; dt=0.05
|-- Boundary conditions :  noslip=[0, 0, 0, 0, 0, 0]
|-- Solution parameters :  eta_min=1.0e18; eta_max=1.0e25; eta_ref=1.0e20; act_temp_diff=0
|-- Solver options      :  direct solver; superlu_dist; penalty term=10000.0
|-- Model setup options :  Type=files; 
|-- Output options      :  filename=output; pvd=1; avd=0; surf=0
|-- Materials           :  2 phases; 


julia> model.Grid
LaMEM grid with constant Δ: 
  nel         : ([32], [32], [32])
  marker/cell : (3, 3, 3)
  x           ϵ [-20.0 : 20.0]
  y           ϵ [-10.0 : 0.0]
  z           ϵ [-10.0 : 0.0]
  Phases      : range ϵ [0 - 1]
  Temp        : range ϵ [0.0 - 0.0]
```

Running a model is very simple:
```julia
julia> run_lamem(model,1)
```

### More examples
More examples can be found on the left hand side menu.
