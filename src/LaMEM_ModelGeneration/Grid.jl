# This is the data that stores LaMEM grid-related info
export Grid, Write_LaMEM_InputFile, show_short

"""
    Structure that contains the LaMEM grid information

    $(TYPEDFIELDS)

Example 1
====
```julia    
julia> d=LaMEM.Grid(coord_x=[0.0, 0.7, 0.8, 1.0], bias_x=[0.3,1.0,3.0], nel_x=[10,4,2])
LaMEM grid with 1D refinement: 
  nel         : ([10, 4, 2], [16], [16])
  marker/cell : (3, 3, 3)
  x           ϵ [0.0, 0.7, 0.8, 1.0], bias=[0.3, 1.0, 3.0], nseg=3, Δmin=0.025000000000000022, Δmax=0.1499999999999999
  y           ϵ [-10.0 : 0.0]
  z           ϵ [-10.0 : 0.0]
```

Example 2
====
```julia    
julia> d=LaMEM.Grid(nel=(10,20))
LaMEM grid with constant Δ: 
  nel         : ([10], [1], [20])
  marker/cell : (3, 3, 3)
  x           ϵ [-10.0 : 10.0]
  y           ϵ [-10.0 : 0.0]
  z           ϵ [-10.0 : 0.0]
```
"""
mutable struct Grid
    "number of markers/element in x-direction"
    nmark_x :: Int64
    
    "number of markers/element in y-direction"
    nmark_y :: Int64 
    
    "number of markers/element in x-direction"
    nmark_z :: Int64

    "number of elements in x-direction"
    nel_x   :: Vector{Int64}

    "number of elements in y-direction"
    nel_y   :: Vector{Int64}

    "number of elements in z-direction"
    nel_z   :: Vector{Int64}

    "coordinates in x-direction"
    coord_x :: Vector{Float64} 

    "coordinates in y-direction"
    coord_y :: Vector{Float64} 

    "coordinates in z-direction"
    coord_z :: Vector{Float64} 

    "number of segments in x-direction (if we employ variable grid spacing in x-direction)"
    nseg_x  :: Int64

    "number of segments in y-direction (if we employ variable grid spacing in y-direction)"
    nseg_y  :: Int64

    "number of segments in z-direction (if we employ variable grid spacing in z-direction)"
    nseg_z  :: Int64

    "bias in x-direction (if we employ variable grid spacing in x-direction)"
    bias_x  :: Vector{Float64} 

    "bias in y-direction (if we employ variable grid spacing in y-direction)"
    bias_y  :: Vector{Float64} 

    "bias in z-direction (if we employ variable grid spacing in z-direction)"
    bias_z  :: Vector{Float64} 

    "Contains the LaMEM Grid object"
    Grid    :: GeophysicalModelGenerator.LaMEM_grid

    "Phases; 3D phase information"
    Phases  ::  Array{Int32} 

    "Temp; 3D phase information"
    Temp    ::  Array{Float64} 

    "Profile info; in case you perform a simulation along a cross-section through a 3D model you can store the original cross-section here"
    Profile ::  Union{Nothing,CartData, ProfileData}


    # set default parameters
    function Grid(;
        nmark_x=3, nmark_y=3, nmark_z=3,
        nel_x=[16], nel_y=16, nel_z=16,
        coord_x=[-10.0, 10.0], coord_y=[-5.0,5.0], coord_z=[-10.0,0.0],
        x=nothing, y=nothing, z=nothing,
        bias_x=1.0, bias_y=1.0, bias_z=0.0,
        nel=nothing, nmark=nothing, Profile=nothing
    )   
        # In case we have a profile, we use the data of the profile to define the grid
        if !isnothing(Profile)
            if !haskey(Profile.fields,:FlatCrossSection)
                error("The profile does not contain the field `:FlatCrossSection`; Add that with the GeophysicalModelGenerator function FlattenCrossSection, or use the CrossSection routine to generate a profile from volume data.")
            end

            x = [extrema(Profile.fields.FlatCrossSection)...,];
            if isa(Profile, CartData) || isa(Profile, ParaviewData) 
                z = [extrema(Profile.z.val)...,];
            elseif isa(Profile, GeoData) || isa(Profile, UTMData) 
                z = [extrema(Profile.depth.val)...,];
            end

            nel_y = 1
            y = nothing
            if isnothing(nel)
                nel = [nel_x, nel_z]
            end           
        end

        # Define number of elements with a shortcut
        if !isnothing(nel)
            nel_x,nel_y,nel_z = nel[1], 1, nel[end];
            if length(nel)==3
                nel_y = nel[2]
            end

            if nel_y==1 && isnothing(y) && !isnothing(x) && !isnothing(z)
                # 2D case and we did not specify y-coordinates, set y such that the aspect ratio is close to 1
                dx = (x[end]-x[1])/nel_x[1]
                dz = (z[end]-z[1])/nel_z[1]
                dy = (dx+dz)/2
                y = [-dy/2, dy/2]
                
            end
        end

        # alternative (shorter) way to define coordinates
        if !isnothing(x);   coord_x = x;    end
        if !isnothing(y);   coord_y = y;    end
        if !isnothing(z);   coord_z = z;    end

        # Define number of markers/cell with a shortcut
        if !isnothing(nmark)
            nmark_x,nmark_y,nmark_z = nmark[1], 1, nmark[end];
            if length(nmark)==3
                nmark_y = nmark[2]
            end
        end
        nseg_x = length(nel_x)
        nseg_y = length(nel_y)
        nseg_z = length(nel_z)

        # Create a LaMEM grid
        Grid_LaMEM = Create_Grid(nmark_x, nmark_y, nmark_z, nel_x, nel_y, nel_z, coord_x, coord_y, coord_z, 
                                 nseg_x, nseg_y, nseg_z, bias_x, bias_y, bias_z)

        # Define Phase and Temp structs                                 
        Phases  = zeros(Int32,size(Grid_LaMEM.X));
        Temp    = zeros(Float64,size(Grid_LaMEM.X));

        # Create struct
        return new(nmark_x, nmark_y, nmark_z, [nel_x...], [nel_y...], [nel_z...], [coord_x...], [coord_y...], [coord_z...], 
            nseg_x, nseg_y, nseg_z, [bias_x...], [bias_y...], [bias_z...], Grid_LaMEM, Phases, Temp, Profile)
    end

