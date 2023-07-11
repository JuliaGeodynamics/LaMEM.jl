# This is the main LaMEM Model struct
using GeophysicalModelGenerator.GeoParams

export Model, Write_LaMEM_InputFile

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

        return new(Scaling, Grid, Time, FreeSurface, BoundaryConditions, 
                    SolutionParams, Solver, ModelSetup, Output, Materials)
    end
    
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



