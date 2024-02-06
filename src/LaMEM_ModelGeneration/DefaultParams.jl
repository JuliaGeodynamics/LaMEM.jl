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
      
        model.Output.out_ptr=1
        model.Output.out_ptr_ID=1
        model.Output.out_ptr_phase=1
        model.Output.out_ptr_Pressure=1
        model.Output.out_ptr_Temperature=1
    end

    return model
end
