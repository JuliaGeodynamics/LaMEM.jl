# This comntains some helper functions to simplify setting up multigrid solvers for LaMEM

export Multigrid, print_short

"""
    Structure that has info about setting up multigrid for LaMEM

    $(TYPEDFIELDS)

"""
Base.@kwdef mutable struct Multigrid
    """
    Number of elements at the fine level
    """
    nel::NTuple{3,Int64} = (64,64,64)

    """
    Number of levels
    """
    levels::Int64    = 3
     
    """
    number of smoothening steps per level 
    """
    smooth::Int64    = 5

    """
    factor for jacbi smoothener oer level
    """
    smooth_jacobi_factor::Float64    = 0.5

    """
    smoother used at every level
    """
    smoother::String    = "chebyshev"


    """
    coarse grid ksp type preonly or fgmres
    """
    coarse_ksp::String    = "preonly"

    """
    coarse grid pc type ["superlu_dist", "mumps", "gamg", "telescope","redundant"]
    """
    coarse_pc::String    = "superlu_dist"

    """
    coarse coarse grid solver in case we use redundant or telescope coarse grid solves
    """
    coarse_coarse_pc::String    = "superlu_dist"

    """
    coarse coarse grid solver in case we use redundant or telescope coarse grid solves
    """
    coarse_coarse_ksp::String    = "preonly"

    """
    number of cores used in the simulation
    """
    cores::Int64    = 128

    """
    number of cores used for coarse grid solver (in case we use pctelescope)
    """
    cores_coarse::Int64    = 16

    """
    GAMG threshold
    """
    gamg_threshold::Float64    = 0.05


    """
    GAMG coarse grid equation limit 
    """
    gamg_coarse_eq_limit::Int64    = 1000

    """
    GAMG repartition coarse grids? (default=false)
    """
    gamg_repartition::Bool    = false

    """
    GAMG parallel coarse grid solver? (default=false)
    """
    gamg_parallel_coarse::Bool    = false
    

end

#=
-crs_telescope_pc_gamg_type <now agg : formerly agg>: Type of AMG method (one of) geo agg classical (PCGAMGSetType)
-crs_telescope_pc_gamg_repartition: <FALSE : FALSE> Repartion coarse grids (PCGAMGSetRepartition)
-crs_telescope_pc_gamg_use_sa_esteig: <TRUE : TRUE> Use eigen estimate from smoothed aggregation for smoother (PCGAMGSetUseSAEstEig)
-crs_telescope_pc_gamg_reuse_interpolation: <TRUE : TRUE> Reuse prolongation operator (PCGAMGReuseInterpolation)
-crs_telescope_pc_gamg_asm_use_agg: <FALSE : FALSE> Use aggregation aggregates for ASM smoother (PCGAMGASMSetUseAggs)
-crs_telescope_pc_gamg_use_parallel_coarse_grid_solver: <FALSE : FALSE> Use parallel coarse grid solver (otherwise put last grid on one process) (PCGAMGSetUseParallelCoarseGridSolve)
-crs_telescope_pc_gamg_cpu_pin_coarse_grids: <FALSE : FALSE> Pin coarse grids to the CPU (PCGAMGSetCpuPinCoarseGrids)
-crs_telescope_pc_gamg_coarse_grid_layout_type <now spread : formerly spread> compact: place reduced grids on processes in natural order; spread: distribute to whole machine for more memory bandwidth (choose one of) compact spread (PCGAMGSetCoarseGridLayoutType)
=#

"""
Returns the total degrees of freedom for a LaMEM simulation
"""
function compute_dof(nel::NTuple{3,Int64})
   
    nel_Vx = nel .+ (1,0,0)
    nel_Vy = nel .+ (0,1,0)
    nel_Vz = nel .+ (0,0,1)
    
    dof_vel = prod(nel .+ nel_Vx .+ nel_Vy .+ nel_Vz)
    dof_T   = prod(nel)
    dof     = dof_vel + dof_T

    return dof
end


"""
    digitsep(value::Integer; separator=",", per_separator=3)

Convert an integer to a string, separating each `per_separator` digits by
`separator`.

    digitsep(12345678)  # "12,345,678"
    digitsep(12345678, seperator= "'")  # "12'345'678"
    digitsep(12345678, seperator= "-", per_separator=4)  # "1234-5678"
"""
function digitsep(value::Integer; seperator=",", per_separator=3)
    isnegative = value < zero(value)
    value = string(abs(value))  # Stringify, no seperators.
    # Figure out last character index of each group of digits.
    group_ends = reverse(collect(length(value):-per_separator:1))
    groups = [value[max(end_index - per_separator + 1, 1):end_index]
              for end_index in group_ends]
    return (isnegative ? "-" : "") * join(groups, seperator)
end

function print_mg_level(io::IO, nel::NTuple; pad=(4,4,4), pad_start="", pad_end="")
    println(io, "$(pad_start)# | $(lpad(nel[1],pad[1]))×$(lpad(nel[2],pad[2]))×$(lpad(nel[3],pad[3])) | $(pad_end)")
end

function max_pad(nel)
    pad = (length(String("$(nel[1])")), length(String("$(nel[2])")), length(String("$(nel[3])"))) 
    return pad
end


