# This is the main LaMEM Model struct

export Model

mutable struct Model
    Grid::Grid
    output_Dir::String

    function Model(;
        LaMEM_Grid=Grid(), 
        output_Dir="output"
        )

        return new(LaMEM_Grid, output_Dir)
    end
    
end

# Show brief overview 
function show(io::IO, d::Model)
    println(io,"LaMEM Model setup")
    println(io,"|")
    println(io,"|-- Scaling  : ")
    show_short(io, d.Grid)  # grid

end