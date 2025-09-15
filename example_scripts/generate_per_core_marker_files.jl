module generate_per_core_marker_files_utils

export crop_bounds, get_proc_bound, get_proc_grid, add_box2!, get_particles_distribution, get_LaMEM_grid_info, get_processor_partitioning_info, check_markers_directory, setup_model_domain, LaMEM_partitioning_info

using GeophysicalModelGenerator

struct LaMEM_partitioning_info <: AbstractGeneralGrid

    # Number of processors in each direction
    nProcX::Int64
    nProcY::Int64
    nProcZ::Int64
    # Number of nodes in each direction
    nNodeX::Int64
    nNodeY::Int64
    nNodeZ::Int64
    # Coordinates of the nodes end of each processor
    xc
    yc
    zc

end

struct particles_distribution <: AbstractGeneralGrid

    x_start
    x_end
    y_start
    y_end
    z_start
    z_end

end

function Base.show(io::IO, d::LaMEM_partitioning_info)

    println(io, "LaMEM Partitioning info: ")
    println(io, "  nProcX : $(d.nProcX)")
    println(io, "  nProcY : $(d.nProcY)")
    println(io, "  nProcZ : $(d.nProcZ)")
    println(io, "  nNodeX : $(d.nNodeX)")
    println(io, "  nNodeY : $(d.nNodeY)")
    println(io, "  nNodeZ : $(d.nNodeZ)")
    println(io, "  xc     : $(d.xc)")
    println(io, "  yc     : $(d.yc)")

    return println(io, "  zc     : $(d.zc)")

end

function check_markers_directory(directory)

    if !isdir(directory)
        mkdir(directory)
    end

end

function get_LaMEM_grid_info(file; args::Union{String, Nothing} = nothing)

    # read information from file
    nmark_x = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "nmark_x", Int64, args = args)
    nmark_y = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "nmark_y", Int64, args = args)
    nmark_z = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "nmark_z", Int64, args = args)

    nel_x = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "nel_x", Int64, args = args)
    nel_y = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "nel_y", Int64, args = args)
    nel_z = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "nel_z", Int64, args = args)

    parsed_x = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "coord_x", Float64, args = args)
    parsed_y = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "coord_y", Float64, args = args)
    parsed_z = GeophysicalModelGenerator.ParseValue_LaMEM_InputFile(file, "coord_z", Float64, args = args)

    # compute information from file
    W = parsed_x[end] - parsed_x[1]
    L = parsed_y[end] - parsed_y[1]
    H = parsed_z[end] - parsed_z[1]

    nel_x_tot = sum(nel_x)
    nel_y_tot = sum(nel_y)
    nel_z_tot = sum(nel_z)

    nump_x = nel_x_tot * nmark_x
    nump_y = nel_y_tot * nmark_y
    nump_z = nel_z_tot * nmark_z

    # finish Grid
    Grid = LaMEM_grid(
        nmark_x, nmark_y, nmark_z,
        nump_x, nump_y, nump_z,
        nel_x,   nel_y,   nel_z,
        W, L, H,
        parsed_x, parsed_y, parsed_z,
        [],[],[],
        [],[],[],
        [],[],[],
        [],[],[]
    )

    return Grid

end

function get_particles_distribution(Grid,P)

    # get number of processors and processor coordnate bounds
    nProcX = P.nProcX;
    nProcY = P.nProcY;
    nProcZ = P.nProcZ;
    xc     = P.xc;
    yc     = P.yc;
    zc     = P.zc;

    (num, num_i, num_j, num_k) = get_numscheme(nProcX, nProcY, nProcZ);

    dx     = Grid.W/Grid.nump_x;
    dy     = Grid.L/Grid.nump_y;
    dz     = Grid.H/Grid.nump_z;

    # % Get particles of respective procs
    # % xi - amount of particles in x direction in each core
    # % ix_start - indexes where they start for each core
    (xi,ix_start,ix_end) = get_ind2(dx,xc,nProcX);
    (yi,iy_start,iy_end) = get_ind2(dy,yc,nProcY);
    (zi,iz_start,iz_end) = get_ind2(dz,zc,nProcZ);

    x_start = ix_start[num_i[:]]
    y_start = iy_start[num_j[:]]
    z_start = iz_start[num_k[:]]
    x_end = ix_end[num_i[:]]
    y_end = iy_end[num_j[:]]
    z_end = iz_end[num_k[:]]

    p_dist = particles_distribution(x_start,x_end,y_start,y_end,z_start,z_end);

    return p_dist

