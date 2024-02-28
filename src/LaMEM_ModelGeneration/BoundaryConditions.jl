#Specify Boundary Conditions
#
# WARNING: incomplete, more parameters to be added 

export BoundaryConditions, VelocityBox, BCBlock, VelCylinder, Write_LaMEM_InputFile


# -------
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

#=
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
=#

function show(d::VelocityBox)
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
    Write_LaMEM_InputFile(io, d::geom_Sphere)

"""
function Write_LaMEM_InputFile(io, d::VelocityBox)
    fields    = fieldnames(typeof(d))
    println(io, "    <VelBoxStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(VelocityBox, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <VelBoxEnd>")
    return nothing
end

# -------
"""
    LaMEM boundary condition `BCBlock` object 
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct BCBlock
    "Number of path points of Bezier curve (path-points only!)"
    npath::Int64 =  2      

    "# Orientation angles at path points (counter-clockwise positive)"    
    theta::Vector{Float64} =  [0.0, 5.0]                      
    
    "Times at path points"
    time::Vector{Float64}  =  [1.0, 2.0]                
    
    "Path points x-y coordinates"
    path::Vector{Float64}  =  [0.0, 0.0, 0.0, 10.0]           
    
    "Number of polygon vertices"
    npoly::Int64 =  4                                

    "Polygon x-y coordinates at initial time"
    poly::Vector{Float64}  =  [ 0.0, 0.0, 0.1, 0.0, 0.1, 0.1, 0.0, 0.1]

    "Polygon bottom coordinate"
    bot::Float64    =  0.0                            
    
    "Polygon top coordinate"
    top::Float64   =  0.1                              

end

