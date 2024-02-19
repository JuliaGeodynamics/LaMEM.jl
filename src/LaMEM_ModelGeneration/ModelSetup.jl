# Model Setup

export ModelSetup, Write_LaMEM_InputFile, 
        geom_Sphere, geom_Ellipsoid, geom_Box, geom_RidgeSeg, geom_Hex, geom_Layer, geom_Cylinder,
        set_geom!

"""
    Structure that contains the LaMEM Model Setup and Advection options
    
    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct ModelSetup
    "Setup type - can be `geom` (phases are assigned from geometric primitives, using `add_geom!(model, ...)`), `files` (from julia input), `polygons` (from geomIO input, which requires `poly_file` to be specified) "
    msetup::String          = "files"              
     
    "add random noise to the particle location"
    rand_noise::Int64      = 1                 

    "random noise flag, subsequently applied to geometric primitives"
    rand_noiseGP::Int64    = 1                 

    "background phase ID"
    bg_phase::Int64        = 0                 

    "save marker to disk flag"
    save_mark::Int64       = 1                 

    "marker input file (extension is .xxxxxxxx.dat), if using `msetup`=`files`"
    mark_load_file::String  = "./markers/mdb"     

    "marker output file (extension is .xxxxxxxx.dat)"
    mark_save_file::String  = "./markers/mdb"     

    "polygon geometry file (redundant), if using `msetup`=`polygons`"
    poly_file::String       = "./input/poly.dat"

    "initial temperature file (redundant), if not set on markers"
    temp_file::String   = "./input/temp.dat"  

    "advection scheme; options=`none` (no advection); `basic` (Euler classical implementation [default]); `Euler` (Euler explicit in time); `rk2` (Runge-Kutta 2nd order in space)"
    advect::String      = "rk2"             

    "velocity interpolation scheme; options = `stag` (trilinear interpolation from FDSTAG points), `minmod` ( MINMOD interpolation to nodes, trilinear interpolation to markers + correction), `stagp` ( STAG_P empirical approach by T. Gerya) "
    interp::String      = "stag"              

    "STAG_P velocity interpolation parameter"
    stagp_a::Float64      = 0.7               

    "marker control type; options are `subgrid` (default; marker control enforced over fine scale grid), `none` (none), `basic` (AVD for cells + corner insertion), and `avd` (pure AVD for all control volumes)"
    mark_ctrl::String           = "subgrid"              

    "min/max number per cell (marker control)"
    nmark_lim::Vector{Int64}        = [10, 100]            

    "x-y-z AVD refinement factors (avd marker control)"
    nmark_avd::Vector{Int64}        = [3, 3, 3]             

    "max number of same phase markers per subcell (subgrid marker control)"
    nmark_sub::Int64                = 3        

    "Different geometric primitives that can be selected if we `msetup``=`geom`; see `geom_Sphere`"
    geom_primitives::Vector    = []
end

# Print info about the structure
function show(io::IO, d::ModelSetup)
    Reference = ModelSetup();
    println(io, "LaMEM Model Setup options: ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        if (f!=:geom_primitives)
            col = gettext_color(d,Reference, f)
            printstyled(io,"  $(rpad(String(f),17)) = $(getfield(d,f)) \n", color=col)      
        else
            col = gettext_color(d,Reference, f)
            geom_objects = getfield(d,:geom_primitives)
            if length(geom_objects)>0
                printstyled(io,"  $(rpad(String(f),17)) = $(geom_objects[1])", color=col)   
                for i = 2:length(geom_objects)
                    printstyled(io,"                      $(geom_objects[i])", color=col)   
                end
            else
                printstyled(io,"  $(rpad(String(f),17)) = ", color=col)   
            end
        end
    end

  
    return nothing
end


function show_short(io::IO, d::ModelSetup)
    str_geom = ""
    if d.msetup == "geom"
        str_geom = "$(length(d.geom_primitives)) geometric primitive objects"
    end

    println(io,"|-- Model setup options :  Type=$(d.msetup); $(str_geom)")

    return nothing
end


# Geometric primitives======

# -------
"""
    LaMEM geometric primitive `sphere` object 
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct geom_Sphere
    "phase"
    phase::Int64          = 1          
     
    "radius of sphere"
    radius::Float64      = 1.5
      
    "center of sphere"
    center::Vector{Float64} = [1.0, 2.0, 3.0]
        
    "optional: Temperature of the sphere. possibilities: [constant, or nothing]"
    Temperature::Union{String,Nothing} = nothing
        
    "required in case of [constant]: temperature value [in Celcius in case of GEO units]"
    cstTemp::Union{Float64,Nothing}     = nothing   