end


"""
This creates a LaMEM grid
"""
function  Create_Grid(nmark_x, nmark_y, nmark_z, nel_x, nel_y, nel_z, coord_x, coord_y, coord_z, 
    nseg_x, nseg_y, nseg_z, bias_x, bias_y, bias_z)

    coord_x  = Float64.(coord_x)
    coord_y  = Float64.(coord_y)
    coord_z  = Float64.(coord_z)
    
    # compute information from file
    W         = coord_x[end]-coord_x[1];
    L         = coord_y[end]-coord_y[1];
    H         = coord_z[end]-coord_z[1];

    nel_x_tot = sum(nel_x);
    nel_y_tot = sum(nel_y);
    nel_z_tot = sum(nel_z);

    nump_x    = nel_x_tot*nmark_x;
    nump_y    = nel_y_tot*nmark_y;
    nump_z    = nel_z_tot*nmark_z;

    # Create 1D coordinate vectors (either regular or refined)
    
    xn, x = GeophysicalModelGenerator.Create1D_grid_vector(coord_x, nel_x, nmark_x, nseg_x, bias_x)
    yn, y = GeophysicalModelGenerator.Create1D_grid_vector(coord_y, nel_y, nmark_y, nseg_y, bias_y)
    zn, z = GeophysicalModelGenerator.Create1D_grid_vector(coord_z, nel_z, nmark_z, nseg_z, bias_z)
    
    # node grid
    Xn,Yn,Zn = GeophysicalModelGenerator.XYZGrid(xn, yn, zn); 

    # marker grid
    X,Y,Z    = GeophysicalModelGenerator.XYZGrid(x, y, z);

    # finish Grid (using a routine of GeophysicalModelGenerator)
    Grid_LaMEM    =  LaMEM_grid(  nmark_x,    nmark_y,    nmark_z,
        nump_x,     nump_y,     nump_z,
        nel_x_tot,  nel_y_tot,  nel_z_tot,    
        W,          L,          H,
        coord_x,    coord_y,    coord_z,
        x,          y,          z,
        X,          Y,          Z,
        xn,         yn,         zn,
        Xn,         Yn,         Zn);
        
    return Grid_LaMEM
