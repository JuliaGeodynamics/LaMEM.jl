# Parameters related to the free surface

# related to timestepping

export FreeSurface, write_LaMEM_inputFile

"""
    Structure that contains the LaMEM free surface information.

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct FreeSurface
    "Free surface activation flag"
    surf_use::Int64             = 0                 

    "air phase ratio correction flag (phases in an element that contains are modified based on the surface position)"
    surf_corr_phase::Int64      = 1                 

    "initial level of the free surface"
    surf_level::Union{Float64,Nothing}  = nothing               

    "phase ID of sticky air layer"
    surf_air_phase::Union{Int64,Nothing}       = nothing                 

    "maximum angle with horizon (smoothed if larger)"
    surf_max_angle::Float64     = 45.0              

    "initial topography file (redundant)"
    surf_topo_file::String      = ""                

    "erosion model [0-none (default), 1-infinitely fast, 2-prescribed rate with given level]"
    erosion_model::Int64        = 0                 

    "number of erosion phases"
    er_num_phases::Int64        = 3                 

    "erosion time delimiters (one less than number)"
    er_time_delims::Vector{Float64} = [0.5,   2.5]  

    "constant erosion rates in different time periods"
    er_rates::Vector{Float64}   = [0.2, 0.1, 0.2]   

    "levels above which we apply constant erosion rates in different time periods"
    er_levels::Vector{Int64}    = [1,   2,   1]     

    "sedimentation model [0-none (dafault), 1-prescribed rate with given level, 2-cont. margin]"
    sediment_model::Int64       = 0                 

    "number of sediment layers"
    sed_num_layers::Int64       = 3                 

    "sediment layers time delimiters (one less than number)"
    sed_time_delims::Vector{Float64} = [0.5,   2.5] 

    "sediment rates in different time periods"
    sed_rates::Vector{Float64}  = [0.3, 0.2, 0.3]   

    "levels below which we apply constant sediment rates in different time periods"
    sed_levels::Vector{Float64} = [-5,  -2,  -2]    

    "sediment layers phase numbers in different time periods"
    sed_phases::Vector{Int64}   = [1,   2,   3]     

    "lateral coordinates of continental margin - origin"
    marginO::Vector{Float64}    = [0.0, 0.0]        

    "lateral coordinates of continental margin - 2nd point"
    marginE::Vector{Float64}    = [10.0, 10.0]      

    "up dip thickness of sediment cover (onshore)"
    hUp::Float64                = 1.5               

    "down dip thickness of sediment cover (off shore)"
    hDown::Float64              = 0.1               

    "half of transition zone"
    dTrans::Float64             = 1.0    
    
    "Topography grid"
    Topography::Union{CartData, Nothing} =   nothing
end

# Print info about the structure
function show(io::IO, d::FreeSurface)
    Reference = FreeSurface();
    println(io, "LaMEM Free Surface parameters: ")
    fields    = fieldnames(typeof(d))

    # Do we have multiple timestepping periods? 
    surf_use = d.surf_use
    if surf_use==1
        
        # print fields
        for f in fields
            col = gettext_color(d,Reference, f)
            printstyled(io,"  $(rpad(String(f),15)) = $(getfield(d,f)) \n", color=col)        
        end
    else
        println(io,"  Free surface inactive")        
    end
  
    return nothing
end

function show_short(io::IO, d::FreeSurface)
    surf_use = d.surf_use
    if surf_use==1
        println(io,"|-- Free Surface        :  surf_level=$(d.surf_level); topo_file=$(d.surf_topo_file)")
    end
    
    return nothing
end



"""
    write_LaMEM_inputFile(io, d::FreeSurface)
Writes the free surface related parameters to file
"""
function write_LaMEM_inputFile(io, d::FreeSurface)
    Reference = FreeSurface();    # reference values
    fields    = fieldnames(typeof(d))
    surf_use  = d.surf_use

    println(io, "#===============================================================================")
    println(io, "# Free surface")
    println(io, "#===============================================================================")
    println(io,"")

    if surf_use==1
        for f in fields
            if (getfield(d,f) != getfield(Reference,f) && (f != :Topography)) 
                
                # only print if value differs from reference value
                name = rpad(String(f),15)
                comment = get_doc(FreeSurface, f)
                data = getfield(d,f) 
                println(io,"    $name  = $(write_vec(data))     # $(comment)")
            end
        end
    end

    println(io,"")
    return nothing
end