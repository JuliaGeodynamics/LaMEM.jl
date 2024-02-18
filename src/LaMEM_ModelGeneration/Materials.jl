# Specify Material properties
using GeoParams
export Materials, Phase, Softening, PhaseAggregate, PhaseTransition, Dike, Write_LaMEM_InputFile


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

    "material ID for phase visualization (default is ID)"
    visID::Union{Nothing,Int64}      = nothing     

    """
    Build-in DIFFUSION creep profiles:
    
    Example: `"Dry__Olivine_diff_creep-Hirth_Kohlstedt_2003"`
    
    Available build-in diffusion creep rheologies are:
    
    1) From [Hirth, G. and Kohlstedt D. (2003), Rheology of the upper mantle and the mantle wedge: A view from the experimentalists]:

    - `"Dry_Olivine_diff_creep-Hirth_Kohlstedt_2003"`
    - `"Wet_Olivine_diff_creep-Hirth_Kohlstedt_2003_constant_C_OH"`
    - `"Wet_Olivine_diff_creep-Hirth_Kohlstedt_2003"`

    2) From [Rybacki and Dresen, 2000, JGR]:
    - `"Dry_Plagioclase_RybackiDresen_2000"`
    - `"Wet_Plagioclase_RybackiDresen_2000"`

    Note that you can always specify your own, by setting `Bd`, `Ed`, `Vd` accordingly.
    """
    diff_prof::Union{Nothing,String}  = nothing

    """
    Build-in DISLOCATION creep profiles: 
    
    Example: `"Granite-Tirel_et_al_2008"`

    Available build-in dislocation creep rheologies are:
    
    1) From [Ranalli 1995]:

    - `"Dry_Olivine-Ranalli_1995"`
    - `"Wet_Olivine-Ranalli_1995"`
    - `"Wet_Quarzite-Ranalli_1995"`
    - `"Quarzite-Ranalli_1995"`
    - `"Mafic_Granulite-Ranalli_1995"`
    - `"Plagioclase_An75-Ranalli_1995"`

    2) From [Carter and Tsenn (1986). Flow properties of continental lithosphere - page 18]:
    
    - `"Quartz_Diorite-Hansen_Carter_1982"`
    
    3) From [J. de Bremond d'Ars et al. Tectonophysics (1999). Hydrothermalism and Diapirism in the Archaean: gravitational instability constrains. - page 5]

    - `"Diabase-Caristan_1982"`
    - `"Tumut_Pond_Serpentinite-Raleigh_Paterson_1965"`

    4) From [Mackwell, Zimmerman & Kohlstedt (1998). High-temperature deformation]:
    
    - `"Maryland_strong_diabase-Mackwell_et_al_1998"`

    5) From [Ueda et al (PEPI 2008)]:

    - `"Wet_Quarzite-Ueda_et_al_2008"`
    
    6) From [Huismans et al 2001]:

    - `"Diabase-Huismans_et_al_2001"`
    - `"Granite-Huismans_et_al_2001"`
    
    7) From [Burg And Podladchikov (1999)]:

    - `"Dry_Upper_Crust-Schmalholz_Kaus_Burg_2009"`
    - `"Weak_Lower_Crust-Schmalholz_Kaus_Burg_2009"`
    - `"Olivine-Burg_Podladchikov_1999"`
    
    8) From [Rybacki and Dresen, 2000, JGR]:

    - `"Dry_Plagioclase_RybackiDresen_2000"`
    - `"Wet_Plagioclase_RybackiDresen_2000"`

    9) From [Hirth, G. & Kohlstedt (2003), D. Rheology of the upper mantle and the mantle wedge: A view from the experimentalists]:

    - `"Wet_Olivine_disl_creep-Hirth_Kohlstedt_2003"`
    - `"Wet_Olivine_disl_creep-Hirth_Kohlstedt_2003_constant_C_OH"`
    - `"Dry_Olivine_disl_creep-Hirth_Kohlstedt_2003"`

    10) From [SchmalholzKausBurg(2009), Geology (wet olivine)]:

    - `"Wet_Upper_Mantle-Burg_Schmalholz_2008"`
    - `"Granite-Tirel_et_al_2008"`

    11) From [Urai et al.(2008)]:

    - `"Ara_rocksalt-Urai_et_al.(2008)"`

    12) From [Bräuer et al. (2011) Description of the Gorleben site (PART 4): Geotechnical exploration of the Gorleben salt dome - page 126]:

    - `"RockSaltReference_BGRa_class3-Braeumer_et_al_2011"`

    13) From [Mueller and Briegel (1978)]:

    - `"Polycrystalline_Anhydrite-Mueller_and_Briegel(1978)"`

    Note that you can always specify your own, by setting `Bn`, `En`, `Vn`, and `n` accordingly.
    """
    disl_prof::Union{Nothing,String}  = nothing                    

    """
    Build-in PEIERLS creep profiles:

    example:  `"Olivine_Peierls-Kameyama_1999"`

    Available profiles:
    - `"Olivine_Peierls-Kameyama_1999"`

    """
    peir_prof::Union{Nothing,String}  = nothing               

    "depth-dependent density model parameter"
    rho_n::Union{Nothing,Float64}       = nothing   

    "depth-dependent density model parameter"
    rho_c::Union{Nothing,Float64}       = nothing   

    "pressure-dependent density model parameter"
    beta::Union{Nothing,Float64}       = nothing   

    "shear modulus"
    G::Union{Nothing,Float64}       = nothing   

    "bulk modulus"
    Kb::Union{Nothing,Float64}       = nothing   

    "Young's modulus"
    E::Union{Nothing,Float64}       = nothing   

    "Poisson's ratio"
    nu::Union{Nothing,Float64}       = nothing   

    "pressure dependence parameter"
    Kp::Union{Nothing,Float64}       = nothing   

    "DIFFUSION creep pre-exponential constant"
    Bd::Union{Nothing,Float64}       = nothing   

    "activation energy"
    Ed::Union{Nothing,Float64}       = nothing   

    "activation volume"
    Vd::Union{Nothing,Float64}       = nothing   

    "POWER LAW reference viscosity"
    eta0::Union{Nothing,Float64}       = nothing   

    "reference strain rate"
    e0 ::Union{Nothing,Float64}       = nothing   

    "DISLOCATION creep pre-exponential constant"
    Bn::Union{Nothing,Float64}       = nothing   

    "activation energy"
    En::Union{Nothing,Float64}       = nothing   

    "activation volume"
    Vn::Union{Nothing,Float64}       = nothing   

    "power law exponent"
    n::Union{Nothing,Float64}       = nothing   

    "PEIERLS creep pre-exponential constant"
    Bp::Union{Nothing,Float64}       = nothing   

    "activation energy"
    Ep::Union{Nothing,Float64}       = nothing   

    "activation volume"
    Vp::Union{Nothing,Float64}       = nothing   

    "scaling stress"
    taup::Union{Nothing,Float64}       = nothing   

    "approximation parameter"
    gamma::Union{Nothing,Float64}       = nothing   

    "stress-dependence parameter"
    q ::Union{Nothing,Float64}       = nothing   

    "reference viscosity for Frank-Kamenetzky viscosity"
    eta_fk::Union{Nothing,Float64}       = nothing   

    "gamma parameter for Frank-Kamenetzky viscosity"
    gamma_fk::Union{Nothing,Float64}       = nothing   

    "reference Temperature for Frank-Kamenetzky viscosity (if not set it is 0°C)"
    TRef_fk::Union{Nothing,Float64}       = nothing   

    "cohesion"
    ch::Union{Nothing,Float64}       = nothing   

    "friction angle"
    fr::Union{Nothing,Float64}       = nothing   

    "stabilization viscosity (default is eta_min)"
    eta_st::Union{Nothing,Float64}       = nothing   

    "viscoplastic plasticity regularisation viscosity"
    eta_vp::Union{Nothing,Float64}       = nothing   

    "pore-pressure ratio"
    rp::Union{Nothing,Float64}       = nothing   

    "friction softening law ID"
    chSoftID::Union{Nothing,Int64}       = nothing   

    "cohesion softening law ID"
    frSoftID::Union{Nothing,Int64}       = nothing  

    "healing ID, points to healTau in Softening"
    healID::Union{Nothing,Int64}       = nothing  

    "thermal expansivity"
    alpha::Union{Nothing,Float64}       = nothing 

    "specific heat (capacity), J⋅K−1⋅kg−1"
    Cp::Union{Nothing,Float64}       = nothing 

    "thermal conductivity"
    k::Union{Nothing,Float64}       = nothing 

    "radiogenic heat production"
    A::Union{Nothing,Float64}       = nothing 

    "optional temperature to set within the phase"
    T::Union{Nothing,Float64}       = nothing 

    "optional, used for dike heating, J/kg"
    Latent_hx::Union{Nothing,Float64}       = nothing 

    "optional, used for dike heating, liquidus temperature of material, celsius"
    T_liq::Union{Nothing,Float64}       = nothing 

    "optional, used for dike heating, solidus temperature of material, celsius"
    T_sol::Union{Nothing,Float64}       = nothing 

    "default value for thermal conductivity boundary"
    T_Nu::Union{Nothing,Float64}       = nothing 

    "optional parameter, Nusselt number for use with conductivity"
    nu_k::Union{Nothing,Float64}       = nothing 

    "name of the phase diagram you want to use (still needs rho to be defined for the initial guess of pressure)"
    rho_ph::Union{Nothing,String}     = nothing

    "in case the phase diagram has a different path provide the path (without the name of the actual PD) here"
    rho_ph_dir::Union{Nothing,String}     = nothing

    "melt fraction viscosity correction factor (positive scalar)"
    mfc::Union{Nothing,Float64}       = nothing 

    """
    GeoParams creeplaws 
    
    Set diffusion or dislocation creeplaws as provided by the GeoParams package:
    
    ```julia
    julia> using GeoParams
    julia> a = SetDiffusionCreep(GeoParams.Diffusion.dry_anorthite_Rybacki_2006);
    julia> p = Phase(ID=1,Name="test", GeoParams=[a]);
    ```
    Note that GeoParams should be a vector, as you could, for example, have diffusion and dislocation creep parameters
    
    Note also that this will overwrite any other creeplaws provided in the Phase struct.
    """
    GeoParams::Union{Nothing,Vector{AbstractCreepLaw}}       = nothing 
