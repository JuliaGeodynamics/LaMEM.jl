# FastScape surface processes (surf_mode = 2), written as a <FastScapeStart>/<FastScapeEnd> block

export FastScape, write_LaMEM_inputFile

"""
    Structure that contains the parameters of the FastScape landscape-evolution model, which
    replaces the built-in erosion/sedimentation when `FreeSurface(surf_mode=2, FastScape=FastScape(...))`
    is used. Requires a LaMEM binary compiled with FastScape (LaMEM_jll >= 3.2.0).

    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct FastScape
    "LaMEM grid type flag [0-uniform, 1-non-uniform]; must be consistent with the LaMEM grid"
    non_uniform_grid::Int64 = 0

    "dimensionality flag [0-3D LaMEM model, 1-2D model]; in 2D the 1D LaMEM surface is extended in the 2nd horizontal direction"
    fs2D::Int64 = 0

    "[only used if fs2D=1] length of the FastScape domain in the extended direction [length units, e.g. km]"
    extendedRange::Float64 = 100.0

    "[only used if fs2D=1 and non_uniform_grid=0] number of FastScape nodes in the extended direction (>2)"
    extendedNodes::Int64 = 101

    "surface-grid refinement factor; a factor n inserts n-1 equally spaced points between adjacent nodes in each direction"
    fs_refine::Int64 = 1

    "maximum FastScape substep [time units, e.g. Myr]; larger LaMEM steps are split into several FastScape substeps"
    max_fs_dt::Float64 = 0.01

    "LaMEM phase ID assigned to newly deposited sediment"
    sed_phases::Int64 = 1

    "topographic BC, 4 digits (one per boundary, same order as `vel_boundary`): 0-reflective/no-flux, 1-fixed height/open (sediment may leave)"
    topo_boundary::String = "1111"

    "surface velocity BC, 4 digits (one per boundary): 1-zero velocity, 0-keep velocity transferred from LaMEM; digit order: bottom (y-min), right (x-max), top (y-max), left (x-min)"
    vel_boundary::String = "0000"

    "add random perturbation to the initial topography"
    random_noise::Int64 = 1

    "write FastScape output every n coupled time steps"
    surf_out_nstep::Int64 = 1

    "vertical (z) exaggeration factor applied to the output"
    vec_times::Float64 = 1.0

    "bedrock river incision coefficient Kf [m^(1-2m)/yr]"
    kf::Float64 = 1e-6

    "sediment river incision coefficient; if < 0, kf is used for both"
    kfsed::Float64 = -1.0

    "drainage area exponent in the stream power law"
    m::Float64 = 0.4

    "local slope exponent in the stream power law"
    n::Float64 = 1.0

    "bedrock transport coefficient (hillslope diffusivity) [m^2/yr]"
    kd::Float64 = 1e-2

    "sediment transport coefficient; if < 0, kd is used for both"
    kdsed::Float64 = -1.0

    "dimensionless bedrock deposition coefficient (enriched stream power law)"
    g::Float64 = 0.0

    "dimensionless sediment deposition coefficient; if < 0, g is used for both"
    gsed::Float64 = 0.0

    "slope exponent for multi-direction flow routing"
    p::Float64 = -2.0

    "marine transport & compaction flag [0-off, 1-on]"
    set_marine::Int64 = 0

    "[only used if set_marine=1] sea level [m]"
    sealevel::Float64 = 0.0

    "[only used if set_marine=1] reference (surface) porosity of silt"
    poroSilt::Float64 = 0.0

    "[only used if set_marine=1] reference (surface) porosity of sand"
    poroSand::Float64 = 0.0

    "[only used if set_marine=1] e-folding depth of the porosity law for silt [m]"
    zporoSilt::Float64 = 1e3

    "[only used if set_marine=1] e-folding depth of the porosity law for sand [m]"
    zporoSand::Float64 = 1e3

    "[only used if set_marine=1] silt fraction of material supplied from the continental domain"
    ratio::Float64 = 0.5

    "[only used if set_marine=1] averaging depth used to solve the silt/sand transport equation [m]"
    depth_siltsand_solve::Float64 = 1e2

    "[only used if set_marine=1] marine transport coefficient for silt [m^2/yr]"
    kdsSilt::Float64 = 3e2

    "[only used if set_marine=1] marine transport coefficient for sand [m^2/yr]"
    kdsSand::Float64 = 1.5e2
end

# Print info about the structure
function show(io::IO, d::FastScape)
    Reference = FastScape()
    println(io, "LaMEM FastScape parameters: ")
    for f in fieldnames(typeof(d))
        col = gettext_color(d, Reference, f)
        printstyled(io, "  $(rpad(String(f),20)) = $(getfield(d,f)) \n", color=col)
    end
    return nothing
end

# Fields that only apply to a 2D model or with marine transport are written only then
function is_written(d::FastScape, f::Symbol)
    marine = (:sealevel, :poroSilt, :poroSand, :zporoSilt, :zporoSand, :ratio, :depth_siltsand_solve, :kdsSilt, :kdsSand)
    f == :extendedRange && return d.fs2D == 1
    f == :extendedNodes && return d.fs2D == 1 && d.non_uniform_grid == 0
    f in marine && return d.set_marine == 1
    return true
end

"""
    write_LaMEM_inputFile(io, d::FastScape)
Writes the `<FastScapeStart>` ... `<FastScapeEnd>` block to file
"""
function write_LaMEM_inputFile(io, d::FastScape)
    println(io, "#===============================================================================")
    println(io, "# FastScape surface processes (surf_mode = 2)")
    println(io, "#===============================================================================")
    println(io, "")
    println(io, "    <FastScapeStart>")
    for f in fieldnames(typeof(d))
        is_written(d, f) || continue
        name = rpad(String(f), 20)
        comment = get_doc(FastScape, f)
        println(io, "        $name  = $(write_vec(getfield(d,f)))     # $(comment)")
    end
    println(io, "    <FastScapeEnd>")
    println(io, "")
    return nothing
end