end

function  get_numscheme(Nprocx,Nprocy,Nprocz)

    n = zeros(Int64, Nprocx * Nprocy * Nprocz)
    nix = zeros(Int64, Nprocx * Nprocy * Nprocz)
    njy = zeros(Int64, Nprocx * Nprocy * Nprocz)
    nkz = zeros(Int64, Nprocx * Nprocy * Nprocz)

    num = 0
    for k in 1:Nprocz
        for j in 1:Nprocy
            for i in 1:Nprocx
                num = num + 1
                n[num] = num
                nix[num] = i
                njy[num] = j
                nkz[num] = k
            end
        end
    end

    return n,nix,njy,nkz

end

function get_ind2(dx,xc,Nprocx)

    if Nprocx == 1

        xi       = [xc[end] - xc[1]]/dx;
        ix_start = [1];
        ix_end   = [xc[end] - xc[1]]/dx;

    else
        xi = zeros(Int64, Nprocx)
        for k = 1:Nprocx
            xi[k] = round((xc[k+1] - xc[k])/dx);
        end

        ix_start = cumsum([0; xi[1:(end - 1)]]) .+ 1
        ix_end = cumsum(xi[1:end])

    end

    return xi,ix_start,ix_end

end

function crop_bounds(uncropped_bounds, proc_bounds, x, y, z)

    # Crop boundaries from the whole model to only the extent of the current processor
    vecs       = [x, y, z]  
    new_bounds = [zeros(size(vecs[i])) for i in eachindex(vecs)]
    for i in eachindex(vecs)
        vec = vecs[i]
        test_bound = uncropped_bounds[i]
        mask_bound = proc_bounds[i]

        new_bound = Float64[]

        if test_bound[1] < test_bound[2]
            if test_bound[1] <= mask_bound[1]
                if test_bound[2] >= mask_bound[2]
                    new_bound = [mask_bound[1], mask_bound[2]]
                elseif test_bound[2] >= mask_bound[1]
                    new_bound = [mask_bound[1], test_bound[2]]
                end
            end

            if test_bound[1] >= mask_bound[1]
                if test_bound[2] <= mask_bound[2]
                    new_bound = [closest_val(test_bound[1], vec), closest_val(test_bound[2], vec)]
                elseif test_bound[1] <= mask_bound[2] && test_bound[2] >= mask_bound[2]
                    new_bound = [test_bound[1], mask_bound[2]]
                end
            end
        else
            error("Wrong coordinates assignment")
        end

        if isempty(new_bound)
            return []
        end
        new_bounds[i] = new_bound
    end

    return new_bounds

end

function closest_val(val, vec)
    return  vec[argmin(abs.(vec .- val))]
end

function get_proc_bound(Grid,p_dist,proc_num)

    dx           = Grid.W/Grid.nump_x;
    dy           = Grid.L/Grid.nump_y;
    dz           = Grid.H/Grid.nump_z;

    parsed_x     = Grid.coord_x
    parsed_y     = Grid.coord_y
    parsed_z     = Grid.coord_z

    model_x      = [ parsed_x[1] + dx/2, parsed_x[end] - dx/2 ]
    model_y      = [ parsed_y[1] + dy/2, parsed_y[end] - dy/2 ]
    model_z      = [ parsed_z[1] + dz/2, parsed_z[end] - dz/2 ]

    x_left       = model_x[1];
    y_front      = model_y[1];
    z_bot        = model_z[1];

    x_start      = p_dist.x_start;
    x_end        = p_dist.x_end;
    y_start      = p_dist.y_start;
    y_end        = p_dist.y_end;
    z_start      = p_dist.z_start;
    z_end        = p_dist.z_end;

    x_proc_bound = [ x_left  + dx*( x_start[proc_num] - 1 ), x_left  + dx*( x_end[proc_num] - 1 ) ];
    y_proc_bound = [ y_front + dy*( y_start[proc_num] - 1 ), y_front + dy*( y_end[proc_num] - 1 ) ];
    z_proc_bound = [ z_bot   + dz*( z_start[proc_num] - 1 ), z_bot   + dz*( z_end[proc_num] - 1 ) ];

    return [ x_proc_bound, y_proc_bound, z_proc_bound ]

end

