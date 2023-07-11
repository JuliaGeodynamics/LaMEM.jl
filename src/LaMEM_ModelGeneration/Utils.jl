# Contains a number of useful functions
export add_phase!, rm_phase!, rm_last_phase!, add_softening!


"""
    add_phase!(model::Model, phase::Phase)
This adds a `phase` (with material properties) to `model`
"""
function add_phase!(model::Model, phase::Phase) 
    push!(model.Materials.Phases, phase);
    return nothing
end

"""
    rm_last_phase!(model::Model, phase::Phase)
This removes the last added `phase` from `model`
"""
function rm_last_phase!(model::Model) 
    if length(model.Materials.Phases)>0
        model.Materials.Phases= model.Materials.Phases[1:end-1]
    end
    return nothing
end

"""
    rm_phase!(model::Model, ID::Int64)
This removes a phase with `ID` from `model`
"""
function rm_phase!(model::Model, ID::Int64) 
    id_vec = [phase.ID for phase in model.Materials.Phases]
    id = findall(id_vec .== ID)
    deleteat!(model.Materials.Phases,id)
    return nothing
end


"""
    add_petsc!(model::Model, option::String) 

Adds one or more PETSc options to the model 

Example
===
```julia
julia> d = Model()
julia> add_petsc!(d,"-snes_npicard 3")
```

"""
function add_petsc!(model::Model, args...) 
    for arg in args
        push!(model.Solver.PETSc_options , arg);
    end
    return nothing
end


function add_softening!(model::Model, args...) 
    for arg in args
        push!(model.Solver.PETSc_options , arg);
    end
    return nothing
end

"""
    add_softening!(model::Model, soft::Softening)
This adds a plastic softening law `soft` to `model`
"""
function add_softening!(model::Model, soft::Softening) 
    push!(model.Materials.SofteningLaws, soft);
    return nothing
end