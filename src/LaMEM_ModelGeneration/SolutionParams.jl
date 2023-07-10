#Solution Parameters

# Capture meta-data with:
# Docs.meta(LaMEM.LaMEM_Model)[Docs.@var(LaMEM.LaMEM_Model.SolutionParams)].docs[Union{}].data

export SolutionParams, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM global solution parameters. 

    $(TYPEDFIELDS)

"""
Base.@kwdef mutable struct SolutionParams
    "gravitational acceleration vector"
    gravity::Vector{Float64} = [0.0, 0.0, -9.81] 

    """
    free surface stabilization parameter [0 - 1]; The value has to be between 0 and 1
    """
    FSSA::Float64            = 1.0         

    "shear heating efficiency parameter   [0 - 1]"   
    shear_heat_eff::Float64  = 1.0             
    
    "Adiabatic Heating activation flag and efficiency. [0.0 - 1.0] (e.g. 0.5 means that only 50% of the potential adiabatic heating affects the energy equation)"
    Adiabatic_Heat::Float64  = 0.0    
    
    "temperature diffusion activation flag"
    act_temp_diff::Int64   = 1        

    "thermal expansion activation flag"
    act_therm_exp::Int64   = 1              
    
    "steady-state temperature initial guess activation flag"
    act_steady_temp::Int64 = 1        
    
    "time for (quasi-)steady-state temperature initial guess"
    steady_temp_t::Float64   = 0.0           

    "number of steps for (quasi-)steady-state temperature initial guess (default = 1)"
    nstep_steady::Int64    = 1               
    
    "recharge heat in anomalous bodies after (quasi-)steady-state temperature initial guess (=2: recharge after every diffusion step of initial guess)"
    act_heat_rech::Int64   = 1               

    "sets initial pressure to be the lithostatic pressure (stabilizes compressible setups in the first steps)"
    init_lith_pres::Int64  = 1       
    
    "create an initial guess step (using constant viscosity `eta_ref` before starting the simulation"
    init_guess::Int64      = 1              

    "use lithostatic instead of dynamic pressure for creep laws"
    p_litho_visc::Int64    = 1              
    
    "use lithostatic pressure for plasticity"
    p_litho_plast::Int64   = 1         

    "limit pressure at first iteration for plasticity"      
    p_lim_plast::Int64     = 1              
    
    "add a constant value [MPa] to the total pressure field, before evaluating plasticity (e.g., when the domain is located @ some depth within the crust)  	"
    p_shift::Int64 		    = 0              
    "pressure shift activation flag (enforce zero pressure on average in the top cell layer); note: this overwrites p_shift above!"
    act_p_shift::Int64       = 1 

    "viscosity lower bound [Pas]"
    eta_min::Float64         = 1e18        
    
    "viscosity upper limit [Pas]   "
    eta_max::Float64         = 1e25         
    
    "Reference viscosity (used for the initial guess) [Pas]"
    eta_ref::Float64         = 1e20      
     
    "Reference temperature [C]"
    T_ref::Float64           = 20.0          
    
    "universal gas constant (you need to change this only for non-dimensional setups)"
    RUGC::Float64            = 8.31  
    
    "cohesion lower bound  [Pa]"
    min_cohes::Float64       = 2e7           
    
    "friction lower bound  [degree]"
    min_fric::Float64        = 5.0      
     
    "ultimate yield stress [Pa]     "
    tau_ult::Float64         = 1e9        
    
    "fluid density for depth-dependent density model"
    rho_fluid::Float64       = 1e3      
    
    "ground water level type for pore pressure computation (see below)"
    gw_level_type::String    = "top"          
    
    "ground water level at the free surface (if defined)"
    gw_level::Float64        = 10.0       
    
    "Biot pressure parameter"
    biot::Float64            = 0.7            
    
    "effective permeability computation activation flag"
    get_permea::Float64      = 1             
    
    "stencil rescaling flag (for internal constraints, for example while computing permeability)"
    rescal::Float64          = 1             
    
    "maximum melt fraction affecting viscosity reduction"
    mfmax::Float64           = 0.1            
    
    "maximum number of local rheology iterations "
    lmaxit::Int64          = 25              
    
    "local rheology iterations relative tolerance"
    lrtol::Float64          = 1e-6         
    
    "dike activation flag (additonal term in divergence)  "
    act_dike::Int64         = 1               
    
    "switch to use T-dependent conductivity, 0: not active"
    useTk::Int64            = 1              
    
    "switch to use Behn & Ito heat source in the dike "
    dikeHeat::Int64         = 1		        

    "compute the velocity gradient tensor 1: active, 0: not active. If active, it automatically activates the output in the .pvd file"
    Compute_velocity_gradient::Int64 = 1     
    
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
    fields    = fieldnames(typeof(d))
    
    println(io, "===============================================================================")
    println(io, " Solution parameters & controls")
    println(io, "===============================================================================")
    println(io,"")

    for f in fields
        if getfield(d,f) != getfield(Reference,f) 
            # only print if value differs from reference value
            name = rpad(String(f),15)
            data = getfield(d,f) 
            help_string  = get_doc(SolutionParams, f)
            println(io,"    $name  = $(write_vec(data))     # $(help_string)")
        end
    end

    println(io,"")
    return nothing
end
