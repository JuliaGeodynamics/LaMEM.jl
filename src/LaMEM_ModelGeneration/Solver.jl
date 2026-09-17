# Solver options

export Solver, write_LaMEM_inputFile

"""
    Structure that contains the LaMEM solver options (the `<SolverOptionsStart>` block of a
    LaMEM input file, LaMEM >= 3.0). Every field has LaMEM's own default value; only fields
    that differ from the default are written to the input file. Tolerance fields are vectors
    `[rtol, atol, maxit]` (or `[rtol, maxit]`), where `atol = -1` means automatic.

    Raw PETSc options can still be passed through `PETSc_options`.

    The LaMEM 2.x keywords `SolverType`, `DirectSolver`, `DirectPenalty`, `MGLevels`, `MGSweeps`,
    `MGSmoother`, `MGJacobiDamp`, `MGCoarseSolver`, `MGRedundantNum` and `MGRedundantSolver` are
    still accepted by the constructor and translated to the new options (with a warning).

    $(TYPEDFIELDS)
"""
mutable struct Solver
    "specify solver options explicitly (skip the automatic defaults) [0/1]"
    skip_defaults::Int64

    "show the linear solver configuration [0/1]"
    view_solvers::Int64

    "show the convergence of the linear iterations [0/1]"
    monitor_solvers::Int64

    "linear problem: skip the nonlinear iterations [0/1]"
    set_linear_problem::Int64

    "continue the simulation if the nonlinear solver diverged, unless a severe reason is detected [0/1]"
    continue_on_fail::Int64

    "nonlinear solver: rtol, atol, maxit (atol = -1: automatic)"
    nonlinear_tolerances::Vector{Float64}

    "linear solver: rtol, atol, maxit (atol = -1: automatic)"
    linear_tolerances::Vector{Float64}

    "Picard/Newton switching: picard rtol, picard minit, newton rtol, newton maxit"
    picard_to_newton::Vector{Float64}

    "use a line search in the nonlinear solver [0/1]"
    use_line_search::Int64

    "use Eisenstat-Walker adaptive linear tolerances [0/1]"
    use_eisenstat_walker::Int64

    "use a matrix-free Jacobian [0/1]"
    use_mat_free_jac::Int64

    "Stokes solver [`\"coupled_direct\"`, `\"block_direct\"`, `\"coupled_mg\"`, `\"block_mg\"`, `\"wbfbt\"`]"
    stokes_solver::String

    "direct solver package [`\"mumps\"`, `\"superlu_dist\"`, `\"default\"` (PETSc LU, sequential only)]"
    direct_solver_type::String

    "block solves in block_mg and wbfbt: rtol, maxit"
    block_tolerances::Vector{Float64}

    "penalty parameter (only for the direct solvers)"
    penalty::Float64

    "number of multigrid levels (-1: automatic)"
    num_mg_levels::Int64

    "number of top matrix-free multigrid levels (only for coupled_mg)"
    num_mat_free_levels::Int64

    "smoother preset [`\"light\"` (richardson + jacobi), `\"intermediate\"` (chebyshev + sor), `\"heavy\"` (gmres + bjacobi)]"
    smoother_type::String

    "smoother KSP [`\"richardson\"`, `\"chebyshev\"`, `\"gmres\"`]"
    smoother_ksp::String

    "smoother PC [`\"jacobi\"`, `\"sor\"`, `\"bjacobi\"`, `\"asm\"`]"
    smoother_pc::String

    "smoother damping (only for richardson)"
    smoother_damping::Float64

    "smoother relaxation parameter (only for sor)"
    smoother_omega::Float64

    "number of smoothing sweeps per level"
    smoother_num_sweeps::Int64

    "number of cpus for the coarse grid solve (0: all, -1: automatic)"
    coarse_num_cpu::Int64

    "cells per cpu on the coarse grid (only for coarse_num_cpu = -1)"
    coarse_cells_per_cpu::Int64

    "coarse grid solver [`\"direct\"`, `\"hypre\"`, `\"bjacobi\"`, `\"asm\"`]"
    coarse_solver::String

    "coarse grid fgmres (hypre, bjacobi, asm): rtol, maxit"
    coarse_tolerances::Vector{Float64}

    "subdomains per cpu (only for bjacobi and asm; -1: automatic)"
    subdomain_num_per_cpu::Int64

    "cells per subdomain (only for subdomain_num_per_cpu = -1)"
    subdomain_cells_per_cpu::Int64

    "subdomain overlap (only for asm)"
    subdomain_overlap::Int64

    "ILU levels in the subdomain solves (only for bjacobi and asm)"
    subdomain_ilu_levels::Int64

    "steady-state temperature solver [`\"mg\"`, `\"default\"`]"
    init_thermal_solver::String

    "thermal solver: rtol, atol, maxit (atol = -1: automatic)"
    thermal_tolerances::Vector{Float64}

    "List with (optional) PETSc options"
    PETSc_options::Vector{String}

