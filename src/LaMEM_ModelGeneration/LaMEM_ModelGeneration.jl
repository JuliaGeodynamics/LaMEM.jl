# These are routines that allow us to fully create a LaMEM model in julia & run it
# In the background, it will create a lamem *.dat model setup and run that

module LaMEM_Model

using GeophysicalModelGenerator
using GeophysicalModelGenerator.GeoParams
import Base: show

filter_fields(fields, filter_out) = (setdiff(fields, filter_out)...,)

include("Scaling.jl")   # Scaling
export Scaling 

include("Grid.jl")      # LaMEM grid 
export Grid

include("Time.jl")      # Timestepping
export Time

include("FreeSurface.jl")      # Timestepping
export FreeSurface

include("Model.jl")     # main LaMEM_Model
export Model

end