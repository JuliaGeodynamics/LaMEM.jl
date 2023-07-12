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
        error("Your initial `Temp` grid is constant, as is your initial `Phases` grid. 
        You do need to set some variability to see action, for example with the GMG function `AddSphere!(model,cen=(0.0,0.0,0.0), radius=(0.15, ))` ")
    end

    
    return nothing
end



