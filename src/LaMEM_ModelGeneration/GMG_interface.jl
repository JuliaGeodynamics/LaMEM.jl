#GMG_interface
#
# Some wrappers around GMG routines

import GeophysicalModelGenerator: addBox!, addLayer!, addSphere!, addEllipsoid!, addCylinder!, aboveSurface, belowSurface
import GeophysicalModelGenerator: addPolygon!, addSlab!, addStripes!
export aboveSurface!, belowSurface!

"""
    addBox!(model::Model; xlim=Tuple{2}, [ylim=Tuple{2}], zlim=Tuple{2},
            Origin=nothing, StrikeAngle=0, DipAngle=0,
            phase = ConstantPhase(1),
            T=nothing )

Adds a box with phase & temperature structure to a 3D model setup. This simplifies creating model geometries in geodynamic models
See the documentation of the GMG routine for the full options.

"""
addBox!(model::Model; kwargs...) = addBox!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 

"""
    addLayer!(model::Model; xlim, ylim, zlim=Tuple{2},
            phase = ConstantPhase(1),
            T=nothing )

Adds a layer with phase & temperature structure to a 3D model setup. This simplifies creating model geometries in geodynamic models
See the documentation of the GMG routine for the full options.

"""
addLayer!(model::Model; kwargs...) = addLayer!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    addSphere!(model::Model; cen=Tuple{3}, radius=Tuple{1}, phase = ConstantPhase(1), T=nothing)

See the documentation of the GMG routine

"""
addSphere!(model::Model; kwargs...) = addSphere!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 

"""
    addCylinder!(model::Model;                                      # required input
                    base=Tuple{3}, cap=Tuple{3}, radius=Tuple{1},   # center and radius of the sphere
                    phase = ConstantPhase(1),                       # Sets the phase number(s) in the sphere
                    T=nothing )                                     # Sets the thermal structure (various fucntions are available)


See the documentation of the GMG routine

"""
addCylinder!(model::Model; kwargs...) = addCylinder!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    addEllipsoid!(model::Model;                                 # required input
                    cen=Tuple{3}, axes=Tuple{3},                # center and semi-axes of the ellpsoid
                    Origin=nothing, StrikeAngle=0, DipAngle=0,  # origin & dip/strike
                    phase = ConstantPhase(1),                   # Sets the phase number(s) in the box
                    T=nothing ) 

See the documentation of the GMG routine

"""
addEllipsoid!(model::Model; kwargs...) = addEllipsoid!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    addPolygon!(model::Model;                                 # required input
                    xlim::Vector, 
                    ylim=Vector,
                    zlim=Vector(), 
                    phase = ConstantPhase(1),                 # Sets the phase number(s) in the box
                    T=nothing) 

See the documentation of the GMG routine

"""
addPolygon!(model::Model; kwargs...) = addPolygon!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    addSlab!(model::Model;                                 # required input
                    trench::Trench, 
                    phase = ConstantPhase(1),                 # Sets the phase number(s) in the box
                    T=nothing) 

See the documentation of the GMG routine

"""
addSlab!(model::Model; kwargs...) = addSlab!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 

"""
    addStripes!(Phase, Grid::AbstractGeneralGrid;
                stripAxes       = (1,1,0),
                stripeWidth     =  0.2,
                stripeSpacing   =  1,
                Origin          =  nothing,
                StrikeAngle     =  0,
                DipAngle        =  10,
                phase           =  ConstantPhase(3),
                stripePhase     =  ConstantPhase(4))
                
See the documentation of the GMG routine

"""
addStripes!(model::Model; kwargs...) = addStripes!(model.Grid.Phases, model.Grid.Grid; kwargs...) 



"""
    aboveSurface(model::Model, DataSurface_Cart::CartData)

Returns a boolean grid that is `true` if the `Phases/Temp` grid are above the surface
"""
aboveSurface(model::Model, DataSurface_Cart::CartData) = aboveSurface(model.Grid.Grid, DataSurface_Cart)


"""
    aboveSurface!(model::Model, DataSurface_Cart::CartData; phase::Int64=nothing, T::Number=nothing) 
    
Sets the `Temp` or `Phases` above the surface `DataSurface_Cart` to a constant value.
"""
function aboveSurface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
    id = aboveSurface(model, DataSurface_Cart)
    if !isnothing(phase)
        model.Grid.Phases[id] .= phase
    end
    if !isnothing(T)
        model.Grid.Temp[id] .= T
    end

    return nothing
end




"""
    belowSurface(model::Model, DataSurface_Cart::CartData)

Returns a boolean grid that is `true` if the `Phases/Temp` grid are below the surface
"""
belowSurface(model::Model, DataSurface_Cart::CartData) = belowSurface(model.Grid.Grid, DataSurface_Cart)


"""
    belowSurface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
Sets the `Temp` or `Phases` below the surface `DataSurface_Cart` to a constant value.
"""
function belowSurface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
    id = belowSurface(model, DataSurface_Cart)
    if !isnothing(phase)
        model.Grid.Phases[id] .= phase
    end
    if !isnothing(T)
        model.Grid.Temp[id] .= T
    end

    return nothing
end