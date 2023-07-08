# Parameters related to the free surface

# related to timestepping

export FreeSurface, FreeSurface_info, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM free surface information.

"""
Base.@kwdef mutable struct FreeSurface
    surf_use::Int64             = 0                 # free surface activation flag
    surf_corr_phase::Int64      = 1                 # air phase ratio correction flag (due to surface position)
    surf_level::Float64         = 0.5               # initial level
    surf_air_phase::Int64       = 0                 # phase ID of sticky air layer
    surf_max_angle::Float64     = 45.0              # maximum angle with horizon (smoothed if larger)
    surf_topo_file::String      = ""                # initial topography file (redundant)
    erosion_model::Int64        = 2                 # erosion model [0-none (default), 1-infinitely fast, 2-prescribed rate with given level]
    er_num_phases::Int64        = 3                 # number of erosion phases
    er_time_delims::Vector{Float64} = [0.5,   2.5]  # erosion time delimiters (one less than number)
    er_rates::Vector{Float64}   = [0.2, 0.1, 0.2]   # constant erosion rates in different time periods
    er_levels::Vector{Int64}    = [1,   2,   1]     # levels above which we apply constant erosion rates in different time periods
    sediment_model::Int64       = 1                 # sedimentation model [0-none (dafault), 1-prescribed rate with given level, 2-cont. margin]
    sed_num_layers::Int64       = 3                 # number of sediment layers
    sed_time_delims::Vector{Float64} = [0.5,   2.5] # sediment layers time delimiters (one less than number)
    sed_rates::Vector{Float64}  = [0.3, 0.2, 0.3]   # sediment rates in different time periods
    sed_levels::Vector{Float64} = [-5,  -2,  -2]    # levels below which we apply constant sediment rates in different time periods 
    sed_phases::Vector{Int64}   = [1,   2,   3]     # sediment layers phase numbers in different time periods
    marginO::Vector{Float64}    = [0.0, 0.0]        # lateral coordinates of continental margin - origin
    marginE::Vector{Float64}    = [10.0, 10.0]      # lateral coordinates of continental margin - 2nd point
    hUp::Float64                = 1.5               # up dip thickness of sediment cover (onshore)
    hDown::Float64              = 0.1               # down dip thickness of sediment cover (off shore)
    dTrans::Float64             = 1.0               # half of transition zone
end


# Strings that explain 
Base.@kwdef struct FreeSurface_info
    surf_use::String            = "free surface activation flag"
    surf_corr_phase::String     = "air phase ratio correction flag (due to surface position)"
    surf_level::String          = "initial level"
    surf_air_phase::String      = "phase ID of sticky air layer"
    surf_max_angle::String      = "maximum angle with horizon (smoothed if larger)"
    surf_topo_file::String      = "initial topography file (redundant)"
    
    erosion_model::String       = "erosion model [0-none (default), 1-infinitely fast, 2-prescribed rate with given level]"
    er_num_phases::String       = "number of erosion phases"
    er_time_delims::String      = "erosion time delimiters (one less than number)"
    er_rates::String            = "constant erosion rates in different time periods"
    er_levels::String           = "levels above which we apply constant erosion rates in different time periods"

    sediment_model::String      = "sedimentation model [0-none (dafault), 1-prescribed rate with given level, 2-cont. margin]"
    sed_num_layers::String      = "number of sediment layers"
    sed_time_delims::String     = "sediment layers time delimiters (one less than number)"
    sed_rates::String           = "sediment rates in different time periods"
    sed_levels::String          = "levels below which we apply constant sediment rates in different time periods"
    sed_phases::String          = "sediment layers phase numbers in different time periods"

    marginO::String             = "lateral coordinates of continental margin - origin"
    marginE::String             = "lateral coordinates of continental margin - 2nd point"
    hUp::String                 = "up dip thickness of sediment cover (onshore)"
    hDown::String               = "down dip thickness of sediment cover (off shore)"
    dTrans::String              = "half of transition zone"
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
        println(io,"|-- Free Surface     :  ")
    end
    
    return nothing
end



"""
    Write_LaMEM_InputFile(io, d::FreeSurface)
Writes the free surface related parameters to file
"""
function Write_LaMEM_InputFile(io, d::FreeSurface)
    Reference = FreeSurface();    # reference values
    Info      = FreeSurface_info()
    fields    = fieldnames(typeof(d))
    surf_use  = d.surf_use

    println(io, "#===============================================================================")
    println(io, "# Free surface")
    println(io, "#===============================================================================")
    println(io,"")

    if surf_use==1
        for f in fields
            if getfield(d,f) != getfield(Reference,f) 
                # only print if value differs from reference value
                name = rpad(String(f),15)
                comment = getfield(Info,f) 
                data = getfield(d,f) 
                println(io,"    $name  = $(write_vec(data))     # $(comment)")
            end
        end
    end

    println(io,"")
    return nothing
end