end


function show(io::IO, d::geom_Sphere)
    println(io, "Sphere(ph=$(d.phase), r=$(d.radius), cen=$(d.center), T=$(d.Temperature)=$(d.cstTemp))")
    return nothing
end

"""
    Write_LaMEM_InputFile(io, d::geom_Sphere)

"""
function Write_LaMEM_InputFile(io, d::geom_Sphere)
    fields    = fieldnames(typeof(d))
    println(io, "    <SphereStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(geom_Sphere, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <SphereEnd>")
    return nothing
end
# -------

# -------
"""
    LaMEM geometric primitive `Ellipsoid` object 
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct geom_Ellipsoid
    "phase"
    phase::Int64          = 1          
     
    "semi-axes of ellipsoid in `x`, `y` and `z` "
    axes::Vector{Float64}      = [2.0, 1.5, 1.0]
      
    "center of sphere"
    center::Vector{Float64} = [1.0, 2.0, 3.0]
        
    "optional: Temperature of the sphere. possibilities: [constant, or nothing]"
    Temperature::Union{String,Nothing} = nothing
        
    "required in case of [constant]: temperature value [in Celcius in case of GEO units]"
    cstTemp::Union{Float64,Nothing}     = nothing   
end


function show(io::IO, d::geom_Ellipsoid)
    println(io, "Ellipsoid(ph=$(d.phase), axes=$(d.axes), cen=$(d.center), T=$(d.Temperature)=$(d.cstTemp))")
    return nothing
end

"""
    Write_LaMEM_InputFile(io, d::geom_Ellipsoid)
"""
function Write_LaMEM_InputFile(io, d::geom_Ellipsoid)
    fields    = fieldnames(typeof(d))
    println(io, "    <EllipsoidStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(geom_Ellipsoid, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <EllipsoidEnd>")
    return nothing
end
# -------

# -------
"""
    LaMEM geometric primitive `Box` object 
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct geom_Box
    "phase"
    phase::Int64          = 1          
     
    "box bound coordinates: `left`, `right`, `front`, `back`, `bottom`, `top` "
    bounds::Vector{Float64}      = [1.0, 2.0, 1.0, 2.0, 1.0, 2.0]
        
    "optional: Temperature structure. possibilities: [constant, linear, halfspace]"
    Temperature::Union{String,Nothing} = nothing
        
    "required in case of [`constant`]: temperature value [in Celcius in case of GEO units]"
    cstTemp::Union{Float64,Nothing}     = nothing   

    "required in case of [`linear,halfspace`]: temperature @ top [in Celcius in case of GEO units]"
    topTemp::Union{Float64,Nothing}     = nothing   
    
    "required in case of [`linear,halfspace`]: temperature @ top [in Celcius in case of GEO units]"
    botTemp::Union{Float64,Nothing}     = nothing   
    
    "required in case of [`halfspace`]: thermal age of lithosphere [in Myrs if GEO units are used]"
    thermalAge::Union{Float64,Nothing}     = nothing   
end

function show(io::IO, d::geom_Box)
    println(io, "Box(ph=$(d.phase), bounds=$(d.bounds), T=$(d.Temperature)=$(d.cstTemp), [top,box]=[$(d.topTemp), $(d.botTemp)], thermalAge=$(d.thermalAge))")
    return nothing
end

"""
    Write_LaMEM_InputFile(io, d::geom_Box)
"""
function Write_LaMEM_InputFile(io, d::geom_Box)
    fields    = fieldnames(typeof(d))
    println(io, "    <BoxStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(geom_Box, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <BoxEnd>")
    return nothing
end
# -------