end

# LaMEM's defaults (info/options/input_file.dat)
const SOLVER_DEFAULTS = (0, 0, 0, 0, 0,
                         [1e-5, -1, 50], [1e-6, -1, 200], [1e-2, 5, 1.2, 20], 1, 0, 0,
                         "coupled_direct", "mumps", [1e-2, 30], 1e3,
                         -1, 0,
                         "heavy", "gmres", "bjacobi", 0.5, 1.0, 20,
                         0, 4096, "direct", [1e-2, 30],
                         1, 2048, 1, 0,
                         "mg", [1e-8, -1, 500],
                         String[])

"""
    Solver(; kwargs...)

Keyword constructor. Accepts the fields of [`Solver`](@ref) and, for backwards compatibility,
the LaMEM 2.x keywords `SolverType`, `DirectSolver`, `DirectPenalty`, `MGLevels`, `MGSweeps`,
`MGSmoother`, `MGJacobiDamp`, `MGCoarseSolver`, `MGRedundantNum`, `MGRedundantSolver`, which are
translated to the corresponding LaMEM 3.x options.
"""
function Solver(; SolverType=nothing, DirectSolver=nothing, DirectPenalty=nothing,
                  MGLevels=nothing, MGSweeps=nothing, MGSmoother=nothing, MGJacobiDamp=nothing,
                  MGCoarseSolver=nothing, MGRedundantNum=nothing, MGRedundantSolver=nothing,
                  kwargs...)
    d = Solver(deepcopy(SOLVER_DEFAULTS)...)
    for (k, v) in kwargs
        hasfield(Solver, k) || error("Solver has no option `$k`; see `?Solver` for the LaMEM >= 3.0 solver options.")
        T = fieldtype(Solver, k)
        setfield!(d, k, T <: Vector ? convert(T, collect(v)) : convert(T, v))
    end

    legacy = (; SolverType, DirectSolver, DirectPenalty, MGLevels, MGSweeps, MGSmoother,
                MGJacobiDamp, MGCoarseSolver, MGRedundantNum, MGRedundantSolver)
    used = [String(k) for (k, v) in pairs(legacy) if !isnothing(v)]
    if !isempty(used)
        @warn "The Solver options $(join(used, ", ")) are from LaMEM 2.x and were translated to the LaMEM >= 3.0 options; " *
              "see `?Solver`. Use `stokes_solver`, `direct_solver_type`, `penalty`, `num_mg_levels`, ... directly instead." maxlog=1
        translate_legacy_solver!(d, legacy)
    end
    return d
end

