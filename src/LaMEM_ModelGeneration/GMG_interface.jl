#GMG_interface
#
# Some wrappers around GMG routines

import GeophysicalModelGenerator: AddBox!, AddSphere!, AddEllipsoid!, AddCylinder!

"""
    AddBox!(model::Model; xlim=Tuple{2}, [ylim=Tuple{2}], zlim=Tuple{2},
            Origin=nothing, StrikeAngle=0, DipAngle=0,
            phase = ConstantPhase(1),
            T=nothing )

Adds a box with phase & temperature structure to a 3D model setup. This simplifies creating model geometries in geodynamic models
See the documentation of the GMG routine

"""
AddBox!(model::Model; kwargs...) = AddBox!(model.Grid.Phases, model.Grid.Temp, model.Grid.Grid; kwargs...) 


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
