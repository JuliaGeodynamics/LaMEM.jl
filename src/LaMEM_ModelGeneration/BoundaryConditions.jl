#Specify Boundary Conditions
#
# WARNING: incomplete, more parameters to be added 

export BoundaryConditions, VelocityBox, Write_LaMEM_InputFile



"""
    Define velocity regions within the modelling region, by specifying its center point and width along the three axis.    

    $(TYPEDFIELDS)

"""
Base.@kwdef mutable struct VelocityBox
    "X-coordinate of center of box"
    cenX::Float64 = 0

    "Y-coordinate of center of box"
    cenY::Float64 = 0

    "Z-coordinate of center of box"
    cenZ::Float64 = 0

    "Width of box in x-direction"
    widthX::Float64 = 0
    
    "Width of box in y-direction"
    widthY::Float64 = 0

    "Width of box in Z-direction"
    widthZ::Float64 = 0

    "Vx velocity of box (default is unconstrained)"
    vx::Union{Nothing, Float64} = nothing

    "Vx velocity of box (default is unconstrained)"
    vy::Union{Nothing, Float64} = nothing
    
    "Vx velocity of box (default is unconstrained)"
    vz::Union{Nothing, Float64} = nothing

    "  box advection flag"
    advect::Int64 = 0
end

function show(io::IO, d::VelocityBox)
    println(io, "VelocityBox: ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) & (f != :ID) & (f != :Name)
            printstyled(io,"  $(rpad(String(f),9)) = $(getfield(d,f)) \n")        
        end
    end

    return nothing
end

function show_short(d::VelocityBox)
    fields    = fieldnames(typeof(d))
    str = "VelocityBox("
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

    "eyy_num_periods"
    eyy_num_periods::Int64  = 2    

    "eyy_time_delims"
    eyy_time_delims::Vector{Float64}  = [1.0]
    
    "eyy_strain_rates"
    eyy_strain_rates::Vector{Float64} = [1e-15, 2e-15]

    "exy_num_periods"
    exy_num_periods::Int64  = 2                 # same for simple shear components in x/y direction
    "exy_time_delims"
    exy_time_delims::Vector{Float64}  = [1.0]
    
    "exy_strain_rates"
    exy_strain_rates::Vector{Float64} = [1e-15, 2e-15]

    "exz_num_periods"
    exz_num_periods::Int64  = 2                 # same for simple shear components in x/z direction
    
    "exz_time_delims"
    exz_time_delims::Vector{Float64}  = [1.0]
    
    "exz_strain_rates"
    exz_strain_rates::Vector{Float64} = [1e-15, 2e-15]

    "eyz_num_periods"
    eyz_num_periods::Int64  = 2                 # same for simple shear components in y/z direction

    "eyz_time_delims"
    eyz_time_delims::Vector{Float64}  = [1.0]
    
    "eyz_strain_rates"
    eyz_strain_rates::Vector{Float64} = [1e-15, 2e-15]

    "background strain rate reference point (fixed)"
    bg_ref_point::Vector{Float64}     = [0.0, 0.0, 0.0]      

    "List of added velocity boxes"
    VelocityBoxes::Vector{VelocityBox} = []

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

        if f != :VelocityBoxes # Skip the velocity boxes

            if getfield(d, f) != getfield(Reference, f)
                # only print if value differs from reference value
                name = rpad(String(f), 15)
                comment = get_doc(BoundaryConditions, f)
                data = getfield(d, f)
                println(io, "    $name  = $(write_vec(data))     # $(comment)")
            end

        else

            # Add the velocity boxes
            if length(d.VelocityBoxes) != 0
                println(io, "")
                println(io, "   # Internal velocity box(es) \n")
                for VB in d.VelocityBoxes

                    println(io, "   <VelBoxStart>")

                    vb_fields = fieldnames(typeof(VB))
                    for vb in vb_fields
                        if !isnothing(getfield(VB, vb))
                            name = rpad(String(vb), 15)
                            comment = get_doc(VelocityBox, vb)
                            data = getfield(VB, vb)
                            println(io, "        $name  = $(write_vec(data))     # $(comment)")
                        end
                    end

                    println(io, "   <VelBoxEnd>")
                    println(io, "")
                end
            end

        end

    end
    println(io, "")


    println(io, "# temperature on the top & bottom boundaries [usually constant]")
    println(io, "    temp_top   = $(write_vec(d.temp_top))")
    println(io, "    temp_bot   = $(write_vec(d.temp_bot))")

    println(io, "")
    return nothing
end
