#GMG_interface
#
# Some wrappers around GMG routines

import GeophysicalModelGenerator: AddBox!, AddLayer!, AddSphere!, AddEllipsoid!, AddCylinder!, AboveSurface, BelowSurface
export AboveSurface!, BelowSurface!

"""
    AddBox!(model::Model; xlim=Tuple{2}, [ylim=Tuple{2}], zlim=Tuple{2},
            Origin=nothing, StrikeAngle=0, DipAngle=0,
            phase = ConstantPhase(1),
            T=nothing )

Adds a box with phase & temperature structure to a 3D model setup. This simplifies creating model geometries in geodynamic models
See the documentation of the GMG routine for the full options.

"""
AddBox!(model::Model; kwargs...) = AddBox!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 

"""
    AddLayer!(model::Model; xlim, ylim, zlim=Tuple{2},
            phase = ConstantPhase(1),
            T=nothing )

Adds a layer with phase & temperature structure to a 3D model setup. This simplifies creating model geometries in geodynamic models
See the documentation of the GMG routine for the full options.

"""
AddLayer!(model::Model; kwargs...) = AddLayer!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    AddSphere!(model::Model; cen=Tuple{3}, radius=Tuple{1}, phase = ConstantPhase(1), T=nothing)

See the documentation of the GMG routine

"""
AddSphere!(model::Model; kwargs...) = AddSphere!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 

"""
    AddCylinder!(model::Model;                                      # required input
                    base=Tuple{3}, cap=Tuple{3}, radius=Tuple{1},   # center and radius of the sphere
                    phase = ConstantPhase(1),                       # Sets the phase number(s) in the sphere
                    T=nothing )                                     # Sets the thermal structure (various fucntions are available)


See the documentation of the GMG routine

"""
AddCylinder!(model::Model; kwargs...) = AddCylinder!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    AddEllipsoid!(model::Model;                                 # required input
                    cen=Tuple{3}, axes=Tuple{3},                # center and semi-axes of the ellpsoid
                    Origin=nothing, StrikeAngle=0, DipAngle=0,  # origin & dip/strike
                    phase = ConstantPhase(1),                   # Sets the phase number(s) in the box
                    T=nothing ) 

See the documentation of the GMG routine

"""
AddEllipsoid!(model::Model; kwargs...) = AddEllipsoid!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    AboveSurface(model::Model, DataSurface_Cart::CartData)

Returns a boolean grid that is `true` if the `Phases/Temp` grid are above the surface
"""
AboveSurface(model::Model, DataSurface_Cart::CartData) = AboveSurface(model.Grid.Grid, DataSurface_Cart)


"""
    AboveSurface!(model::Model, DataSurface_Cart::CartData; phase::Int64=nothing, T::Number=nothing) 
    
Sets the `Temp` or `Phases` above the surface `DataSurface_Cart` to a constant value.
"""
function AboveSurface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
    id = AboveSurface(model, DataSurface_Cart)
    if !isnothing(phase)
        model.Grid.Phases[id] .= phase
    end
    if !isnothing(T)
        model.Grid.Temp[id] .= T
    end

    return nothing
end




"""
    BelowSurface(model::Model, DataSurface_Cart::CartData)

Returns a boolean grid that is `true` if the `Phases/Temp` grid are below the surface
"""
BelowSurface(model::Model, DataSurface_Cart::CartData) = BelowSurface(model.Grid.Grid, DataSurface_Cart)


"""
    BelowSurface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
Sets the `Temp` or `Phases` below the surface `DataSurface_Cart` to a constant value.
"""
function BelowSurface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
    id = BelowSurface(model, DataSurface_Cart)
    if !isnothing(phase)
        model.Grid.Phases[id] .= phase
    end
    if !isnothing(T)
        model.Grid.Temp[id] .= T
    end

    return nothing
end