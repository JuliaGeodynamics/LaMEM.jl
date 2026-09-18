# This checks the LaMEM Model setup for errors and catches them before you run a model
export Check_LaMEM_Model


"""
    Check_LaMEM_Model(m::Model; warn_constant_grid=true)

Checks the LaMEM Setup Model `m` for errors.

`warn_constant_grid` toggles the warning that is emitted when both the initial `Phases`
and `Temp` grids are constant. Set it to `false` for intentionally uniform setups (e.g. the
0D rheology benchmark in `stress_strainrate_0D`).
"""
function Check_LaMEM_Model(m::Model; warn_constant_grid=true)

    if length(m.Materials.Phases)==0
        error("You need to specify properties for the phases, with add_phase!(mode, Phase(ID=1,...))")
    end

    if (m.ModelSetup.msetup=="geom") && length(m.ModelSetup.geom_primitives) == 0
        error("If you use internal geometries to set phases, you need to at least specify one internal geometry object.
               Example: add_geom!(model, GeomSphere())")
    end

    if warn_constant_grid && (m.ModelSetup.msetup=="files") && diff([extrema(m.Grid.Phases)...])[1]==0 && diff([extrema(m.Grid.Temp)...])[1]==0
        @warn "Your initial `Temp` grid is constant, as is your initial `Phases` grid. \n Is that intended? \n In most cases, you would want to set some variability in the initial conditions, \n for example with the `GeophysicalModelGenerator` function `add_sphere!(model,cen=(0.0,0.0,0.0), radius=(0.15, ))` "
    end

    if !(m.Solver.stokes_solver in ("coupled_direct", "block_direct", "coupled_mg", "block_mg", "wbfbt"))
        error("Unknown stokes_solver $(m.Solver.stokes_solver); choose one of \"coupled_direct\", \"block_direct\", \"coupled_mg\", \"block_mg\", \"wbfbt\"")
    end
    if !(m.Solver.direct_solver_type in ("mumps", "superlu_dist", "default"))
        error("Unknown direct_solver_type $(m.Solver.direct_solver_type); choose one of \"mumps\", \"superlu_dist\", \"default\"")
    end
    if !(m.Solver.coarse_solver in ("direct", "hypre", "bjacobi", "asm"))
        error("Unknown coarse_solver $(m.Solver.coarse_solver); choose one of \"direct\", \"hypre\", \"bjacobi\", \"asm\"")
    end

    # LaMEM >= 3.0 rejects fewer than two cells per direction and non-unit mesh bias
    for (dir, nel) in zip(("x", "y", "z"), (m.Grid.nel_x, m.Grid.nel_y, m.Grid.nel_z))
        if sum(nel) < 2
            error("LaMEM requires at least two cells in every direction; nel_$dir = $(sum(nel)). Use e.g. Grid(nel=(nx,nz)) for 2D setups, which gives two cells in y.")
        end
    end
    for (dir, bias) in zip(("x", "y", "z"), (m.Grid.bias_x, m.Grid.bias_y, m.Grid.bias_z))
        if any(b -> !(b == 1.0 || b == 0.0), bias)
            error("Non-unit mesh bias ratios (bias_$dir = $bias) are not supported by LaMEM >= 3.0; use uniform segments instead.")
        end
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

