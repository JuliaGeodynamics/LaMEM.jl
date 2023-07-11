# Solver options

export Solver, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM solver options
    
    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Solver
    "solver employed [`\"direct\"` or `\"multigrid\"`]"
    SolverType::String      =	"direct"

    "mumps/superlu_dist/pastix/umfpack  (requires these external PETSc packages to be installed!)"
    DirectSolver::String    =	"superlu_dist"		

    "penalty parameter [employed if we use a direct solver]"
    DirectPenalty::Float64  =	1e4			

    "number of MG levels [default=3]"
    MGLevels::Int64 	    =	3			

    "number of MG smoothening steps per level [default=10]"
    MGSweeps::Int64 	    =	10			

    "type of smoothener used [chebyshev or jacobi]"
    MGSmoother::String      =	"chebyshev" 	

    "Dampening parameter [only employed for Jacobi smoothener; default=0.6]"
    MGJacobiDamp::Float64   =	0.5			

    "coarse grid solver if using multigrid [`\"direct\"` / `\"mumps\"` / `\"superlu_dist\"` or `\"redundant\"` - more options specifiable through the command-line options `-crs_ksp_type` & `-crs_pc_type`]"
    MGCoarseSolver::String  =	"direct" 		

    "How many times do we copy the coarse grid? [only employed for redundant solver; default is 4]"
    MGRedundantNum::Int64   =	4			

    "The coarse grid solver for each of the redundant solves [only employed for redundant; options are `\"mumps\"`/`\"superlu_dist\"` with default `\"superlu_dist\"`]"
    MGRedundantSolver::String   = 	"superlu_dist"		

    "List with (optional) PETSc options"
    PETSc_options::Vector{String} = []
end

# Print info about the structure
function show(io::IO, d::Solver)
    Reference = Solver();
    println(io, "LaMEM Solver options: ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),17)) = $(getfield(d,f)) \n", color=col)        
    end

  
    return nothing
end

function show_short(io::IO, d::Solver)
    if d.SolverType=="direct"
        println(io,"|-- Solver options      :  $(d.SolverType) solver; $(d.DirectSolver); penalty term=$(d.DirectPenalty)")
    else
        println(io,"|-- Solver options      :  $(d.SolverType) solver; coarse grid solver=$(d.MGCoarseSolver); $(d.MGLevels) levels")
    end

    return nothing
end



"""
    Write_LaMEM_InputFile(io, d::Solver)
Writes the free surface related parameters to file
"""
function Write_LaMEM_InputFile(io, d::Solver)
    Reference = Solver();    # reference values
    fields    = fieldnames(typeof(d))

    println(io, "#===============================================================================")
    println(io, "# Solver options")
    println(io, "#===============================================================================")
    println(io,"")

    for f in fields
        if getfield(d,f) != getfield(Reference,f) 
            # only print if value differs from reference value
            name = rpad(String(f),15)
            comment = get_doc(Solver, f)
            data = getfield(d,f) 
            println(io,"    $name  = $(write_vec(data))     # $(comment)")
        end
    end

    println(io,"")
    return nothing
end


"""
    Write_LaMEM_InputFile_PETSc(io, d::Solver)
Writes the (optional) PETSc options to file
"""
function Write_LaMEM_InputFile_PETSc(io, d::Solver)
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