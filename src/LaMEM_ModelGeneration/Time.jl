# related to timestepping

export Time, Time_info, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM timestepping information. An explanation of the paramneters is given in the struct `Time_info`

"""
Base.@kwdef mutable struct Time
    time_end::Float64  = 1.0      # simulation end time
    dt::Float64        = 0.05     # initial time step
    dt_min:: Float64   = 0.01     # minimum time step (declare divergence if lower value is attempted)
    dt_max::Float64    = 0.2      # maximum time step
	dt_out::Float64    = 0.2      # output step (output at least at fixed time intervals)
	inc_dt::Float64    = 0.1      # time step increment per time step (fraction of unit)
	CFL::Float64       = 0.5      # CFL (Courant-Friedrichs-Lewy) criterion
	CFLMAX::Float64    = 0.8      # CFL criterion for elasticity
	nstep_max::Int64   = 50       # maximum allowed number of steps (lower bound: time_end/dt_max)
	nstep_out::Int64   = 1        # save output every n steps; Set this to -1 to deactivate saving output
	nstep_rdb::Int64   = 100      # save restart database every n steps
    num_dt_periods::Int64 = 0     # number of time stepping periods
    time_dt_periods::Vector{Int64} = []     # timestamps where timestep should be fixed (first entry has to 0)
    step_dt_periods::Vector{Float64} = []   # target timesteps ar timestamps above 
    nstep_ini::Int64   = 5            # save output for n initial steps
    time_tol::Float64  = 1e-8        # relative tolerance for time comparisons
end


# Strings that explain 
Base.@kwdef struct Time_info
    time_end::String        = "simulation end time"
    dt::String              = "initial time step"
    dt_min::String          = "minimum time step (declare divergence if lower value is attempted)"
    dt_max::String          = "maximum time step"
	dt_out::String          = "output step (output at least at fixed time intervals)"
	inc_dt::String          = "time step increment per time step (fraction of unit)"
	CFL::String             = "CFL (Courant-Friedrichs-Lewy) criterion"
	CFLMAX::String          = "CFL criterion for elasticity"
	nstep_max::String       = "maximum allowed number of steps (lower bound: time_end/dt_max)"
	nstep_out::String       = "save output every n steps; Set this to -1 to deactivate saving output"
	nstep_rdb::String       = "save restart database every n steps"
    num_dt_periods::String  = "number of time stepping periods"
    time_dt_periods::String = "timestamps where timestep should be fixed (first entry has to 0)"
    step_dt_periods::String = "target timesteps ar timestamps above "
    nstep_ini::String       = "save output for n initial steps"
    time_tol::String        = "relative tolerance for time comparisons"
end


# Print info about the structure
function show(io::IO, d::Time)
    println(io, "LaMEM Timestepping parameters: ")
    fields         = fieldnames(typeof(d))

    # Do we have multiple timestepping periods? 
    num_dt_periods = d.num_dt_periods   
    if num_dt_periods==0
        fields = filter_fields(fields, (:num_dt_periods, :time_dt_periods, :step_dt_periods))
    end

    # print fields
    for f in fields
        println(io,"  $(rpad(String(f),15)) = $(getfield(d,f))")        
    end
  
    return nothing
end

function show_short(io::IO, d::Time)
    println(io,"|-- Time     :  nstep_max=$(d.nstep_max); nstep_out=$(d.nstep_out); time_end=$(d.time_end); dt=$(d.dt)")
    return nothing
end



"""
Writes the Time related parameters to file
"""
function Write_LaMEM_InputFile(io, d::Time)
    Reference = Time();    # reference values
    Info      = Time_info()
    fields    = fieldnames(typeof(d))

    println(io, "#===============================================================================")
    println(io, "# Time stepping parameters")
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