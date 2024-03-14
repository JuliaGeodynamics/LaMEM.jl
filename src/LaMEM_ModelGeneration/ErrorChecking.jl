# This checks the LaMEM Model setup for errors and catches them before you run a model
export Check_LaMEM_Model


"""
    Check_LaMEM_Model(m::Model)

Checks the LaMEM Setup Model `m` for errors
"""
function Check_LaMEM_Model(m::Model)
    
    if length(m.Materials.Phases)==0
        error("You need to specify properties for the phases, with add_phase!(mode, Phase(ID=1,...))")
    end

    if (m.ModelSetup.msetup=="geom") && length(m.ModelSetup.geom_primitives) == 0
        error("If you use internal geometries to set phases, you need to at least specify one internal geometry object. 
               Example: add_geom!(model, geom_Sphere())")
    end

    if (m.ModelSetup.msetup=="files") && diff([extrema(m.Grid.Phases)...])[1]==0 && diff([extrema(m.Grid.Temp)...])[1]==0
        @warn "Your initial `Temp` grid is constant, as is your initial `Phases` grid. \n Is that intended? \n In most cases, you would want to set some variability in the initial conditions, \n for example with the `GeophysicalModelGenerator` function `add_sphere!(model,cen=(0.0,0.0,0.0), radius=(0.15, ))` "
    end

    if (m.Solver.SolverType!="direct") &&  (m.Solver.SolverType!="multigrid")
        error("Unknown SolverType; choose either \"direct\" or \"multigrid\"!")
    end

    
    return nothing
end

"""
    is_rectilinear(topography::CartData)

Checks whether `topography` is rectilinear
"""
function is_rectilinear(topography::CartData)
    dx = extrema(diff(ustrip.(topography.x.val[:,:,1]), dims=1))
    dy = extrema(diff(ustrip.(topography.y.val[:,:,1]), dims=2))
    
    return (dx[2] ≈ dx[1]) .& (dy[2] ≈ dy[1])
end

"""
    within_bounds(model::Model, topography::CartData)

Verifies that the bounds of the topography grid are larger than that of the model
"""
function within_bounds(model::Model, topography::CartData)
    x_topo = extrema(topography.x.val)
    y_topo = extrema(topography.y.val)
    x =extrema(model.Grid.Grid.X)
    y =extrema(model.Grid.Grid.Y)

    if (x_topo[1]>x[1]) ||  (x_topo[2]<x[2]) ||
       (y_topo[1]>y[1]) ||  (y_topo[2]<y[2])
        within = false
    else
        within = true
    end
    return within
end

