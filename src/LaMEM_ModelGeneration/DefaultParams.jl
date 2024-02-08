# This sets default parameters, depending  on various combinations of input patameters

"""
    model = UpdateDefaultParameters(model::Model)

This updates the default parameters depending on some of the input parameters.
If you activate passive tracers, for example, it will also activate output for that 
"""
function UpdateDefaultParameters(model::Model)

    # If PhaseTransitions are defined, we generally want this to be activated in computations
    if !isempty(model.Materials.PhaseTransitions)
        model.SolutionParams.Phasetrans = 1
    end
   
    # If PassiveTracers are defined, we generally want this to be visualized as well:
    if model.PassiveTracers.Passive_Tracer==1
        PT_default = PassiveTracers();

        if all(all(PT_default.PassiveTracer_Box .== model.PassiveTracers.PassiveTracer_Box) )
            # If the default values are used, set it to be the full size of the box
            model.PassiveTracers.PassiveTracer_Box = [model.Grid.coord_x;  model.Grid.coord_y;  model.Grid.coord_z]
        end

        model.Output.out_ptr=1
        model.Output.out_ptr_ID=1
        model.Output.out_ptr_phase=1
        model.Output.out_ptr_Pressure=1
        model.Output.out_ptr_Temperature=1
    end

    if  model.BoundaryConditions.open_top_bound==0
        # If do not have an open (stress-free) top boundary, pressur is only defined up to a constant which can mess 
        # up phase transitions or P-dependent rheology (e.g. Drucker-Prager). This sets the average P @ the top to be 0
        model.SolutionParams.act_p_shift = 1
    end

    # output additional fields at all times; stress, strainrate, density, pressure, velocity, temperature

    # is using MG and 2D , set da_refine_y to 1 

    # if we have a free surface, you'll generally want output  
    if  model.FreeSurface.surf_use==1
        model.Output.out_surf=1
        model.Output.out_surf_pvd         = 1 
        model.Output.out_surf_velocity    = 1 
        model.Output.out_surf_topography  = 1 
        model.Output.out_surf_amplitude   = 1  
    end

    # Scaling: if we use default values, employ smarter default values based on the model setup
    if isdefault(model.Scaling,Scaling())
        le = abs(diff(model.Grid.coord_z)[1])*km    # length
        η  = model.SolutionParams.eta_ref*Pas       # viscosity
        model.Scaling = Scaling(GEO_units(length=le, viscosity = η))
    end
        
    # exx_strain_rates: no need to specify exx_num_periods

    # if surf_use=1 and surf_level==nothing, set it to zero

    return model
end
