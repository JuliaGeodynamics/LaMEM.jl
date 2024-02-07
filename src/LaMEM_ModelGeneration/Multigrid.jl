# This comntains some helper functions to simplify setting up multigrid solvers for LaMEM

export Multigrid

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
    smoothening steps per level 
    """
    smooth::Int64    = 5

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

end


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

function print_mg_level(nel::NTuple; pad=(4,4,4), pad_start="")
    println("$pad_start # | $(lpad(nel[1],pad[1]))×$(lpad(nel[2],pad[2]))×$(lpad(nel[3],pad[3])) |")
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
    println("# total dof: $(digitsep(dof,seperator="'"))")
    
    #
    println(io,"# --- $(d.levels) MG levels ---- ")
    for l=1:d.levels
        print_mg_level(nel, pad=pad)
        
        if all(mod.(nel,2) .== 0) && l<d.levels
            nel = nel./2
            nel = Int64.(nel)
        elseif all(mod.(nel,2) .!= 0)
            println("Cannot create multigrid for level $(l+1)")
        end
    end
    println("-gmg_mg_levels $(d.levels)")

    println("-gmg_pc_type mg")
    println("-gmg_pc_mg_galerkin")
    println("-gmg_pc_mg_type multiplicative")
    println("-gmg_pc_mg_cycle_type v")
    
    min_cores_coarse = prod(nel)
    if d.cores>min_cores_coarse
        println("Warning: Coarse grid solver can only be done on $(min_cores_coarse) cores")
    end

    #println("#  coarse solver: $(d.coarse_solver)")
    #println("#  coarse solver requires <$(prod(nel)) cores")
    
    reduction_factor  = Int64(d.cores/d.cores_coarse)
    println("    # ---- Coarse Grid: $( d.coarse_pc) ")
    print_mg_level(nel, pad=pad, pad_start="   ")
    println("    -crs_ksp_type $(d.coarse_ksp)")

    if d.coarse_pc=="telescope"
        println("    -crs_pc_type telescope")
        println("    -crs_pc_telescope_reduction_factor $(Int64(reduction_factor))")

    elseif d.coarse_pc=="superlu_dist"
        println("    -crs_pc_type lu")
        println("    -crs_pc_factor_mat_solver_type $(d.coarse_pc)")
    elseif d.coarse_pc=="redundant"
        # use a redundant solver
        println("    -crs_pc_type redundant")
        println("    -crs_pc_redundant_number $reduction_factor")
        println("    -crs_pc_redundant_ksp_type $(d.coarse_coarse_ksp)")

        if (d.coarse_coarse_pc=="superlu_dist") || (d.coarse_coarse_pc=="mumps")
            println("    -crs_pc_redundant_pc_type lu")
            println("    -crs_redundant_pc_factor_mat_solver_type $(d.coarse_coarse_pc)")
        else
            println("    -crs_pc_redundant_pc_type $(d.coarse_coarse_pc)")
        end
    else
        println("    -crs_pc_type $(d.coarse_pc)")
    end
    
    

    # print fields
 #   for f in fields
 #       col = gettext_color(d,Reference, f)
 #       printstyled(io,"  $(rpad(String(f),15)) = $(getfield(d,f)) \n", color=col)        
 #   end
    
    return nothing
end