# -------
"""
    LaMEM geometric primitive `RidgeSeg` object 
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct geom_RidgeSeg
    "phase"
    phase::Int64          = 1          
     
    "box bound coordinates: `left`, `right`, `front`, `back`, `bottom`, `top` "
    bounds::Vector{Float64}      = [1.0, 2.0, 1.0, 2.0, 1.0, 2.0]
        
    "coordinate order: left, right [can be different for oblique ridge]"
    ridgeseg_x::Vector{Float64}      = [1.5, 1.5]
    
    "coordinate order: front, back [can be different for oblique ridge]"
    ridgeseg_y::Vector{Float64}      = [1.0, 2.0]
    
    "initial temperature structure [ridge must be set to `halfspace_age` --> setTemp=4]"
    Temperature::String = "halfspace_age"

    "required in case of [`linear,halfspace`]: temperature @ top [in Celcius in case of GEO units]"
    topTemp::Float64     = 0.0   
    
    "required in case of [`linear,halfspace`]: temperature @ top [in Celcius in case of GEO units]"
    botTemp::Float64    = 1300.0   
    
    "minimum age of seafloor at ridge [in `Myr` in case of GEO units]"
    age0::Float64     = 0.001   

    "[optional] parameter that indicates the maximum thermal age of a plate "
    maxAge::Union{Float64,Nothing}      = nothing

    "[optional] parameter that indicates the spreading velocity of the plate; if not defined it uses bvel_velin specified elsewhere"
    v_spread::Union{Float64,Nothing}    = nothing
end

function show(io::IO, d::geom_RidgeSeg)
    println(io, "RidgeSeg(ph=$(d.phase), bounds=$(d.bounds), ridgeseg_x=$(d.ridgeseg_x),ridgeseg_y=$(d.ridgeseg_y),  T=$(d.Temperature) = [top,box]=[$(d.topTemp), $(d.botTemp)], age0=$(d.age0)), maxAge=$(d.maxAge), v_spread=$(d.v_spread))")
    return nothing
end

"""
    Write_LaMEM_InputFile(io, d::geom_RidgeSeg)
"""
function Write_LaMEM_InputFile(io, d::geom_RidgeSeg)
    fields    = fieldnames(typeof(d))
    println(io, "    <RidgeSegStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(geom_RidgeSeg, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <RidgeSegEnd>")
    return nothing
end
# -------

# -------
"""
    LaMEM geometric primitive `Hex` object to define hexahedral elements
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct geom_Hex
    "phase"
    phase::Int64          = 1          
     
    """
    `x`-`y`-`z` coordinates for each of 8 nodes (24 parameters)
    (counter)-clockwise for an arbitrary face, followed by the opposite face
    """
    coord::Vector{Float64}      = [0.25, 0.25, 0.25,   0.5, 0.2, 0.2,   0.6, 0.7, 0.25,   0.3, 0.5, 0.3,   0.2, 0.3, 0.75,   0.6, 0.15, 0.75,   0.5, 0.6, 0.80,   0.2, 0.4, 0.75]
end

function show(io::IO, d::geom_Hex)
    println(io, "Hex(ph=$(d.phase), coord=$(d.coord))")
    return nothing
end

"""
    Write_LaMEM_InputFile(io, d::geom_Hex)
"""
function Write_LaMEM_InputFile(io, d::geom_Hex)
    fields    = fieldnames(typeof(d))
    println(io, "    <HexStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(geom_Hex, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <HexEnd>")
    return nothing
end
# -------

