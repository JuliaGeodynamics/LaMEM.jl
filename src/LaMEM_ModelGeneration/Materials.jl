# Specify Material properties
export Materials, Phase, Write_LaMEM_InputFile



"""
    Defines the material properties for each of the phases

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Phase
    "Material phase ID"
    ID::Union{Nothing,Int64}    = nothing     

    "Description of the phase" 
    Name::Union{Nothing,String} = nothing   

    "Density"
    rho::Union{Nothing,Float64} = nothing

    "Linear viscosity"
    eta::Union{Nothing,Float64} = nothing

end

function show(io::IO, d::Phase)
    println(io, "Phase $(d.ID) ($(d.Name)): ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) & (f != :ID) & (f != :Name)
            printstyled(io,"  $(rpad(String(f),6)) = $(getfield(d,f)) \n")        
        end
    end

    return nothing
end


"""
    Structure that contains the material properties in the current simulation
    
    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Materials
    "Different Materials implemented"
    Phases::Vector{Phase}      =	[Phase(ID=0, eta=1, rho=1)]

    "Softening laws implemented"
    #Softening      =	nothing
end

# Print info about the structure
function show(io::IO, d::Materials)
    Reference = Materials();
    println(io, "LaMEM Materials: ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),17)) = $(getfield(d,f)) \n", color=col)        
    end
  
    return nothing
end

function show_short(io::IO, d::Materials)
    println(io,"|-- Materials           :  $(length(d.Phases)) phases defined; ")
    return nothing
end
"""
    Write_LaMEM_InputFile(io, d::Output)
Writes the free surface related parameters to file
"""
function Write_LaMEM_InputFile(io, d::Materials)
    Reference = Solver();    # reference values
    fields    = fieldnames(typeof(d))

    println(io, "#===============================================================================")
    println(io, "# Material phase parameters")
    println(io, "#===============================================================================")
    println(io,"")


    # Define softening laws
    println(io, "# Define softening laws (maximum 10)")
    #for Soft in d.Softening
    #    println(io, "   <SofteningStart>")

    #    println(io,"   <SofteningEnd>")
    #end
    
    # Define materials 
    println(io, "# Define material properties for all phases (maximum 32)")
    println(io, "# By default all rheological mechanisms are deactivated")
    println(io, "# List only active parameters in the material data block")
    println(io,"")
    for Mat in d.Phases
        Reference = Phase(); 
        println(io, "    <MaterialStart>")

        
        println(io,"    <MaterialEnd>")
    end


    println(io,"")
    return nothing
end