# related to timestepping

export Time, write_LaMEM_inputFile

"""
    Structure that contains the LaMEM timestepping information. An explanation of the paramneters is given in the struct `Time_info`

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Time
    "simulation end time"
    time_end::Float64  = 1.0      

    "initial time step"
    dt::Float64        = 0.05     

    "minimum time step (declare divergence if lower value is attempted)"
    dt_min:: Float64   = 0.01     

    "maximum time step"
    dt_max::Float64    = 0.2      

    "output step (output at least at fixed time intervals)"
	dt_out::Float64    = 0.2      

    "time step increment per time step (fraction of unit)"
	inc_dt::Float64    = 0.1      

    "CFL (Courant-Friedrichs-Lewy) criterion"
	CFL::Float64       = 0.5      

    "CFL criterion for elasticity"
	CFLMAX::Float64    = 0.8      

    "maximum allowed number of steps (lower bound: time_end/dt_max)"
	nstep_max::Int64   = 50       

    "save output every n steps; Set this to -1 to deactivate saving output"
	nstep_out::Int64   = 1        

    "save restart database every n steps"
	nstep_rdb::Int64   = 100      

    "number of time stepping periods"
    num_dt_periods::Int64 = 0     

    "timestamps where timestep should be fixed (first entry has to 0)"
    time_dt_periods::Vector{Int64} = []     

    "target timesteps ar timestamps above"
    step_dt_periods::Vector{Float64} = []   

    "save output for n initial steps"
    nstep_ini::Int64   = 1            

    "relative tolerance for time comparisons"
    time_tol::Float64  = 1e-8        
end

# Print info about the structure
function show(io::IO, d::Time)
    Reference = Time();    # reference values
    println(io, "LaMEM Timestepping parameters: ")
    fields         = fieldnames(typeof(d))

    # Do we have multiple timestepping periods? 
    num_dt_periods = d.num_dt_periods   
    if num_dt_periods==0
        fields = filter_fields(fields, (:num_dt_periods, :time_dt_periods, :step_dt_periods))
    end

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),15)) = $(getfield(d,f)) \n", color=col)        
    end
  
    return nothing
end

function show_short(io::IO, d::Time)
    println(io,"|-- Time                :  nstep_max=$(d.nstep_max); nstep_out=$(d.nstep_out); time_end=$(d.time_end); dt=$(d.dt)")
    return nothing
end



"""
Writes the Time related parameters to file
"""
function write_LaMEM_inputFile(io, d::Time)
    Reference = Time();    # reference values
    fields    = fieldnames(typeof(d))

    println(io, "#===============================================================================")
    println(io, "# Time stepping parameters")
    println(io, "#===============================================================================")
    println(io,"")

    for f in fields
        if getfield(d,f) != getfield(Reference,f) ||
            (f == :dt_max)  ||  
            (f == :time_end) ||
            (f == :nstep_max)
            

            # only print if value differs from reference value
            name = rpad(String(f),15)
            comment = get_doc(Time, f)
            data = getfield(d,f) 
            
            println(io,"    $name  = $(write_vec(data))     # $(comment)")
        end
    end

    println(io,"")
    return nothing
end