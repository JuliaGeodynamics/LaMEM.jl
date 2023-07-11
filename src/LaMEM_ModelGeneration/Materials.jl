# Specify Material properties
export Materials, Phase, Softening, PhaseTransition, Dike, Write_LaMEM_InputFile



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
    Defines phase transitions on markers (that change the Phase ID of a marker depending on some conditions)

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct PhaseTransition
    "Phase_transition law ID"
    ID::Int64                      =   0           

    "[Constant, Clapeyron, Box]: Constant - the phase transition occurs only at a fixed value of the parameter; Clapeyron - clapeyron slope"
    Type::String                    =   "Constant"      
    
    "Type of predefined Clapeyron slope, such as Mantle_Transition_660km"
    Name_Clapeyron::Union{Int64, Nothing}          =  nothing

    "box bound coordinates: [left, right, front, back, bottom, top]"
    PTBox_Bounds::Union{Vector{Float64}, Nothing} =   nothing   
    
    "1: only check particles in the vicinity of the box boundaries (2: in all directions)"
    BoxVicinity::Union{Int64, Nothing} 	        =	1								

    "[T = Temperature, P = Pressure, Depth = z-coord, X=x-coord, Y=y-coord, APS = accumulated plastic strain, MeltFraction, t = time] parameter that triggers the phase transition"
    Parameter_transition::String                =   "T"     

    "Value of the parameter [unit of T,P,z, APS] "        
    ConstantValue::Union{Float64, Nothing}      =   1200          

    "The number of involved phases [default=1]"
    number_phases::Union{Int64, Nothing}        =   1              

    "Above the chosen value the phase is 1, below it, the value is PhaseBelow"
    PhaseAbove::Union{Vector{Int64}, Nothing}   =   nothing              
    PhaseBelow::Union{Vector{Int64}, Nothing}   =   nothing               
    
    "Phase within the box  [use -1 if you don't want to change the phase inside the box]"
    PhaseInside::Union{Vector{Int64}, Nothing}  =   nothing

    "Phase outside the box [use -1 if you don't want to change the phase outside the box. If combined with OutsideToInside, all phases that come in are set to PhaseInside]"
    PhaseOutside::Union{Vector{Int64}, Nothing} =   nothing       

    "[BothWays=default; BelowToAbove; AboveToBelow] Direction in which transition works"
    PhaseDirection::String                      =   "BothWays"      

    "[APS] Parameter to reset on particles below PT or within box"
    ResetParam::String                          =   "APS"        
    
    "# Temperature condition witin the box [none, constant, linear, halfspace]"
    PTBox_TempType::String                      =   "linear"          
    
    "Temp @ top of box [for linear & halfspace] "               
    PTBox_topTemp::Union{Float64, Nothing}      =   nothing                        

    "Temp @ bottom of box [for linear & halfspace] "     
    PTBox_botTemp::Union{Float64, Nothing}      =   nothing                            
    
    "Thermal age, usually in geo-units [Myrs] [only in case of halfspace]"
    PTBox_thermalAge::Union{Float64, Nothing}   =   nothing        

    "Temp within box [only for constant T]"                     
    PTBox_cstTemp::Union{Float64, Nothing}      =   nothing                            

    "[optional] only for NotInAirBox, velocity with which box moves in cm/yr  "
    v_box::Union{Float64, Nothing}   =   nothing  

    "[optional] beginning time of movemen in Myr"
    t0_box::Union{Float64, Nothing}   =   nothing                    

    "[optional] end time of movement in Myr"
    t1_box::Union{Float64, Nothing}   =   nothing                         
end

