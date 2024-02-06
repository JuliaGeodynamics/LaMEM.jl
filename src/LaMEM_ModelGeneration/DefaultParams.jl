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


    return model
end
