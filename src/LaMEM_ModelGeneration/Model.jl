# This is the main LaMEM Model struct
using GeophysicalModelGenerator.GeoParams

export Model, Write_LaMEM_InputFile

"""
    Model

Structure that holds all the information to create a LaMEM input file

    $(TYPEDFIELDS)
"""
mutable struct Model
    "Scaling parameters"
    Scaling::Scaling
    
    "LaMEM Grid"
    Grid::Grid
    
    "Time options"
    Time

    "Free surface options"
    FreeSurface

    "Boundary conditions"
    BoundaryConditions

    "Global solution parameters"
    SolutionParams

    "Solver options and optional PETSc options"
    Solver

    "Model setup"
    ModelSetup

    "Output options"
    Output

    "Material parameters for each of the phases"
    Materials

    
end

"""
    Model(;
        Scaling=Scaling(GEO_units()),
        Grid=Grid(), 
        Time=Time(),
        FreeSurface=FreeSurface(),
        BoundaryConditions=BoundaryConditions(),
        SolutionParams=SolutionParams(),
        Solver=Solver(),
        ModelSetup=ModelSetup(),
        Output=Output(),
        Materials=Materials()
        )

Creates a LaMEM Model setup.

    $(TYPEDFIELDS)

"""
function Model(;
    Scaling=Scaling(GEO_units()),
    Grid=Grid(), 
    Time=Time(),
    FreeSurface=FreeSurface(),
    BoundaryConditions=BoundaryConditions(),
    SolutionParams=SolutionParams(),
    Solver=Solver(),
    ModelSetup=ModelSetup(),
    Output=Output(),
    Materials=Materials()
    )

    return Model(Scaling, Grid, Time, FreeSurface, BoundaryConditions, 
                SolutionParams, Solver, ModelSetup, Output, Materials)
end

"""
    Model(args...)

Allow to define a model setup by specifying some of the basic objects

Example
===
```julia
julia> d = Model(Grid(nel=(10,1,20)), Scaling(NO_units()))
LaMEM Model setup
|
|-- Scaling             :  GeoParams.Units.GeoUnits{GeoParams.Units.NONE}
|-- Grid                :  nel=(10, 1, 20); xϵ(-10.0, 10.0), yϵ(-10.0, 0.0), zϵ(-10.0, 0.0) 
|-- Time                :  nstep_max=50; nstep_out=1; time_end=1.0; dt=0.05
|-- Boundary conditions :  noslip=[0, 0, 0, 0, 0, 0]
|-- Solution parameters :  
|-- Solver options      :  direct solver; superlu_dist; penalty term=10000.0
|-- Model setup options :  Type=geom; 
|-- Output options      :  filename=output; pvd=1; avd=0; surf=0
|-- Materials           :  1 phases;  

```

"""
function Model(args...)
    names_str = typeof.(args);  # this may have { } in them
    names_strip = ();
    for name in names_str
        name_str = split("$name","{")[1]
        names_strip = (names_strip..., name_str)
    end 
    args_tuple = NamedTuple{Symbol.(names_strip)}(args)

    return Model(; args_tuple...)
end

# Show brief overview of Model
function show(io::IO, d::Model)
    println(io,"LaMEM Model setup")
    println(io,"|")
    show_short(io, d.Scaling)   
    show_short(io, d.Grid)     
    show_short(io, d.Time)      
    show_short(io, d.FreeSurface)   
    show_short(io, d.BoundaryConditions)   
    show_short(io, d.SolutionParams)   
    show_short(io, d.Solver)   
    show_short(io, d.ModelSetup)   
    show_short(io, d.Output)   
    show_short(io, d.Materials)
    
end



"""
    Write_LaMEM_InputFile(d::Model,fname::String; dir=pwd())

Writes a LaMEM input file based on the data stored in Model
"""
function Write_LaMEM_InputFile(d::Model, fname::String="input.dat"; dir=pwd())
    Check_LaMEM_Model(d)    # check for mistakes in input


    io = open(fname,"w")

    Write_LaMEM_InputFile(io, d.Scaling)
    Write_LaMEM_InputFile(io, d.Grid)
    Write_LaMEM_InputFile(io, d.Time)
    Write_LaMEM_InputFile(io, d.FreeSurface)
    Write_LaMEM_InputFile(io, d.BoundaryConditions)
    Write_LaMEM_InputFile(io, d.SolutionParams)
    Write_LaMEM_InputFile(io, d.Solver)
    Write_LaMEM_InputFile(io, d.ModelSetup)
    Write_LaMEM_InputFile(io, d.Output)
    Write_LaMEM_InputFile(io, d.Materials)
    
    Write_LaMEM_InputFile_PETSc(io, d.Solver)   # add PETSc options last

    close(io)
end



