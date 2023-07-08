#Solution Parameters

export SolutionParams, SolutionParams_info, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM solution parameters information. 

"""
Base.@kwdef mutable struct SolutionParams
    
    gravity::Vector{Float64} = [0.0, 0.0, -10.0]  # gravity vector
    FSSA::Float64            = 1.0            # free surface stabilization parameter [0 - 1]
    shear_heat_eff::Float64  = 1.0            # shear heating efficiency parameter   [0 - 1]
    Adiabatic_Heat::Float64  = 0.0            # Adiabatic Heating activaction flag and efficiency. [0.0 - 1.0] (e.g. 0.5 means that only 50% of the potential adiabatic heating affects the energy equation)   
    act_temp_diff::Int64   = 1              # temperature diffusion activation flag
    act_therm_exp::Int64   = 1              # thermal expansion activation flag
    act_steady_temp::Int64 = 1              # steady-state temperature initial guess activation flag
    steady_temp_t::Float64   = 0.0            # time for (quasi-)steady-state temperature initial guess
    nstep_steady::Int64    = 1              # number of steps for (quasi-)steady-state temperature initial guess (default = 1)
    act_heat_rech::Int64   = 1              # recharge heat in anomalous bodies after (quasi-)steady-state temperature initial guess (=2: recharge after every diffusion step of initial guess)
    init_lith_pres::Int64  = 1              # initial pressure with lithostatic pressure (stabilizes compressible setups in the first steps)
    init_guess::Int64      = 1              # initial guess flag
    p_litho_visc::Int64    = 1              # use lithostatic pressure for creep laws
    p_litho_plast::Int64   = 1              # use lithostatic pressure for plasticity
    p_lim_plast::Int64     = 1              # limit pressure at first iteration for plasticity
    p_shift::Int64 		= 0              # constant [MPa] added to the total pressure field, before evaluating plasticity (e.g., when the domain is located @ some depth within the crust)  	
    act_p_shift::Int64     = 1              # pressure shift activation flag (enforce zero pressure on average in the top cell layer); note: this overwrites p_shift above!
    
    eta_min::Float64         = 1e18           # viscosity lower bound [Pas]
    eta_max::Float64         = 1e25           # viscosity upper limit [Pas]
    eta_ref::Float64         = 1e20           # reference viscosity (initial guess) [Pas]
    T_ref::Float64           = 20.0           # reference temperature [C]
    RUGC::Float64            = 8.31           # universal gas constant (required only for non-dimensional setups)
    min_cohes::Float64       = 2e7            # cohesion lower bound  [Pa]
    min_fric::Float64        = 5.0            # friction lower bound  [degree]
    tau_ult::Float64         = 1e9            # ultimate yield stress [Pa]
    rho_fluid::Float64       = 1e3            # fluid density for depth-dependent density model
    gw_level_type::String    = "top"            # ground water level type for pore pressure computation (see below)
    gw_level::Float64        = 10.0           # ground water level at the free surface (if defined)
    biot::Float64            = 0.7            # Biot pressure parameter
    get_permea::Float64      = 1              # effective permeability computation activation flag
    rescal::Float64          = 1              # stencil rescaling flag (for internal constraints, for example while computing permeability)
    mfmax::Float64           = 0.1            # maximum melt fraction affecting viscosity reduction
    lmaxit::Int64          = 25               # maximum number of local rheology iterations 
    lrtol::Float64           = 1e-6           # local rheology iterations relative tolerance
    act_dike::Int64        = 1               # dike activation flag (additonal term in divergence)
    useTk::Int64           = 1               # switch to use T-dependent conductivity, 0: not active
    dikeHeat::Int64        = 1		         # switch to use Behn & Ito heat source in the dike
    Compute_velocity_gradient::Int64 = 1     # compute the velocity gradient tensor 1: active, 0: not active. If active, it automatically activates the output in the .pvd file
    
end


# Strings that explain 
Base.@kwdef struct SolutionParams_info
    gravity::String = "gravity vector"
    FSSA::String            = "free surface stabilization parameter [0 - 1]"
    shear_heat_eff::String  = "shear heating efficiency parameter   [0 - 1]"
    Adiabatic_Heat::String  = "Adiabatic Heating activaction flag and efficiency. [0.0 - 1.0] (e.g. 0.5 means that only 50% of the potential adiabatic heating affects the energy equation)   "
    act_temp_diff::String   =  "temperature diffusion activation flag"
    act_therm_exp::String   = "thermal expansion activation flag"
    act_steady_temp::String = "steady-state temperature initial guess activation flag"
    steady_temp_t::String   = "time for (quasi-)steady-state temperature initial guess"
    nstep_steady::String    = "number of steps for (quasi-)steady-state temperature initial guess (default = 1)"
    act_heat_rech::String   = "recharge heat in anomalous bodies after (quasi-)steady-state temperature initial guess (=2: recharge after every diffusion step of initial guess)"
    init_lith_pres::String  = "initial pressure with lithostatic pressure (stabilizes compressible setups in the first steps)"
    init_guess::String      = "initial guess flag"
    p_litho_visc::String    = "use lithostatic pressure for creep laws"
    p_litho_plast::String   = "use lithostatic pressure for plasticity"
    p_lim_plast::String     = "limit pressure at first iteration for plasticity"
    p_shift::String 		   = "constant [MPa] added to the total pressure field, before evaluating plasticity (e.g., when the domain is located @ some depth within the crust)  	"
    act_p_shift::String     = "pressure shift activation flag (enforce zero pressure on average in the top cell layer); note: this overwrites p_shift above!"
    
    eta_min::String         = "viscosity lower bound [Pas]"
    eta_max::String         = "viscosity upper limit [Pas]"
    eta_ref::String         = "reference viscosity (initial guess) [Pas]"
    T_ref::String           = "reference temperature [C]"
    RUGC::String            = "universal gas constant (required only for non-dimensional setups)"
    min_cohes::String       = "cohesion lower bound  [Pa]"
    min_fric::String        = "friction lower bound  [degree]"
    tau_ult::String         =  "ultimate yield stress [Pa]"
    rho_fluid::String       = "fluid density for depth-dependent density model"
    gw_level_type::String    = "ground water level type for pore pressure computation (see below)"
    gw_level::String        = "ground water level at the free surface (if defined)"
    biot::String            = "Biot pressure parameter"
    get_permea::String      = "effective permeability computation activation flag"
    rescal::String          =" stencil rescaling flag (for internal constraints, for example while computing permeability)"
    mfmax::String           = "maximum melt fraction affecting viscosity reduction"
    lmaxit::String            = " maximum number of local rheology iterations "
    lrtol::String           = "local rheology iterations relative tolerance"
    useTk::String             = "switch to use T-dependent conductivity, 0: not active"
    dikeHeat::String          = "switch to use Behn & Ito heat source in the dike"
    Compute_velocity_gradient::String = "compute the velocity gradient tensor 1: active, 0: not active. If active, it automatically activates the output in the .pvd file"
end


# Print info about the structure
function show(io::IO, d::SolutionParams)
    Reference = SolutionParams();    # reference values
    println(io, "LaMEM Solution parameters : ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),15)) = $(getfield(d,f)) \n", color=col)        
    end
    
    return nothing
end

function show_short(io::IO, d::SolutionParams)
    println(io,"|-- Solution parameters :  ")
    return nothing
end



"""
    Write_LaMEM_InputFile(io, d::SolutionParams)
Writes the boundary conditions related parameters to file
"""
function Write_LaMEM_InputFile(io, d::SolutionParams)
    Reference = SolutionParams();    # reference values
    Info      = SolutionParams_info()
    fields    = fieldnames(typeof(d))
    
    println(io, "#===============================================================================")
    println(io, "# Solution parameters & controls")
    println(io, "#===============================================================================")
    println(io,"")

    for f in fields
        if getfield(d,f) != getfield(Reference,f) 
            # only print if value differs from reference value
            name = rpad(String(f),15)
            comment = getfield(Info,f) 
            data = getfield(d,f) 
            println(io,"    $name  = $(write_vec(data))     # $(comment)")
        end
    end

    println(io,"")
    return nothing
end
