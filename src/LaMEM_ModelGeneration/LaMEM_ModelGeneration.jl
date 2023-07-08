# These are routines that allow us to fully create a LaMEM model in julia & run it
# In the background, it will create a lamem *.dat model setup and run that

module LaMEM_Model

using GeophysicalModelGenerator
using GeophysicalModelGenerator.GeoParams
import Base: show

# Few utils that are being used
filter_fields(fields, filter_out) = (setdiff(fields, filter_out)...,)
gettext_color(d,Reference, field) = getfield(d,field) != getfield(Reference,field) ? :blue : :default

function write_vec(data)
    if !isa(data,String)
        str = ""
        for d in data
            str = str*" $d"
        end
    else
        str = data
    end

    return str
end

include("Scaling.jl")   # Scaling
export Scaling 

include("Grid.jl")      # LaMEM grid 
export Grid

include("Time.jl")      # Timestepping
export Time

include("FreeSurface.jl")      # Free surface
export FreeSurface

include("BoundaryConditions.jl")      # Boundary Conditions
export BoundaryConditions

include("SolutionParams.jl")      # Solution parameters 
export SolutionParams

include("Model.jl")     # main LaMEM_Model
export Model

end