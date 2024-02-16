# Model Setup

export ModelSetup, Write_LaMEM_InputFile, geom_Sphere, set_geom!

"""
    Structure that contains the LaMEM Model Setup and Advection options
    
    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct ModelSetup
    "Setup type - can be `geom` (phases are assigned from geometric primitives), `files` (from julia input), `polygons` (from geomIO input, which requires `poly_file` to be specified) "
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
    println(io,"|-- Model setup options :  Type=$(d.msetup); ")

    return nothing
end


# Geometric primitives======
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

        println("WARNING! Still need to implement geometric primitives!!")
    end


    println(io,"")
    return nothing
end