# LaMEM 2.x -> 3.x solver options (doc/src/man/Upgrade_v2.2.1_to_v3.0.0.md, section 4.3)
function translate_legacy_solver!(d::Solver, legacy)
    direct_package(name) = name in ("mumps", "superlu_dist") ? name : "default"

    if !isnothing(legacy.SolverType)
        if legacy.SolverType == "direct"
            d.stokes_solver = "block_direct"
        elseif legacy.SolverType == "multigrid"
            d.stokes_solver = "coupled_mg"
        else
            error("Unknown SolverType $(legacy.SolverType); choose either \"direct\" or \"multigrid\"")
        end
    end
    isnothing(legacy.DirectSolver)  || (d.direct_solver_type = direct_package(legacy.DirectSolver))
    isnothing(legacy.DirectPenalty) || (d.penalty = Float64(legacy.DirectPenalty))
    isnothing(legacy.MGLevels)      || (d.num_mg_levels = Int64(legacy.MGLevels))
    isnothing(legacy.MGSweeps)      || (d.smoother_num_sweeps = Int64(legacy.MGSweeps))
    isnothing(legacy.MGJacobiDamp)  || (d.smoother_damping = Float64(legacy.MGJacobiDamp))
    if !isnothing(legacy.MGSmoother)
        d.smoother_type = legacy.MGSmoother == "jacobi" ? "light" : "intermediate"
    end
    if !isnothing(legacy.MGCoarseSolver)
        d.coarse_solver = "direct"
        if legacy.MGCoarseSolver == "redundant"
            d.coarse_num_cpu = 1
        elseif legacy.MGCoarseSolver != "direct"
            d.direct_solver_type = direct_package(legacy.MGCoarseSolver)
        end
    end
    if !isnothing(legacy.MGRedundantNum) || !isnothing(legacy.MGRedundantSolver)
        @warn "MGRedundantNum/MGRedundantSolver no longer exist in LaMEM >= 3.0 (the redundant coarse solver was replaced by telescope); ignored." maxlog=1
    end
    return d
end

is_direct_stokes(d::Solver) = d.stokes_solver in ("coupled_direct", "block_direct")

# Print info about the structure
function show(io::IO, d::Solver)
    Reference = Solver();
    println(io, "LaMEM Solver options: ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),24)) = $(getfield(d,f)) \n", color=col)
    end

    return nothing
end

function show_short(io::IO, d::Solver)
    if is_direct_stokes(d)
        println(io,"|-- Solver options      :  $(d.stokes_solver); $(d.direct_solver_type); penalty=$(d.penalty)")
    else
        levels = d.num_mg_levels == -1 ? "automatic" : "$(d.num_mg_levels)"
        println(io,"|-- Solver options      :  $(d.stokes_solver); MG levels=$(levels); coarse solver=$(d.coarse_solver)")
    end

    return nothing
end

# LaMEM reads the iteration counts in the tolerance vectors as integers
solver_value(x::AbstractFloat) = isinteger(x) && abs(x) < 1e15 ? string(Int(x)) : string(x)
solver_value(x) = string(x)
solver_value(v::AbstractVector) = join(solver_value.(v), " ")

"""
    write_LaMEM_inputFile(io, d::Solver)
Writes the solver options (`<SolverOptionsStart>` block) to file
"""
function write_LaMEM_inputFile(io, d::Solver)
    Reference = Solver();    # reference values
    fields    = filter_fields(fieldnames(typeof(d)), (:PETSc_options,))

    println(io, "#===============================================================================")
    println(io, "# Solver options")
    println(io, "#===============================================================================")
    println(io,"")
    println(io, "<SolverOptionsStart>")

    always = [:stokes_solver]
    if is_direct_stokes(d) || d.coarse_solver == "direct"
        push!(always, :direct_solver_type)
    end
    if is_direct_stokes(d)
        push!(always, :penalty)
    end

    for f in fields
        if (getfield(d,f) != getfield(Reference,f)) || (f in always)
            name    = rpad(String(f),24)
            comment = get_doc(Solver, f)
            println(io,"    $name = $(solver_value(getfield(d,f)))     # $(comment)")
        end
    end

    println(io, "<SolverOptionsEnd>")
    println(io,"")
    return nothing
end


"""
    write_LaMEM_inputFile_PETSc(io, d::Solver)
Writes the (optional) PETSc options to file
"""
function write_LaMEM_inputFile_PETSc(io, d::Solver)
    PETSc_options = d.PETSc_options

    println(io, "#===============================================================================")
    println(io, "# PETSc options")
    println(io, "#===============================================================================")
    println(io,"")

    if length(PETSc_options)>0
        println(io, "<PetscOptionsStart>")
        for opt in PETSc_options
            println(io,"    $opt")
        end

        println(io, "<PetscOptionsEnd>")
    end
    println(io,"")
    return nothing
end
