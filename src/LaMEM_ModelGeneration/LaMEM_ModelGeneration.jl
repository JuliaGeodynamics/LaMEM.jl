# These are routines that allow us to fully create a LaMEM model in julia & run it
# In the background, it will create a lamem *.dat model setup and run that

module LaMEM_Model

using GeophysicalModelGenerator
using GeophysicalModelGenerator.GeoParams
using DocStringExtensions
import Base: show

# Few utils that are being used
filter_fields(fields, filter_out) = (setdiff(fields, filter_out)...,)
gettext_color(d,Reference, field) = getfield(d,field) != getfield(Reference,field) ? :blue : :default

function write_vec(data)
    if !isa(data,String)
        str = ""; for d in data; str = str*" $d" end
    else
        str = data
    end

    return str
end

"""
    help_info::String = get_doc(structure, field::Symbol) 
This returns a string with the documentation for a parameter `field` that is within the `structure`. 
Note that this structure must be a help structure of the current one.
"""
function get_doc(structure, field::Symbol) 
    alldocs       =   Docs.meta(LaMEM_Model);
    var           =   eval(Meta.parse("Docs.@var($structure)"))
    fields_local  =   alldocs[var].docs[Union{}].data[:fields]
    str = fields_local[field]

    # Add comment to next line (if required)
    str = replace(str, "\n" => "\n #")

    # remove the # at the end of the string
    if str[end]=='#'
        str = str[1:end-1]
    end

    return str
end

include("Scaling.jl")   # Scaling
export Scaling 

include("Grid.jl")      # LaMEM grid 
export Grid

include("Time.jl")      # Timestepping
export Time

include("FreeSurface.jl")           # Free surface
export FreeSurface

include("BoundaryConditions.jl")    # Boundary Conditions
export BoundaryConditions

include("SolutionParams.jl")        # Solution parameters 
export SolutionParams

include("Solver.jl")                # solver options
export Solver

include("ModelSetup.jl")            # model setup options
export ModelSetup, geom_Sphere, set_geom!

include("Output.jl")                # output options
export Output

include("Materials.jl")             # main LaMEM_Model
export Materials, Phase, Softening, PhaseTransition, Dike

include("Model.jl")                 # main LaMEM_Model
export Model

include("GMG_interface.jl")

include("Utils.jl")
export  add_phase!, rm_phase!, rm_last_phase!, add_petsc!, add_softening!,
        add_phasetransition!, add_dike!, add_geom!        

    
include("ErrorChecking.jl")
export Check_LaMEM_Model

end


#=

# this simplifies the process to create the correct structures from the LaMEM input *.dat file
function transfer_data()
    io = open("test_in.dat","r")
    io_w = open("test_out.dat","w")

    while !eof(io)
        line = readline(io)
        line_new    = split(line,"#")
        if length(line_new)==2
            line_new = line_new[2:-1:1]
            line_new[1] = "    \""*strip(line_new[1])*"\""
        end
        for i=1:length(line_new)
            println(io_w,line_new[i])
        end
        println(io_w,"")

    end

    close(io)
    close(io_w)
end


=#