function show(io::IO, d::PhaseTransition)
    println(io, "Phase Transition Law $(d.ID): ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) & (f != :ID) & (f != :Name)
            printstyled(io,"     $(rpad(String(f),20)) = $(getfield(d,f)) \n")        
        end
    end

    return nothing
end

function show_short(d::PhaseTransition)
    fields    = fieldnames(typeof(d))
    str = "PhaseTransition("
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
    Defines the properties related to inserting dikes

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Dike
    "Material phase ID"
    ID::Int64   = 0     

    "value for dike/magma- accommodated extension, between 0 and 1, in the front of the box, for phase dike" 
    Mf::Float64 = 0.5	

    "[optional] value for dike/magma- accommodate extension, between 0 and 1, for dike phase; M is linearly interpolated between Mf & Mc and Mc & Mb, if not set, Mc default is set to -1 so it is not used"
    Mc::Float64 = 0.5	   # 
	
    "[optional], location for Mc, must be between front and back boundaries of dike box, if not set, default value to 0.0, but not used"
    y_Mc::Union{Nothing,Float64} = 0.5 	   # 

    "value for dike/magma-accommodated extension, between 0 and 1, in the back of the box, for phase dike"    
    Mb::Union{Nothing,Float64} = 0.5           # 
        
    "Phase ID "
    PhaseID::Union{Nothing,Int64} = 0
	    
    "Phase transition ID "
    PhaseTransID::Union{Nothing,Int64} = 0
end

function show(io::IO, d::Dike)
    println(io, "Dike $(d.ID): ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) & (f != :ID) & (f != :Name)
            printstyled(io,"     $(rpad(String(f),12)) = $(getfield(d,f)) \n")        
        end
    end

    return nothing
end

function show_short(d::Dike)
    fields    = fieldnames(typeof(d))
    str = "Dike("
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
    Structure that contains the material properties in the current simulation
    
    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Materials
    "Different Materials implemented"
    Phases::Vector{Phase}               =	[Phase(ID=0, eta=1, rho=1)]

    "Softening laws implemented"
    SofteningLaws::Vector{Softening}    =	[]

    "Internal Phase Transitions (that change the ID of markers) implemented"
    PhaseTransitions::Vector{PhaseTransition}    =	[]

    "Dikes implemented (mostly for MOR simulations)"
    Dikes::Vector{Dike}             =	[]

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
            printstyled(io,"  $(rpad("Phases",15)) = $(str) \n", color=col)        
        else
            printstyled(io,"  $(rpad(" ",15)) = $(str) \n", color=col)        
        end
    end

    # print softening laws fields
    softening = d.SofteningLaws;
    col = gettext_color(d,Reference, :SofteningLaws)
    for (i,soft) in enumerate(softening)
        str = show_short(soft)
        if i==1
            printstyled(io,"  $(rpad("Softening",15)) = $(str) \n", color=col)        
        else
            printstyled(io,"  $(rpad(" ",15)) = $(str) \n", color=col)        
        end
    end
    if length(softening)==0
        printstyled(io,"  $(rpad("Softening",15)) = \n", color=:default)        
    end

    # print Phase Transitions laws fields
    phasetransitions = d.PhaseTransitions;
    col = gettext_color(d,Reference, :PhaseTransitions)
    for (i,phasetrans) in enumerate(phasetransitions)
        str = show_short(phasetrans)
        if i==1
            printstyled(io,"  $(rpad("PhaseTransition",15)) = $(str) \n", color=col)        
        else
            printstyled(io,"     $(rpad(" ",15)) = $(str) \n", color=col)        
        end
    end
    if length(phasetransitions)==0
        printstyled(io,"  $(rpad("PhaseTransition",15)) = \n", color=:default)        
    end

    # print Phase Transitions laws fields
    dikes = d.Dikes;
    col = gettext_color(d,Reference, :Dikes)
    for (i,dike) in enumerate(dikes)
        str = show_short(dike)
        if i==1
            printstyled(io,"  $(rpad("Dikes",15)) = $(str) \n", color=col)        
        else
            printstyled(io,"  $(rpad(" ",15)) = $(str) \n", color=col)        
        end
    end
    #if length(dikes)==0
    #    printstyled(io,"  $(rpad("Dikes",15)) = \n", color=:default)        
    #end

    return nothing
end

function show_short(io::IO, d::Materials)
    str = "|-- Materials           :  $(length(d.Phases)) phases; "
    if length(d.SofteningLaws)>0
        str = str*"$(length(d.SofteningLaws)) softening laws; "
    end
    if length(d.PhaseTransitions)>0
        str = str*"$(length(d.PhaseTransitions)) phase transitions; "
    end
    if length(d.Dikes)>0
        str = str*"$(length(d.Dikes)) dikes; "
    end
    println(io,str)

    return nothing
end


"""
    Write_LaMEM_InputFile(io, d::Output)
Writes the free surface related parameters to file
"""
function Write_LaMEM_InputFile(io, d::Materials)

    println(io, "#===============================================================================")
    println(io, "# Material phase parameters")
    println(io, "#===============================================================================")
    println(io,"")

    # Define softening laws
    println(io, "   # Define softening laws (maximum 10)")
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
    
    # Define PhaseTransitions laws
    println(io, "   # Define Phase Transition laws (maximum 10)")
    for PT in d.PhaseTransitions
      
        println(io, "   <PhaseTransitionStart>")
        
        pt_fields    = fieldnames(typeof(PT))
        for pt in pt_fields
            if !isnothing(getfield(PT,pt))
                name = rpad(String(pt),15)
                comment = get_doc(PhaseTransition, pt)
                data = getfield(PT,pt) 
                println(io,"        $name  = $(write_vec(data))     # $(comment)")
            end
        end

        println(io,"   <PhaseTransitionEnd>")
        println(io,"")
    end
    
    # Define Dikes parameters
    if length(d.Dikes)>0
        println(io, "   # Define properties for the dike (additional source term/RHS in the continuity equation):   ")
        println(io, "   # Define the associated phase, the amount of magma-accommodated extension on the front (Mf) and on the back (Mb) of the box and set its ID")
    end
    for dike in d.Dikes
        println(io, "   <DikeStart>")
        
        dike_fields    = fieldnames(typeof(dike))
        for pt in dike_fields
            if !isnothing(getfield(dike, pt))
                name = rpad(String(pt),15)
                comment = get_doc(Dike, pt)
                data = getfield(dike,pt) 
                println(io,"        $name  = $(write_vec(data))     # $(comment)")
            end
        end

        println(io,"   <DikeEnd>")
        println(io,"")
    end

    # Define materials 
    println(io, "   # Define material properties for all phases (maximum 32)")
    println(io, "   # By default all rheological mechanisms are deactivated")
    println(io, "   # List only active parameters in the material data block")
    println(io,"")

    # Write material properties for the different phases
    for phase in d.Phases
        println(io, "   <MaterialStart>")
        phase_fields    = fieldnames(typeof(phase))
        for p in phase_fields
            if !isnothing(getfield(phase,p))
                name = rpad(String(p),15)
                comment = get_doc(Phase, p)
                data = getfield(phase,p) 
                println(io,"        $name  = $(write_vec(data))     # $(comment)")
            end
        end
        println(io,"   <MaterialEnd>")
        println(io,"")
    end
    println(io,"")
    
    return nothing
end