end


function add_geoparams_rheologies(phase::Phase)
    if !isnothing(phase.GeoParams)
        # NOTE: this needs checking; likely that B in LaMEM is defined differently!
        println("GeoParamsExt: adding creeplaw params")
        for ph in phase.GeoParams
            if isa(ph, DiffusionCreep)
                phase.Bd = ph.A
                phase.Ed = ph.E
                phase.Vd = ph.V
            elseif isa(ph, DislocationCreep)
                phase.Bn = ph.A
                phase.En = ph.E
                phase.Vn = ph.V
                phase.n  = ph.n
            end
        end
    end
    return phase
end

function show(io::IO, d::Phase)
    println(io, "Phase $(d.ID) ($(d.Name)): ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) & (f != :ID) & (f != :Name) & (f != :GeoParams)
            printstyled(io,"  $(rpad(String(f),9)) = $(getfield(d,f)) \n")        
        end

        # if we have GeoParams creep data, print it differently
        if f == :GeoParams && !isnothing(getfield(d,f))
            g = getfield(d,f);
            names = "["
            for i=1:length(g)
                name = GeoParams.uint2str(g[i].Name)
                names = names*"$(name); "
            end
            names = names*"]"
            printstyled(io,"  $(rpad(String(f),9)) = $names \n")        
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
    Lm::Union{Nothing,Float64}          =   nothing   
    
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
    Defines phase aggregates, which can be useful for visualization purposes

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct PhaseAggregate
    "Name of the phase aggregate"
    name::String    =   "Crust"    

    "Phases to be combined"
    phaseID::Union{Nothing, Vector{Int64}} =   nothing
    
    "number of aggregated phases"
    numPhase::Union{Nothing,Int64} =   nothing 
    
end

function show(io::IO, d::PhaseAggregate)
    println(io, "PhaseAggregate $(d.name): ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) & (f != :numPhase) & (f != :name)
            printstyled(io,"  $(rpad(String(f),6)) = $(getfield(d,f)) \n")        
        end
    end

    return nothing
end

function show_short(d::PhaseAggregate)
    fields    = fieldnames(typeof(d))
    str = "PhaseAggregate("
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
    Name_Clapeyron::Union{String, Nothing}          =  nothing

    "box bound coordinates: [left, right, front, back, bottom, top]"
    PTBox_Bounds::Union{Vector{Float64}, Nothing} =   nothing   
    
    "1: only check particles in the vicinity of the box boundaries (2: in all directions)"
    BoxVicinity::Union{Int64, Nothing} 	        =	nothing								

    "[T = Temperature, P = Pressure, Depth = z-coord, X=x-coord, Y=y-coord, APS = accumulated plastic strain, MeltFraction, t = time] parameter that triggers the phase transition"
    Parameter_transition::Union{String, Nothing}   =   nothing   

    "Value of the parameter [unit of T,P,z, APS] "        
    ConstantValue::Union{Float64, Nothing}      =   nothing          

    "The number of involved phases [default=1]"
    number_phases::Union{Int64, Nothing}        =   1              

    "Above the chosen value the phase is 1, below it, the value is PhaseBelow"
    PhaseAbove::Union{Vector{Int64}, Nothing}   =   nothing       
    
    "Below the chosen value the phase is PhaseBelow, above it, the value is 1"
    PhaseBelow::Union{Vector{Int64}, Nothing}   =   nothing               
    
    "Phase within the box  [use -1 if you don't want to change the phase inside the box]"
    PhaseInside::Union{Vector{Int64}, Nothing}  =   nothing

    "Phase outside the box [use -1 if you don't want to change the phase outside the box. If combined with OutsideToInside, all phases that come in are set to PhaseInside]"
    PhaseOutside::Union{Vector{Int64}, Nothing} =   nothing       

    "[BothWays=default; BelowToAbove; AboveToBelow] Direction in which transition works"
    PhaseDirection::Union{String, Nothing}      =   nothing 

    "[APS] Parameter to reset on particles below PT or within box"
    ResetParam::Union{String, Nothing}          =  nothing  
    
    "# Temperature condition witin the box [none, constant, linear, halfspace]"
    PTBox_TempType::Union{String, Nothing}      =   nothing         
    
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
    
    "[optional] clapeyron slope of phase transition [in K/MPa]; P=(T-T0_clapeyron)*clapeyron_slope + P0_clapeyron "
    clapeyron_slope::Union{Float64, Nothing}   =   nothing   
    
    "[optional] P0_clapeyron [Pa]"
    P0_clapeyron::Union{Float64, Nothing}   =   nothing   
    
    "[optional] T0_clapeyron [C]"
    T0_clapeyron::Union{Float64, Nothing}   =   nothing   
    
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
    Phases::Vector{Phase}               =	[]

    "Softening laws implemented"
    SofteningLaws::Vector{Softening}    =	[]

    "Internal Phase Transitions (that change the ID of markers) implemented"
    PhaseTransitions::Vector{PhaseTransition}    =	[]

    "Dikes implemented (mostly for MOR simulations)"
    Dikes::Vector{Dike}             =	[]

    "Phase aggregates (combines different phases such as upper_lower crust into one for visualization purposes)"
    PhaseAggregates::Vector{PhaseAggregate} = []
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

    # print phase aggregates fields
    phaseaggregates = d.PhaseAggregates;
    col = gettext_color(d,Reference, :PhaseAggregates)
    for (i,phaseaggregate) in enumerate(phaseaggregates)
        str = show_short(phaseaggregate)
        if i==1
            printstyled(io,"  $(rpad("PhaseAggregate",15)) = $(str) \n", color=col)        
        else
            printstyled(io,"  $(rpad(" ",15)) = $(str) \n", color=col)        
        end
    end
    if length(phaseaggregates)==0
        printstyled(io,"  $(rpad("PhaseAggregate",15)) = \n", color=:default)        
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

    # print Dike fields
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
    if length(d.PhaseAggregates)>0
        str = str*"$(length(d.PhaseAggregates)) phase aggregates "
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
    
    # Define phase aggregates
    println(io, "   # Define phase aggregates (for visualization purposes)")
    for PhaseAgg in d.PhaseAggregates
        if isnothing(PhaseAgg.numPhase)
            PhaseAgg.numPhase = length(PhaseAgg.phaseID)
        end
        println(io, "   <PhaseAggStart>")
        
        phaseaggregate_fields    = fieldnames(typeof(PhaseAgg))
        for phaseaggregate in phaseaggregate_fields
            if !isnothing(getfield(PhaseAgg,phaseaggregate))
                name = rpad(String(phaseaggregate),15)
                comment = get_doc(PhaseAggregate, phaseaggregate)
                data = getfield(PhaseAgg,phaseaggregate) 
                println(io,"        $name  = $(write_vec(data))     # $(comment)")
            end
        end

        println(io,"   <PhaseAggEnd>")
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
                comment = split(comment,"\n")[1]
                data = getfield(phase,p) 
                println(io,"        $name  = $(write_vec(data))     # $(comment)")
            end
        end
        println(io,"   <MaterialEnd>")
        println(io,"")
    end
    println(io,"")

    # Define PhaseTransitions laws
    println(io, "#===============================================================================")
    println(io, "# Define phase transitions")
    println(io, "#===============================================================================")
    println(io,"")

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


    return nothing
end