function get_proc_grid(Grid_info,p_dist,proc_bounds,proc_num,RandomNoise)

    x_proc_bound  = proc_bounds[1];
    y_proc_bound  = proc_bounds[2];
    z_proc_bound  = proc_bounds[3];

    loc_nump_x = p_dist.x_end[proc_num] - p_dist.x_start[proc_num] + 1
    loc_nump_y = p_dist.y_end[proc_num] - p_dist.y_start[proc_num] + 1
    loc_nump_z = p_dist.z_end[proc_num] - p_dist.z_start[proc_num] + 1
    
    loc_nel_x = loc_nump_x/Grid_info.nmark_x
    loc_nel_y = loc_nump_y/Grid_info.nmark_y
    loc_nel_z = loc_nump_z/Grid_info.nmark_z

    x  = range(x_proc_bound[1], x_proc_bound[2], length=loc_nump_x)
    y  = range(y_proc_bound[1], y_proc_bound[2], length=loc_nump_y)
    z  = range(z_proc_bound[1], z_proc_bound[2], length=loc_nump_z)

    # marker grid
    X, Y, Z = GeophysicalModelGenerator.xyz_grid(x, y, z)

    W = x_proc_bound[2] - x_proc_bound[1]
    L = y_proc_bound[2] - y_proc_bound[1]
    H = z_proc_bound[2] - z_proc_bound[1]

    if RandomNoise == 1
        dx = x[2]   - x[1]
        dy = y[2]   - y[1]
        dz = z[2]   - z[1]
        dXNoise = zeros(size(X)) + dx;
        dYNoise = zeros(size(Y)) + dy;
        dZNoise = zeros(size(Z)) + dz;
    
        dXNoise = dXNoise.*(rand(size(dXNoise))-0.5);
        dYNoise = dYNoise.*(rand(size(dYNoise))-0.5);
        dZNoise = dZNoise.*(rand(size(dZNoise))-0.5);
    
        Xpart   = X + dXNoise;
        Ypart   = Y + dYNoise;
        Zpart   = Z + dZNoise;
    
        X       = Xpart;
        Y       = Ypart;
        Z       = Zpart;
        x       = X(1,:,1);
        y       = Y(:,1,1);
        z       = Z(1,1,:);
    
    end

    Grid = LaMEM_grid(
        Grid_info.nmark_x, Grid_info.nmark_y, Grid_info.nmark_z,
        loc_nump_x, loc_nump_y, loc_nump_z,
        loc_nel_x, loc_nel_y, loc_nel_z,
        W, L, H,
        x, y, z,
        x, y, z,
        X, Y, Z,
        [], [], [],
        [], [], []
    )
    return Grid

end

function add_box2!(
        Phase, Temp, Grid::AbstractGeneralGrid,       # required input
        bounds;     # limits of the box
        Origin   = nothing, StrikeAngle = 0, DipAngle = 0,      # origin & dip/strike
        phase    = ConstantPhase(0),                       # Sets the phase number(s) in the box
        T        = nothing,                              # Sets the thermal structure (various functions are available)
        segments = nothing,                       # Allows defining multiple ridge segments
        cell     = false 
        )

    if isempty(bounds)

        return nothing
        # if isa(xlim, Nothing) || isa(zlim, Nothing) Submit maybe to PR
        #     return nothing

    else

        xlim=(Tuple(bounds[1])) 
        ylim=(Tuple(bounds[2])) 
        zlim=(Tuple(bounds[3]))

        add_box!( 
                Phase, Temp, Grid;       # required input
                xlim     = xlim, ylim = ylim, zlim = zlim,     # limits of the box
                Origin   = Origin, StrikeAngle = StrikeAngle, DipAngle = DipAngle,      # origin & dip/strike
                phase    = phase,                          # Sets the phase number(s) in the box
                T        = T,                                  # Sets the thermal structure (various functions are available)
                cell     = cell )

    end

end