#=
function show(io::IO, d::BCBlock)
    println(io, "BCBlock: ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) 
            printstyled(io,"  $(rpad(String(f),9)) = $(getfield(d,f)) \n")        
        end
    end

    return nothing
end
=#

function show(io::IO, d::BCBlock)
    print(io, "BCBlock(npath=$(d.npath), theta=$(d.theta), time=$(d.time))")
    return nothing
end

function Write_LaMEM_InputFile(io, d::BCBlock)
    fields    = fieldnames(typeof(d))
    println(io, "    <BCBlockStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(BCBlock, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <BCBlockEnd>")
    return nothing
end
# -------

# -------
"""
    LaMEM boundary condition internal velocty cylinder `VelCylinder` object 
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct VelCylinder
    "X-coordinate of base of cylinder"
    baseX::Float64    =   1.0      

    "Y-coordinate of base of cylinder"
    baseY::Float64    =   1.0      
    
    "Z-coordinate of base of cylinder"
    baseZ::Float64    =   1.0      
    
    "X-coordinate of cap of cylinder"
    capX::Float64     =   1.0      
    
    "Y-coordinate of cap of cylinder"
    capY::Float64     =   1.0      
    
    "Z-coordinate of cap of cylinder"
    capZ::Float64     =   1.0      
    
    "radius of cylinder"
    radius::Float64   =   1.0     
    
    "Vx velocity of cylinder (default is unconstrained)"
    vx::Union{Nothing,Float64}       =   nothing  
    
    "Vy velocity of cylinder (default is unconstrained)"
    vy::Union{Nothing,Float64}       =   nothing     
    
    "Vz velocity of cylinder (default is unconstrained)  "
    vz::Union{Nothing,Float64}       =   nothing  
    
    "cylinder advection flag"
    advect::Int64   =   0        
    
    "magnitude of velocity applied along the cylinder's axis of orientation"
    vmag::Float64     =   1.0     
    
    "velocity profile [uniform or parabolic]"
    type::String     =   "uniform" 

end

#=
function show(io::IO, d::VelCylinder)
    println(io, "VelCylinder: ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if !isnothing(getfield(d,f)) 
            printstyled(io,"  $(rpad(String(f),9)) = $(getfield(d,f)) \n")        
        end
    end

    return nothing
end
=#
function show(io::IO, d::VelCylinder)
    print(io, "VelCylinder(base=($(d.baseX), $(d.baseY), $(d.baseZ)), cap=$(d.capX), $(d.capY), $(d.capZ))), radius=$(d.radius), Velocity=($(d.vx),$(d.vy),$(d.vz)), advect=$(d.advect), vmag=$(d.vmag), type=$(d.type))")
    return nothing
end

function Write_LaMEM_InputFile(io, d::VelCylinder)
    fields    = fieldnames(typeof(d))
    println(io, "    <VelCylinderStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(VelCylinder, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <VelCylinderEnd>")
    return nothing
end
# -------


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

    "List of added Bezier blocks"
    BCBlocks::Vector{BCBlock} = []

    "List of added velocity cylinders"
    VelCylinders::Vector{VelCylinder} = []

    "Face identifier  (Left; Right; Front; Back; CompensatingInflow)"
    bvel_face::Union{Nothing,String}    =         nothing

    "Velocity on opposite side: -1 for inverted velocity; 0 for no velocity; 1 for the same direction of velocity"
    bvel_face_out::Union{Nothing,Int64}  =         nothing

    "Bottom coordinate of inflow window"
    bvel_bot::Union{Nothing,Float64}    =        nothing

    "Top coordinate of inflow window"
    bvel_top::Union{Nothing,Float64}        =        nothing

    "Number of periods when velocity changes (Optional)"
    velin_num_periods::Union{Nothing,Int64}    =         nothing
 
    "Change velocity at 2 and 5 Myrs (one less than number of intervals, not required for one interval) (Optional)"
    velin_time_delims::Union{Nothing,Vector}    =        nothing
    
    "inflow velocity for each time interval(Multiple values required if  velin_num_periods>1)"
    bvel_velin::Union{Nothing,Vector}       =   nothing
    
    "outflow velocity (if not specified, computed from mass balance)"
    bvel_velout::Union{Nothing,Float64}     =   nothing      

    "vert.distance from bvel_bot and bvel_top over which velocity is reduced linearly"
    bvel_relax_d::Union{Nothing,Float64}    =   nothing                    

    "bottom inflow velocity for use with bvel_face=CompensatingInflow"
    bvel_velbot::Union{Nothing,Int64}       =   nothing   	                     

    "top inflow velocity for use with bvel_face=CompensatingInflow"
    bvel_veltop::Union{Nothing,Int64}       =   nothing                

    "bvel_temperature_inflow: Thermal age of the plate, which can be constant if set to Fixed_thermal_age or Constant_T_inflow (Temperature of the inflow material is constant everywhere)"
    bvel_temperature_inflow::Union{Nothing,String}   =     nothing

    "In dimensional unit. If the user specify this value, he needs to specify the temperature of the mantle and top as well"
    bvel_thermal_age::Union{Nothing,Float64}         =   nothing                    

    "In dimensional unit. Temperature of the mantle"
    bvel_temperature_mantle::Union{Nothing,Float64}  =   nothing                    

    "In dimensional unit. temperature of the top"        
    bvel_temperature_top::Union{Nothing,Float64}     =   nothing                    

    "Constant temperature inflow. "      
    bvel_temperature_constant::Union{Nothing,Float64}    =   nothing                    
      
    "Imposes a stratigraphy of phase injected in the inflow boundary [if undefined, it uses the phase close to the boundary]"
    bvel_num_phase::Union{Nothing,Int64}       =   nothing                      

    "phase number of inflow material [if undefined, it uses the phase close to the boundary] from bottom to top"
    bvel_phase::Union{Nothing,Vector{Int64}}       =   nothing                 

    "Depth interval of injection of the phase (the interval is defined by num_phase+1 coordinates). e.g. [-120 -100 -10 0    ]"
    bvel_phase_interval::Union{Nothing,Vector{Float64}}       =   nothing              

    "# Permeable lower boundary flag    "
    open_bot_bound::Union{Nothing,Int64}       =   nothing    

    "Phase of the inflow material from the bottom (The temperature of the inflow phase it is the same of the bottom boundary) in case of open_bot_bound=1"
    permeable_phase_inflow::Union{Nothing,Int64}       =   nothing    

    "fixed phase (no-flow condition)"
    fix_phase::Union{Nothing,Int64}       =   nothing 

    "fixed cells (no-flow condition)"
    fix_cell::Union{Nothing,Int64}       =   nothing 

    "fixed cells input file (extension is .xxxxxxxx.dat)"
    fix_cell_file::Union{Nothing,String} = nothing

    "How many periods with different temp_bot do we have? "
    temp_bot_num_periods::Union{Nothing,Int64}       =   nothing 

    "At which time do we switch from one to the next period?"
    temp_bot_time_delim::Union{Nothing,Vector{Float64}}       =   nothing 

    # Optional plume inflow @ bottom boundary
    "# have a plume-like inflow boundary @ bottom"
    Plume_InflowBoundary::Union{Nothing,Int64}       =   nothing 
    
    """
    Type of plume inflow boundary.
    - `"Inflow_type"` or 
    - `"Pressure_type"` (circular)	or 
    - `"Permeable_Type"` which combines the open bot boundary with the plume boundary condition (the option herein listed overwrites open_bot, so do not activate that) 	
    """
    Plume_Type::Union{Nothing,String}           =   nothing   
    
    "2D or 3D (circular)		"
    Plume_Dimension::Union{Nothing,String}       =   nothing   

    " how much of the plume is actually in the model. This usually 1 (default) but lower if the plume is in a corner of a symmetric setup and matters for the outflow"
    Plume_areaFrac::Union{Nothing,Float64}       =   nothing 

    "phase of plume material"
    Plume_Phase::Union{Nothing,Int64}       =   nothing 

    " # depth of provenience of the plume (i.e. how far from the bottom of the model the plume source is) "
    Plume_Depth::Union{Nothing,Float64}       =   nothing 

    "# Astenosphere phase (if the inflow occurs outside the plume radius)"
    Plume_Mantle_Phase::Union{Nothing,Int64}       =   nothing 

    "# temperature of inflow plume"
    Plume_Temperature::Union{Nothing,Float64}       =   nothing 

    " # Inflow velocity	(not required if Pressure_Type) in cm/year if using GEOunits"
    Plume_Inflow_Velocity::Union{Nothing,Float64}       =   nothing 

    " `\"Gaussian\"` or `\"Poiseuille\"`"
    Plume_VelocityType::Union{Nothing,String}       =   nothing   
    
    "# [X,Y] of center  (2nd only in case of 3D plume)"
    Plume_Center::Union{Nothing,Vector{Float64}}       =   nothing 

    " # Width/Radius of plume"
    Plume_Radius::Union{Nothing,Float64}       =   nothing 

    "# Inflow phase. If the velocity happens to be positive in the domain, the inflow material has a constant phase and the temperature of the bottom"
    Plume_Phase_Mantle::Union{Nothing,Int64}       =   nothing 

    " Pressure on the top boundary"
    pres_top::Union{Nothing,Float64}       =   nothing 

    " Pressure on the bottom boundary"
    pres_bot::Union{Nothing,Float64}       =   nothing 

    "pressure initial guess flag;  linear profile between pres_top and pres_bot in the unconstrained cells"
    init_pres::Union{Nothing,Int64}       =   nothing 

    "temperature initial guess flag; linear profile between temp_top and temp_bot"
    init_temp::Union{Nothing,Int64}       =   nothing 

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

        if (f != :VelocityBoxes) && (f != :VelCylinder) && (f != :BCBlock) # Skip the velocity boxes

            if getfield(d, f) != getfield(Reference, f)
                # only print if value differs from reference value
                name = rpad(String(f), 15)
                comment = get_doc(BoundaryConditions, f)
                data = getfield(d, f)
                println(io, "    $name  = $(write_vec(data))     # $(comment)")
            end
        end
        
        #end        elseif f != :VelocityBoxes
#            Write_LaMEM_InputFile(io, f)


            #=
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
            =#
      #  elseif f != :VelCylinder
      #      Write_LaMEM_InputFile(io, f)
      #  elseif f != :BCBlock
      #      Write_LaMEM_InputFile(io, f)
#
#
      #  end

    end
    println(io, "")

    if length(d.VelocityBoxes)>0
        println(io, "")
        println(io, "# Velocity boxes: \n")
        for object in d.VelocityBoxes
            Write_LaMEM_InputFile(io, object)
        end
    end

    if length(d.VelCylinders)>0
        println(io, "")
        for object in d.VelCylinders
            Write_LaMEM_InputFile(io, object)
        end
    end

    if length(d.BCBlocks)>0
        println(io, "")
        for object in d.BCBlocks
            Write_LaMEM_InputFile(io, object)
        end
    end
    
    


    println(io, "# temperature on the top & bottom boundaries [usually constant]")
    println(io, "    temp_top   = $(write_vec(d.temp_top))")
    println(io, "    temp_bot   = $(write_vec(d.temp_bot))")

    println(io, "")
    return nothing
end
