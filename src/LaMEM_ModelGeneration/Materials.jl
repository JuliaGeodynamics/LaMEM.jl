# Specify Material properties
export Materials, Phase, Softening, Write_LaMEM_InputFile



"""
    Defines the material properties for each of the phases

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Phase
    "Material phase ID"
    ID::Union{Nothing,Int64}    = nothing     

    "Description of the phase" 
    Name::Union{Nothing,String} = nothing   

    "Density [kg/m^3]"
    rho::Union{Nothing,Float64} = nothing

    "Linear viscosity [Pas]"
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

function show_short(d::Phase)
    fields    = fieldnames(typeof(d))
    str = "Phase("
    for (i,f) in enumerate(fields)
        if !isnothing(getfield(d,f))
            str=str*"$(String(f))=$(getfield(d,f))"        
            if i<length(fields)
                str=str*","
            end
        end
    end
    str=str*")"
    return str
end



"""
    Defines strain softening parameters

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Softening
    "softening law ID"
    ID::Int64          =   0    

    "Begin of softening, in units of accumulated plastic strain (APS)"
    APS1::Float64        =   0.1    

    "End of softening, in units of accumulated plastic strain (APS)"
    APS2::Float64        =   1.0     
    
    "Reduction ratio"
    A::Float64           =   0.7     
    
    "Material length scale (in selected units, e.g. km in geo)"
    Lm::Float64          =   0.2    
    
    # healing parameters
    "APS when healTau2 activates"
    APSheal2::Union{Float64,Nothing}      =   nothing 

    "healing timescale parameter [Myr]  "
    healTau::Union{Float64,Nothing}       =   nothing  

    "healing timescale parameter [Myr]  starting at APS=APSheal2"
    healTau2::Union{Float64,Nothing}      =   nothing    
end

function show(io::IO, d::Softening)
    println(io, "Softening Law $(d.ID): ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) & (f != :ID) & (f != :Name)
            printstyled(io,"  $(rpad(String(f),6)) = $(getfield(d,f)) \n")        
        end
    end

    return nothing
end

function show_short(d::Softening)
    fields    = fieldnames(typeof(d))
    str = "Softening("
    for (i,f) in enumerate(fields)
        if !isnothing(getfield(d,f))
            str=str*"$(String(f))=$(getfield(d,f))"        
            if i<length(fields)
                str=str*","
            end
        end
    end
    if str[end]==','; str = str[1:end-1] end
    str=str*")"
    return str
end



"""
    Structure that contains the material properties in the current simulation
    
    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Materials
    "Different Materials implemented"
    Phases::Vector{Phase}               =	[Phase(ID=0, eta=1, rho=1)]

    "Softening laws implemented"
    SofteningLaws::Vector{Softening}    =	[]
end

# Print info about the structure
function show(io::IO, d::Materials)
    Reference = Materials();
    println(io, "LaMEM Material Properties: ")

    # print phases fields
    phases = d.Phases;
    col = gettext_color(d,Reference, :Phases)
    for (i,phase) in enumerate(phases)
        str = show_short(phase)
        if i==1
            printstyled(io,"  $(rpad("Phases",10)) = $(str) \n", color=col)        
        else
            printstyled(io,"  $(rpad(" ",10)) = $(str) \n", color=col)        
        end
    end
  

    # print softening laws fields
    softening = d.SofteningLaws;
    col = gettext_color(d,Reference, :SofteningLaws)
    for (i,soft) in enumerate(softening)
        str = show_short(soft)
        if i==1
            printstyled(io,"  $(rpad("Softening",10)) = $(str) \n", color=col)        
        else
            printstyled(io,"  $(rpad(" ",10)) = $(str) \n", color=col)        
        end
    end
    if length(softening)==0
        printstyled(io,"  $(rpad("Softening",10)) = \n", color=:default)        
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
    for Soft in d.SofteningLaws
      
        println(io, "   <SofteningStart>")
        
        soft_fields    = fieldnames(typeof(Soft))
        for soft in soft_fields
            if !isnothing(getfield(Soft,soft))
                name = rpad(String(soft),15)
                comment = get_doc(Softening, soft)
                data = getfield(Soft,soft) 
                println(io,"        $name  = $(write_vec(data))     # $(comment)")
            end
        end

        println(io,"   <SofteningEnd>")
        println(io,"")
    end
    
    # Define materials 
    println(io, "# Define material properties for all phases (maximum 32)")
    println(io, "# By default all rheological mechanisms are deactivated")
    println(io, "# List only active parameters in the material data block")
    println(io,"")

    # Write material properties for the different phases
    for phase in d.Phases
        println(io, "    <MaterialStart>")
        phase_fields    = fieldnames(typeof(phase))
        for p in phase_fields
            if !isnothing(getfield(phase,p))
                name = rpad(String(p),15)
                comment = get_doc(Phase, p)
                data = getfield(phase,p) 
                println(io,"        $name  = $(write_vec(data))     # $(comment)")
            end
        end
        println(io,"    <MaterialEnd>")
        println(io,"")
    end

    # 

    println(io,"")
    return nothing
end