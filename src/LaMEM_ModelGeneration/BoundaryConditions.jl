#Specify Boundary Conditions
#
# WARNING: incomplete, more parameters to be added 
export BoundaryConditions, BoundaryConditions_info, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM boundary conditions information. 

"""
Base.@kwdef mutable struct BoundaryConditions
    
    
    noslip::Vector{Int64} = [0, 0, 0, 0, 0, 0]  # No-slip boundary flag mask (left right front back bottom top)

    open_top_bound::Int64 = 0                   # Stress-free (free surface/infinitely fast erosion) top boundary flag

    temp_top::Float64   =   0.0                 # Constant temperature on the top boundary
    temp_bot::Float64   =   1300.0              # Constant temperature on the bottom boundary               


    # Background strain rate parameters
    exx_num_periods::Int64  = 3                                 # number intervals of constant strain rate (x-axis)
    exx_time_delims::Vector{Float64}  = [0.1, 5.0]              # time delimiters (one less than number of intervals, not required for one interval)
    exx_strain_rates::Vector{Float64} = [1e-15, 2e-15, 1e-15]   # strain rates for each interval

    eyy_num_periods::Int64  = 2                 # ... same for y-axis
    eyy_time_delims::Vector{Float64}  = [1.0]
    eyy_strain_rates::Vector{Float64} = [1e-15, 2e-15]

    exy_num_periods::Int64  = 2                 # same for simple shear components in x/y direction
    exy_time_delims::Vector{Float64}  = [1.0]
    exy_strain_rates::Vector{Float64} = [1e-15, 2e-15]

    exz_num_periods::Int64  = 2                 # same for simple shear components in x/z direction
    exz_time_delims::Vector{Float64}  = [1.0]
    exz_strain_rates::Vector{Float64} = [1e-15, 2e-15]

    eyz_num_periods::Int64  = 2                 # same for simple shear components in y/z direction
    eyz_time_delims::Vector{Float64}  = [1.0]
    eyz_strain_rates::Vector{Float64} = [1e-15, 2e-15]

    bg_ref_point::Vector{Float64}     = [0.0, 0.0, 0.0]       # background strain rate reference point (fixed)

end


# Strings that explain 
Base.@kwdef struct BoundaryConditions_info
    noslip::String = "No-slip boundary flag mask (left right front back bottom top)"

    open_top_bound::String = "Stress-free (free surface/infinitely fast erosion) top boundary flag"

    temp_top::String   =   "Constant temperature on the top boundary"
    temp_bot::String   =   "Constant temperature on the bottom boundary"


    # Background strain rate parameters
    exx_num_periods::String  = " number intervals of constant strain rate (x-axis)"
    exx_time_delims::String  = "time delimiters (one less than number of intervals, not required for one interval)"
    exx_strain_rates::String = "strain rates for each interval"

    eyy_num_periods::String  = ""               
    eyy_time_delims::String  = ""
    eyy_strain_rates::String =""

    exy_num_periods::String  = ""
    exy_time_delims::String  = ""
    exy_strain_rates::String = ""

    exz_num_periods::String  = ""
    exz_time_delims::String  = ""
    exz_strain_rates::String = ""

    eyz_num_periods::String  = ""                 # same for simple shear components in y/z direction
    eyz_time_delims::String  = ""
    eyz_strain_rates::String = ""

    bg_ref_point::String     = "background strain rate reference point (fixed)"

end


# Print info about the structure
function show(io::IO, d::BoundaryConditions)
    Reference = BoundaryConditions();    # reference values
    println(io, "LaMEM Boundary conditions : ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),15)) = $(getfield(d,f)) \n", color=col)        
    end
    
    return nothing
end

function show_short(io::IO, d::BoundaryConditions)
    println(io,"|-- Boundary conditions :  noslip=$(d.noslip)")
    
    return nothing
end



"""
    Write_LaMEM_InputFile(io, d::BoundaryConditions)
Writes the boundary conditions related parameters to file
"""
function Write_LaMEM_InputFile(io, d::BoundaryConditions)
    Reference = BoundaryConditions();    # reference values
    Info      = BoundaryConditions_info()
    fields    = fieldnames(typeof(d))
    
    println(io, "#===============================================================================")
    println(io, "# Boundary conditions")
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