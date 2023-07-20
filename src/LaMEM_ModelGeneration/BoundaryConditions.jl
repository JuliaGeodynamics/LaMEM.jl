#Specify Boundary Conditions
#
# WARNING: incomplete, more parameters to be added 

export BoundaryConditions, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM boundary conditions information. 
    
    $(TYPEDFIELDS)

"""
Base.@kwdef mutable struct BoundaryConditions
    
    "No-slip boundary flag mask (left right front back bottom top)"
    noslip::Vector{Int64} = [0, 0, 0, 0, 0, 0]  

    "Stress-free (free surface/infinitely fast erosion) top boundary flag"
    open_top_bound::Int64 = 0                   
    
    "Constant temperature on the top boundary"
    temp_top::Float64   =   0.0            
    
    "Constant temperature on the bottom boundary  "                 
    temp_bot::Float64   =   1300.0              

    "number intervals of constant background strain rate (x-axis)"
    exx_num_periods::Int64  = 3                            
    
    "time delimiters (one less than number of intervals, not required for one interval) "    
    exx_time_delims::Vector{Float64}  = [0.1, 5.0]    
    
    "strain rates for each interval          "
    exx_strain_rates::Vector{Float64} = [1e-15, 2e-15, 1e-15]   

    eyy_num_periods::Int64  = 2               
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

    "background strain rate reference point (fixed)"
    bg_ref_point::Vector{Float64}     = [0.0, 0.0, 0.0]      

end

# Print info about the structure
function show(io::IO, d::BoundaryConditions)
    Reference = BoundaryConditions();    # reference values
    println(io, "LaMEM Boundary conditions : ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),17)) = $(getfield(d,f)) \n", color=col)        
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
    fields    = fieldnames(typeof(d))
    
    println(io, "#===============================================================================")
    println(io, "# Boundary conditions")
    println(io, "#===============================================================================")
    println(io,"")

    for f in fields
        if getfield(d,f) != getfield(Reference,f) 
            # only print if value differs from reference value
            name = rpad(String(f),15)
            comment = get_doc(BoundaryConditions, f)
            data = getfield(d,f) 
            println(io,"    $name  = $(write_vec(data))     # $(comment)")
        end
    end

    println(io,"")
    return nothing
end