# -------
"""
    LaMEM geometric primitive `Layer` object 
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct geom_Layer
    "phase"
    phase::Int64          = 1          
     
    "top of layer"
    top::Float64         = 5.0
    
    "bottom of layer"
    bottom::Float64      = 3.0
    
    "optional: add a cosine perturbation on top of the interface (if 1)"
    cosine::Union{Int64,Nothing} = nothing
    
    "required if cosine: wavelength in x-direction"
    wavelength::Union{Float64,Nothing} = nothing

    "required if cosine: amplitude of perturbation"
    amplitude::Union{Float64,Nothing} = nothing

    "optional: Temperature structure. possibilities: [constant, linear, halfspace]"
    Temperature::Union{String,Nothing} = nothing

    "required in case of [`constant`]: temperature value [in Celcius in case of GEO units]"
    cstTemp::Union{Float64,Nothing}     = nothing   

    "required in case of [`linear,halfspace`]: temperature @ top [in Celcius in case of GEO units]"
    topTemp::Union{Float64,Nothing}     = nothing   
    
    "required in case of [`linear,halfspace`]: temperature @ top [in Celcius in case of GEO units]"
    botTemp::Union{Float64,Nothing}     = nothing   
    
    "required in case of [`halfspace`]: thermal age of lithosphere [in Myrs if GEO units are used]"
    thermalAge::Union{Float64,Nothing}  = nothing   
end

function show(io::IO, d::geom_Layer)
    println(io, "Layer(ph=$(d.phase), bot/top=[$(d.bot),$(d.top)], T=$(d.Temperature)=$(d.cstTemp), [Ttop,Tbot]=[$(d.topTemp), $(d.botTemp)], thermalAge=$(d.thermalAge), cosine perturbation=$(d.cosine), wavelength=$(d.wavelength), amplitude=$(d.amplitude))")
    return nothing
end

"""
    Write_LaMEM_InputFile(io, d::geom_Layer)
"""
function Write_LaMEM_InputFile(io, d::geom_Layer)
    fields    = fieldnames(typeof(d))
    println(io, "    <LayerStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(geom_Layer, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <LayerEnd>")
    return nothing
end
# -------

# -------
"""
    LaMEM geometric primitive `Cylinder` object 
    
    $(TYPEDFIELDS)
"""
Base.@kwdef struct geom_Cylinder
    "phase"
    phase::Int64          = 1          
     
    "radius of cylinder "
    radius::Float64      = 1.5
    
    "center of base of cylinder"
    base::Vector{Float64}      = [1.0, 2.0, 3.0]
    
    "center of cap of cylinder"
    cap::Vector{Float64}      = [3.0, 5.0, 7.0]
    
    "optional: Temperature structure. possibilities: [constant]"
    Temperature::Union{String,Nothing} = nothing
        
    "required in case of [`constant`]: temperature value [in Celcius in case of GEO units]"
    cstTemp::Union{Float64,Nothing}     = nothing   

end

function show(io::IO, d::geom_Cylinder)
    println(io, "Cylinder(ph=$(d.phase), radius=$(d.radius) base=$(d.base), cap=$(d.cap), T=$(d.Temperature)=$(d.cstTemp) )")
    return nothing
end

"""
    Write_LaMEM_InputFile(io, d::geom_Cylinder)
"""
function Write_LaMEM_InputFile(io, d::geom_Cylinder)
    fields    = fieldnames(typeof(d))
    println(io, "    <CylinderStart>")
    for f in fields
        if !isnothing(getfield(d,f))
            name = rpad(String(f),15)
            comment = get_doc(geom_Cylinder, f)
            data = getfield(d,f) 
            println(io,"        $name  = $(write_vec(data))     # $(comment)")
        end
    end
    println(io, "    <CylinderEnd>")
    return nothing
end
# -------

# ==========================



"""
    Write_LaMEM_InputFile(io, d::ModelSetup)
Writes options related to the Model Setup to disk
"""
function Write_LaMEM_InputFile(io, d::ModelSetup)
    Reference = ModelSetup();    # reference values
    fields    = fieldnames(typeof(d))

    println(io, "#===============================================================================")
    println(io, "# Model setup & advection")
    println(io, "#===============================================================================")
    println(io,"")

    for f in fields

    
        if getfield(d,f) != getfield(Reference,f)  ||
            (f == :bg_phase)    ||
            (f == :msetup)      ||
            (f == :rand_noise)  ||
            (f == :nmark_lim)   ||
            (f == :nmark_sub)   ||
            (f == :advect)      ||
            (f == :interp)      ||
            (f == :mark_ctrl)
            

            if (f != :geom_primitives)
                # only print if value differs from reference value
                name = rpad(String(f),15)
                comment = get_doc(ModelSetup, f)
                data = getfield(d,f) 
                println(io,"    $name  = $(write_vec(data))     # $(comment)")
            end
        end
    end

    # Write geometric primitives in a separate block
    if length(d.geom_primitives)>0
        println(io, "")
        println(io, "# Geometric primitives: \n")
        for object in d.geom_primitives
            Write_LaMEM_InputFile(io, object)
        end
    end


    println(io,"")
    return nothing
end