end

function show(io::IO, d::Grid)
    if length(d.coord_x) == length(d.coord_y) == length(d.coord_z) 
        println(io, "LaMEM grid with constant Δ: ")
    else
        println(io, "LaMEM grid with 1D refinement: ")
    end
    println(io,"  nel         : ($(d.nel_x), $(d.nel_y), $(d.nel_z))")
    println(io,"  marker/cell : ($(d.nmark_x), $(d.nmark_y), $(d.nmark_z))")
    print_coord(io, "x", d.coord_x, d.bias_x, d.nseg_x, d.Grid.xn_vec)
    print_coord(io, "y", d.coord_y, d.bias_y, d.nseg_y, d.Grid.yn_vec)
    print_coord(io, "z", d.coord_z, d.bias_z, d.nseg_z, d.Grid.zn_vec)
    println(io,"  Phases      : range ϵ [$(minimum(d.Phases)) - $(maximum(d.Phases))]")
    println(io,"  Temp        : range ϵ [$(minimum(d.Temp)) - $(maximum(d.Temp))]")
    
    if !isnothing(d.Profile)
        println(io,"  Profile     : yes")
    end

    return nothing
end

function show_short(io::IO, d::Grid)
    nel   = (sum(d.nel_x), sum(d.nel_y), sum(d.nel_z)) 
    x,y,z = extrema(d.coord_x), extrema(d.coord_y), extrema(d.coord_z)
    str   = "|-- Grid                :  nel=$(nel); xϵ$x, yϵ$y, zϵ$z"
    if !isnothing(d.Profile)
        str *= "; +profile"
    end 
    println(io,str)
    return nothing
end


function print_coord(io, direction, coord, bias, nseg, coord_vec)
    if length(coord)==2
        println(io,"  $direction           ϵ [$(coord[1]) : $(coord[end])]")
    else
        Δmin=minimum(diff(coord_vec))
        Δmax=maximum(diff(coord_vec))
        println(io,"  $direction           ϵ $coord, bias=$bias, nseg=$nseg, Δmin=$Δmin, Δmax=$Δmax")
    end
end


"""
    Write_LaMEM_InputFile(io, d::Grid)

This writes grid info to a LaMEM input file

Example
===
```julia
julia> d=LaMEM.Grid(coord_x=[0.0, 0.7, 0.8, 1.0], bias_x=[0.3,1.0,3.0], nel_x=[10,4,2])
julia> io = open("test.dat","w")
julia> LaMEM.Write_LaMEM_InputFile(io, d)
julia> close(io)
```

"""
function Write_LaMEM_InputFile(io, d::Grid)

    println(io, "#===============================================================================")
    println(io, "# Grid & discretization parameters")
    println(io, "#===============================================================================")
    println(io,"")
    
    println(io,"# Number of cells for all segments")
    println(io,"    nel_x   = $(write_vec(d.nel_x))")
    println(io,"    nel_y   = $(write_vec(d.nel_y))")
    println(io,"    nel_z   = $(write_vec(d.nel_z))")
    
    println(io,"")
    println(io,"# Coordinates of all segments (including start and end points)")
    println(io,"    coord_x = $(write_vec(d.coord_x))")
    if length(d.nel_x)>=2
        println(io,"    nseg_x  = $(write_vec(d.nseg_x))")
        println(io,"    bias_x  = $(write_vec(d.bias_x))")
    end

    println(io,"    coord_y = $(write_vec(d.coord_y))")
    if length(d.nel_y)>=2
        println(io,"    nseg_y  = $(write_vec(d.nseg_y))")
        println(io,"    bias_y  = $(write_vec(d.bias_y))")
    end

    println(io,"    coord_z = $(write_vec(d.coord_z))")
    if length(d.nel_z)>=2
        println(io,"    nseg_z  = $(write_vec(d.nseg_z))")
        println(io,"    bias_z  = $(write_vec(d.bias_z))")
    end

    println(io,"")
    println(io,"# Number of markers per cell")
    println(io,"    nmark_x =  $(d.nmark_x)")
    println(io,"    nmark_y =  $(d.nmark_y)")
    println(io,"    nmark_z =  $(d.nmark_z)")
    
    println(io,"")

    return nothing
end
