# These are routines that allow us to fully create a LaMEM model in julia & run it
# In the background, it will create a lamem *.dat model setup and run that

module LaMEM_Model

using GeophysicalModelGenerator
import Base: show

include("Grid.jl")  # LaMEM grid 
export Grid, Write_LaMEM_InputFile

include("Model.jl") # main LaMEM_Model
export Model

end