# Print info about the structure
function show(io::IO, d::Multigrid)
    nel = d.nel
    pad = max_pad(nel)

    dof = compute_dof(nel);   # compute degrees of freedom
    println(io,"# total dof: $(digitsep(dof,seperator="'"))")
    println(io,"# using $(d.cores) cores")
    
    #
    println(io,"# --- $(d.levels) MG levels ---- ")
    for l=1:d.levels
        if l>1
            pad_end=""
        else
            pad_end=" - $(d.cores) cores"
        end
        print_mg_level(io, nel, pad=pad, pad_end=pad_end)

        if all(mod.(nel,2) .== 0) && l<d.levels
            nel = nel./2
            nel = Int64.(nel)
        elseif all(mod.(nel,2) .!= 0)
            println(io,"Cannot create multigrid for level $(l+1)")
        end
    end
    println(io,"-gmg_pc_mg_levels $(d.levels)")

    # Setup main multigrid
    println(io,"-gmg_pc_type mg")
    println(io,"-gmg_pc_mg_galerkin")
    println(io,"-gmg_pc_mg_type multiplicative")
    println(io,"-gmg_pc_mg_cycle_type v")
    
    # Setup smoothener per level
    if d.smoother=="jacobi"
        println(io,"-gmg_mg_levels_ksp_type richardson")
        println(io,"-gmg_mg_levels_ksp_richardson_scale 0.5")
        println(io,"-gmg_mg_levels_pc_type jacobi")
	elseif d.smoother=="chebyshev"
        println(io,"-gmg_mg_levels_ksp_type chebyshev")
    else
        println(io,"-gmg_mg_levels_pc_type $(d.smoother)")
    end
    println(io,"-gmg_mg_levels_ksp_max_it $(d.smooth)")
    println(io," ")

    min_cores_coarse = prod(nel)
    if d.cores>min_cores_coarse
        println(io,"Warning: Coarse grid solver can only be done on $(min_cores_coarse) cores")
    end

    println(io,"    # ---- Coarse Grid: $( d.coarse_pc) ")

    num_cores_coarse = d.cores_coarse
    if  d.coarse_pc=="superlu_dist" ||  d.coarse_pc=="mumps"
        num_cores_coarse = d.cores
    end

    print_mg_level(io, nel, pad=pad, pad_start="    ", pad_end = " - $num_cores_coarse cores")
    reduction_factor  = Int64(d.cores/d.cores_coarse)
    if d.coarse_pc=="telescope"
        println(io,"    -crs_ksp_type $(d.coarse_ksp)")
        println(io,"    -crs_pc_type telescope")
        println(io,"    -crs_pc_telescope_reduction_factor $(Int64(reduction_factor))")

        if (d.coarse_coarse_pc=="superlu_dist") || (d.coarse_coarse_pc=="mumps")
            println(io,"    -crs_telescope_ksp_type preonly")
            println(io,"    -crs_telescope_pc_type lu")
            println(io,"    -crs_telescope_pc_factor_mat_solver_type $(d.coarse_coarse_pc)")

        elseif (d.coarse_coarse_pc=="gamg") 
                println(io,"    -crs_telescope_ksp_type $(d.coarse_coarse_ksp)")
                println(io,"    -crs_telescope_pc_type gamg")
                println(io,"        # ---- GAMG coarse grid solver")
                println(io,"        -crs_telescope_pc_gamg_coarse_eq_limit $(d.gamg_coarse_eq_limit)")
                println(io,"        -crs_telescope_pc_gamg_threshold $(d.gamg_threshold)")
                println(io,"        -crs_telescope_pc_gamg_repartition $(Int64(d.gamg_repartition))")
                println(io,"        -crs_telescope_pc_gamg_use_parallel_coarse_grid_solver $(Int64(d.gamg_parallel_coarse))")
            
        else
            println(io,"    -crs_telescope_ksp_type $(d.coarse_coarse_ksp)")
            println(io,"    -crs_telescope_pc_type $(d.coarse_coarse_pc)")
        end

    elseif d.coarse_pc=="superlu_dist"
        println(io,"    -crs_ksp_type $(d.coarse_ksp)")
        println(io,"    -crs_pc_type lu")
        println(io,"    -crs_pc_factor_mat_solver_type $(d.coarse_pc)")

    elseif d.coarse_pc=="redundant"
      
        # use a redundant solver
        println(io,"    -crs_ksp_type $(d.coarse_ksp)")
        println(io,"    -crs_pc_type redundant")
        println(io,"    -crs_pc_redundant_number $reduction_factor")
        println(io,"    -crs_pc_redundant_ksp_type $(d.coarse_coarse_ksp)")

        if (d.coarse_coarse_pc=="superlu_dist") || (d.coarse_coarse_pc=="mumps")
            println(io,"    -crs_pc_redundant_pc_type lu")
            println(io,"    -crs_redundant_pc_factor_mat_solver_type $(d.coarse_coarse_pc)")
        else
            println(io,"    -crs_pc_redundant_pc_type $(d.coarse_coarse_pc)")
        end
    else
        println(io,"    -crs_pc_type $(d.coarse_pc)")
    end

    
    return nothing
end


"""
This creates a single string, so we can use it in the command line
"""
function print_short(d::Multigrid)

    # get string with output
    io = IOBuffer();
    show(IOContext(io, :limit => true, :displaysize => (10, 10)), "text/plain", d);
    s = String(take!(io));

    # vector with lines
    s_vec = split(s,"\n")

    # remove comments
    s_vec = strip.(s_vec)
    s_vec = s_vec[startswith.(s_vec,"#") .== false]
    s_vec = s_vec[length.(s_vec).>0]    # remove empty lines

    # create single string
    str = " ";
    for s in s_vec
        str *= s * " ";
    end

    return str
end