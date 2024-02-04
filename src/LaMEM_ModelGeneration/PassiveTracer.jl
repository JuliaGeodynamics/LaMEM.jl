#PassiveTracers

# Capture meta-data with:
# Docs.meta(LaMEM.LaMEM_Model)[Docs.@var(LaMEM.LaMEM_Model.PassiveTracers)].docs[Union{}].data

export PassiveTracers, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM passive tracers parameters. 

    $(TYPEDFIELDS)

"""
Base.@kwdef mutable struct PassiveTracers
    "activate passive tracers?"
    Passive_Tracer::Int64 = 0

    """
    Dimensions of box in which we distribute passive tracers  
    """
    PassiveTracer_Box::Union{Nothing,Vector{Float64}}     = nothing       

    """
    The number of passive tracers in every direction
    """
    PassiveTracer_Resolution::Vector{Int64}     = [100,1,100]       

    """
    Under which condition are they activated? ["Always"],  "Melt_Fraction", "Temperature", "Pressure", "Time"  
    """
    PassiveTracer_ActiveType::Union{Nothing,String}     = "Always"       

    """
    Under which condition are they activated? ["Always"],  "Melt_Fraction", "Temperature", "Pressure", "Time"  
    """
    PassiveTracer_ActiveValue::Union{Nothing,Float64}   = nothing       

end

# Print info about the structure
function show(io::IO, d::PassiveTracers)
    Reference = PassiveTracers();    # reference values
    println(io, "LaMEM Passive Tracers : ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),15)) = $(getfield(d,f)) \n", color=col)        
    end
    
    return nothing
end

function show_short(io::IO, d::PassiveTracers)
    println(io,"|-- Passive Tracers :  Passive_Tracer=$(d.Passive_Tracer); PassiveTracer_Box=$(d.PassiveTracer_Box); PassiveTracer_Resolution=$(d.PassiveTracer_Resolution); PassiveTracer_ActiveType=$(d.PassiveTracer_ActiveType); PassiveTracer_ActiveValue=$(d.PassiveTracer_ActiveValue)")
    return nothing
end



"""
    Write_LaMEM_InputFile(io, d::PassiveTracers)
Writes the boundary conditions related parameters to file
"""
function Write_LaMEM_InputFile(io, d::PassiveTracers)
    Reference = PassiveTracers();    # reference values
    fields    = fieldnames(typeof(d))
    
    println(io, "#===============================================================================")
    println(io, "# Passive Tracers")
    println(io, "#===============================================================================")
    println(io,"")

    for f in fields
        if getfield(d,f) != getfield(Reference,f) ||
            (f == :eta_ref) ||
            (f == :gravity)

            # only print if value differs from reference value
            name = rpad(String(f),15)
            data = getfield(d,f) 
            help_string  = get_doc(PassiveTracers, f)
            println(io,"    $name  = $(write_vec(data))     # $(help_string)")
        end
    end

    println(io,"")
    return nothing
end
