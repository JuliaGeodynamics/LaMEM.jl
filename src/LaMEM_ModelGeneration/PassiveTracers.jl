#PassiveTracers

# Capture meta-data with:
# Docs.meta(LaMEM.LaMEM_Model)[Docs.@var(LaMEM.LaMEM_Model.PassiveTracers)].docs[Union{}].data

export PassiveTracers, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM passive tracers parameters. 

    $(TYPEDFIELDS)

"""
Base.@kwdef mutable struct PassiveTracers
    """
    activate passive tracers?"
    """
    Passive_Tracer::Int64 = 0

    """
    Dimensions of box in which we distribute passive tracers   [Left, Right, Front, Back, Bottom, Top]
    """
    PassiveTracer_Box::Union{Nothing,Vector{Float64}}     = [-600.0, 600, -1, 1, -300, -50]     

    """
    The number of passive tracers in every direction
    """
    PassiveTracer_Resolution::Vector{Int64}     = [100,1,100]       

    """
    Under which condition are they activated? ["Always"],  "Melt_Fraction", "Temperature", "Pressure", "Time"  
    """
    PassiveTracer_ActiveType::Union{Nothing,String}     = "Always"       

    """
    The value to activate them
    """
    PassiveTracer_ActiveValue::Union{Nothing,Float64}   = 0.1       

end

# Print info about the structure
function show(io::IO, d::PassiveTracers)
    Reference = PassiveTracers();    # reference values
    if d.Passive_Tracer==1
        println(io, "LaMEM passive tracers (active): ")
    else
        println(io, "LaMEM passive tracers (inactive): ")
    end
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),15)) = $(getfield(d,f)) \n", color=col)        
    end
    
    return nothing
end

function show_short(io::IO, d::PassiveTracers)
    if d.Passive_Tracer==1
        N = d.PassiveTracer_Resolution;
        c = d.PassiveTracer_Box;
        val = d.PassiveTracer_ActiveValue
        if d.PassiveTracer_ActiveType=="Always"
            value = ""
        else
            value = "Value=$val; "
        end 
        println(io,"|-- Passive Tracers     :  Type=$(d.PassiveTracer_ActiveType); $(value)Res=[$(N[1]),$(N[2]),$(N[3])], Box=[$(c[1]):$(c[2]),$(c[3]):$(c[4]),$(c[5]):$(c[6])]")
    end
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
    println(io, "# Passive tracers ")
    println(io, "#===============================================================================")
    #println(io,"")
    if d.Passive_Tracer==1
    
        for f in fields
            # only print if value differs from reference value
            name = rpad(String(f),15)
            data = getfield(d,f) 
            help_string  = get_doc(PassiveTracers, f)
            print(io,"   $name  = $(write_vec(data))     # $(help_string)")
        end

        println(io,"")
        end
    return nothing
end
