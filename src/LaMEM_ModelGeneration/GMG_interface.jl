#GMG_interface
#
# Some wrappers around GMG routines

import GeophysicalModelGenerator: add_box!, add_layer!, add_sphere!, add_ellipsoid!, add_cylinder!, above_surface, below_surface
import GeophysicalModelGenerator: addPolygon!, addSlab!, addStripes!
export above_surface!, below_surface!

"""
    add_box!(model::Model; xlim=Tuple{2}, [ylim=Tuple{2}], zlim=Tuple{2},
            Origin=nothing, StrikeAngle=0, DipAngle=0,
            phase = ConstantPhase(1),
            T=nothing )

Adds a box with phase & temperature structure to a 3D model setup. This simplifies creating model geometries in geodynamic models
See the documentation of the GMG routine for the full options.

"""
add_box!(model::Model; kwargs...) = add_box!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 

"""
    add_layer!(model::Model; xlim, ylim, zlim=Tuple{2},
            phase = ConstantPhase(1),
            T=nothing )

Adds a layer with phase & temperature structure to a 3D model setup. This simplifies creating model geometries in geodynamic models
See the documentation of the GMG routine for the full options.

"""
add_layer!(model::Model; kwargs...) = add_layer!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    add_sphere!(model::Model; cen=Tuple{3}, radius=Tuple{1}, phase = ConstantPhase(1), T=nothing)

See the documentation of the GMG routine

"""
add_sphere!(model::Model; kwargs...) = add_sphere!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 

"""
    add_cylinder!(model::Model;                                      # required input
                    base=Tuple{3}, cap=Tuple{3}, radius=Tuple{1},   # center and radius of the sphere
                    phase = ConstantPhase(1),                       # Sets the phase number(s) in the sphere
                    T=nothing )                                     # Sets the thermal structure (various fucntions are available)


See the documentation of the GMG routine

"""
add_cylinder!(model::Model; kwargs...) = add_cylinder!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


"""
    add_ellipsoid!(model::Model;                                 # required input
                    cen=Tuple{3}, axes=Tuple{3},                # center and semi-axes of the ellpsoid
                    Origin=nothing, StrikeAngle=0, DipAngle=0,  # origin & dip/strike
                    phase = ConstantPhase(1),                   # Sets the phase number(s) in the box
                    T=nothing ) 

See the documentation of the GMG routine

"""
add_ellipsoid!(model::Model; kwargs...) = add_ellipsoid!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


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
    above_surface(model::Model, DataSurface_Cart::CartData)

Returns a boolean grid that is `true` if the `Phases/Temp` grid are above the surface
"""
above_surface(model::Model, DataSurface_Cart::CartData) = above_surface(model.Grid.Grid, DataSurface_Cart)


"""
    above_surface!(model::Model, DataSurface_Cart::CartData; phase::Int64=nothing, T::Number=nothing) 
    
Sets the `Temp` or `Phases` above the surface `DataSurface_Cart` to a constant value.
"""
function above_surface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
    id = above_surface(model, DataSurface_Cart)
    if !isnothing(phase)
        model.Grid.Phases[id] .= phase
    end
    if !isnothing(T)
        model.Grid.Temp[id] .= T
    end

    return nothing
end




"""
    below_surface(model::Model, DataSurface_Cart::CartData)

Returns a boolean grid that is `true` if the `Phases/Temp` grid are below the surface
"""
below_surface(model::Model, DataSurface_Cart::CartData) = below_surface(model.Grid.Grid, DataSurface_Cart)


"""
    below_surface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
Sets the `Temp` or `Phases` below the surface `DataSurface_Cart` to a constant value.
"""
function below_surface!(model::Model, DataSurface_Cart::CartData; phase::Union{Int64,Nothing}=nothing, T::Union{Number,Nothing}=nothing) 
    
    id = below_surface(model, DataSurface_Cart)
    if !isnothing(phase)
        model.Grid.Phases[id] .= phase
    end
    if !isnothing(T)
        model.Grid.Temp[id] .= T
    end

    return nothing
end