"""
    decompose_mpi_ranks(total_ranks::Int, nx::Int, ny::Int, nz::Int) -> Tuple{Int,Int,Int}

Decompose total number of MPI ranks into a 3D processor grid (px, py, pz),
optimizing for cell aspect ratio closest to 1.0.
"""
function decompose_mpi_ranks(total_ranks::Int, nx::Int, ny::Int, nz::Int)
    # Get all factors of total_ranks
    factors = get_factors(total_ranks)
    
    # Initialize best configuration
    best_px = 1
    best_py = 1
    best_pz = 1
    best_metric = Inf
    
    # Try all possible combinations of factors
    for px in factors
        remaining = total_ranks ÷ px
        rem_factors = get_factors(remaining)
        
        for py in rem_factors
            pz = remaining ÷ py
            
            # Skip invalid combinations
            if px * py * pz != total_ranks
                continue
            end
            
            # Calculate local grid sizes
            local_nx = nx / px
            local_ny = ny / py
            local_nz = nz / pz
            
            # Calculate aspect ratios (always ≥ 1.0)
            ar_xy = max(local_nx/local_ny, local_ny/local_nx)
            ar_xz = max(local_nx/local_nz, local_nz/local_nx)
            ar_yz = max(local_ny/local_nz, local_nz/local_ny)
            
            # Metric: average deviation from aspect ratio of 1.0
            metric = (ar_xy + ar_xz + ar_yz) / 3.0
            
            # Update best configuration if this one is better
            # If metrics are equal, prefer larger px
            if metric < best_metric || 
               (isapprox(metric, best_metric, rtol=1e-10) && px > best_px)
                best_metric = metric
                best_px = px
                best_py = py
                best_pz = pz
            end
        end
    end
    
    # Calculate and print aspect ratios for chosen decomposition
    local_nx = nx / best_px
    local_ny = ny / best_py
    local_nz = nz / best_pz

    println("Maximum aspect ratio: $(max(local_nx/local_ny, local_ny/local_nx,
                                    local_nx/local_nz, local_nz/local_nx,
                                    local_ny/local_nz, local_nz/local_ny))")
    
    return (best_px, best_py, best_pz)
end

"""
Get all factors of a number n
"""
function get_factors(n::Int)
    factors = Int[]
    for i in 1:isqrt(n)
        if n % i == 0
            push!(factors, i)
            if i != n÷i
                push!(factors, n÷i)
            end
        end
    end
    sort!(factors)
    return factors
end
"""
    setup_model_domain(coord_x::Vector{Float64}, 
                      coord_y::Vector{Float64}, 
                      coord_z::Vector{Float64},
                      nx::Int, ny::Int, nz::Int, 
                      n_ranks::Int) -> ModelDomain

Setup model domain decomposition using domain boundaries and resolution.

Parameters:
- coord_x, coord_y, coord_z: 2-element vectors specifying [min, max] for each direction
- nx, ny, nz: Number of cells in each direction
- n_ranks: Total number of MPI ranks

Returns:
- ModelDomain struct containing all domain decomposition information
"""
function setup_model_domain(coord_x::Vector{Float64}, 
                          coord_y::Vector{Float64}, 
                          coord_z::Vector{Float64},
                          nx::Int, ny::Int, nz::Int, 
                          n_ranks::Int)
    
    # Verify input vectors have correct size
    if any(length.([coord_x, coord_y, coord_z]) .!= 2)
        error("coord_x, coord_y, and coord_z must be 2-element vectors [min, max]")
    end
    
    # Generate full coordinate vectors
    nnodx = nx + 1
    nnody = ny + 1
    nnodz = nz + 1
    
    xcoor = collect(range(coord_x[1], coord_x[2], length=nnodx))
    ycoor = collect(range(coord_y[1], coord_y[2], length=nnody))
    zcoor = collect(range(coord_z[1], coord_z[2], length=nnodz))
    
    # Decompose MPI ranks into 3D processor grid
    Nprocx, Nprocy, Nprocz = decompose_mpi_ranks(n_ranks, nx, ny, nz)
    
    # Calculate subdomain divisions
    function calculate_domain_divisions(N::Int, nproc::Int)
        base_size = div(N, nproc)
        remainder = N % nproc
        
        indices = zeros(Int, nproc + 1)
        indices[1] = 1
        
        for i in 1:nproc
            local_size = base_size + (i <= remainder ? 1 : 0)
            indices[i + 1] = indices[i] + local_size
        end
        
        return indices
    end
    
    # Calculate divisions for each direction
    ix = calculate_domain_divisions(nx, Nprocx)
    iy = calculate_domain_divisions(ny, Nprocy)
    iz = calculate_domain_divisions(nz, Nprocz)
    
    P = LaMEM_partitioning_info(
        Nprocx, Nprocy, Nprocz,
        nnodx, nnody, nnodz, 
        xcoor[ix], ycoor[iy],zcoor[iz]
        )

        xcoor=[]
        ycoor=[]
        zcoor=[]

    return P

end

end # module
