# This is the main LaMEM Model struct
using GeophysicalModelGenerator.GeoParams

export Model, Write_LaMEM_InputFile

mutable struct Model
    Scaling::Scaling
    Grid::Grid
    Time
    FreeSurface
    BoundaryConditions
    SolutionParams
    Solver
    ModelSetup
    Output
    Materials

    function Model(;
        Scaling=Scaling(GEO_units()),
        Grid=Grid(), 
        Time=Time(),
        FreeSurface=FreeSurface(),
        BoundaryConditions=nothing,
        SolutionParams=nothing,
        Solver=nothing,
        ModelSetup=nothing,
        Output=nothing,
        Materials=nothing
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
    


    close(io)
    
end