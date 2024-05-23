# 2D Thermomechanical subduction example
using LaMEM, GeophysicalModelGenerator

model = Model(Grid( x   = [-2000.,2000.],
                    y   = [-2.5, 2.5],          # <- model is 2D, size in y-direction is choosen to be close to a cube shape for the cell
                    z   = [-660,40] ,
                    #nel = (512,1,128)
                    nel = (256,1,64)
                         
                    ),
                    
                    ## Output filename
                    Output(out_file_name="TMSubduction_2D", out_dir="TMSubduction_2D"),        

                    BoundaryConditions( temp_bot        = 1565.0,
                                        temp_top        = 20.0,
                                        open_top_bound  = 1),
                    Scaling(GEO_units(  temperature     = 1000,
                                        stress          = 1e9Pa,
                                        length          = 1km,
                                        viscosity       = 1e20Pa*s) ),
                    Time(nstep_max=200) )  

# Set timestepping parameters
model.Time = Time(  time_end  = 2000.0,
    dt        = 0.001,
    dt_min    = 0.000001,
    dt_max    = 0.1,
    nstep_max = 400,
    nstep_out = 10
)

# Set solution parameters
model.SolutionParams = SolutionParams(  shear_heat_eff = 1.0,
                                        Adiabatic_Heat = 1.0,
                                        act_temp_diff  = 1,
                                        eta_min   = 5e18,
                                        eta_ref   = 1e20,
                                        eta_max   = 1e25,
                                        min_cohes = 1e3
)

# Set surface topography
model.FreeSurface = FreeSurface(    surf_use        = 1,                # free surface activation flag
                                    surf_corr_phase = 1,                # air phase ratio correction flag (due to surface position)
                                    surf_level      = 0.0,              # initial level
                                    surf_air_phase  = 5,                # phase ID of sticky air layer
                                    surf_max_angle  = 40.0              # maximum angle with horizon (smoothed if larger))
                                )

# Set model output
model.Output = Output(  out_density         = 1,
                        out_j2_strain_rate  = 1,
                        out_surf            = 1, 	
                        out_surf_pvd        = 1,
                        out_surf_topography = 1,
                        out_temperature     = 1,  )

# Specify phase and temperature information
Tair            = 20.0;
Tmantle         = 1280.0;
Adiabat         = 0.4
model.Grid.Temp     .= Tmantle .+ 1.0;      # set mantle temperature (without adiabat at first)
model.Grid.Phases   .= 0;    

# Sticky air:
model.Grid.Temp[model.Grid.Grid.Z .> 0]    .=  Tair;
model.Grid.Phases[model.Grid.Grid.Z .> 0.0 ] .= 5;

# Left ocanic plate:
add_box!(model;  xlim    = (-2000.0, 0.0), 
                ylim    = (model.Grid.coord_y...,), 
                zlim    = (-660.0, 0.0),
                Origin  = nothing, StrikeAngle=0, DipAngle=0,
                phase   = LithosphericPhases(Layers=[20 80], Phases=[1 2 0] ),
                T       = SpreadingRateTemp(    Tsurface    = Tair,
                                                Tmantle     = Tmantle,
                                                MORside     = "left",
                                                SpreadingVel= 0.5,
                                                AgeRidge    = 0.01;
                                                maxAge      = 80.0      ) )
# Add right oceanic plate:
add_box!(model;  xlim    = (1500, 2000), 
                ylim    = (model.Grid.coord_y..., ), 
                zlim    = (-660.0, 0.0),
                Origin  = nothing, StrikeAngle=0, DipAngle=0,
                phase   = LithosphericPhases(Layers=[20 80], Phases=[1 2 0] ),
                T       = SpreadingRateTemp(    Tsurface    = Tair,
                                                Tmantle     = Tmantle,
                                                MORside     = "right",
                                                SpreadingVel= 0.5,
                                                AgeRidge    = 0.01;
                                                maxAge      = 80.0      ) )
                                    
# Add overriding plate margin
add_box!(model;  xlim    = (0.0, 400.0), 
                ylim    = (model.Grid.coord_y[1], model.Grid.coord_y[2]), 
                zlim    = (-660.0, 0.0),
                Origin  = nothing, StrikeAngle=0, DipAngle=0,
                phase   = LithosphericPhases(Layers=[25 90], Phases=[3 4 0] ),
                T       = HalfspaceCoolingTemp(     Tsurface    = Tair,
                                                    Tmantle     = Tmantle,
                                                    Age         = 80      ) )

                                                    
# Overriding plate craton
add_box!(model;  xlim    = (400.0, 1500.0), 
                ylim    = (model.Grid.coord_y...,), 
                zlim    = (-660.0, 0.0),
                Origin  = nothing, StrikeAngle=0, DipAngle=0,
                phase   = LithosphericPhases(Layers=[35 100], Phases=[3 4 0] ),
                T       = HalfspaceCoolingTemp(     Tsurface    = Tair,
                                                    Tmantle     = Tmantle,
                                                    Age         = 120      ) )
#   Add pre-subducted slab                                                  
add_box!(model;  xlim    = (0.0, 300), 
                ylim    = (model.Grid.coord_y...,), 
                zlim    = (-660.0, 0.0),
                Origin  = nothing, StrikeAngle=0, DipAngle=30,
                phase   = LithosphericPhases(Layers=[30 80], Phases=[1 2 0], Tlab=1250 ),
                T       = HalfspaceCoolingTemp(     Tsurface    = Tair,
                                                    Tmantle     = Tmantle,
                                                    Age         = 80      ) )

# Impose approximate adiabat                                                    
model.Grid.Temp = model.Grid.Temp - model.Grid.Grid.Z.*Adiabat;

# Softening
softening =       Softening(    ID   = 0,   			# softening law ID
                                APS1 = 0.1, 			# begin of softening APS
                                APS2 = 0.5, 			# end of softening APS
                                A    = 0.95, 		        # reduction ratio
                            )

# mantle
dryPeridotite = Phase(  Name        = "dryPeridotite",                                     
                        ID          = 0,                                                # phase id  [-]
                        rho         = 3300.0,                                           # density [kg/m3]
                        alpha       = 3e-5,                                             # coeff. of thermal expansion [1/K]
                        disl_prof   = "Dry_Olivine_disl_creep-Hirth_Kohlstedt_2003",
                        Vn          = 14.5e-6,
                        diff_prof   = "Dry_Olivine_diff_creep-Hirth_Kohlstedt_2003",
                        Vd          = 14.5e-6,
                        G           = 5e10,                                             # elastic shear module [MPa]
                        k           = 3,                                                # conductivity
                        Cp          = 1000.0,                                           # heat capacity
                        ch          = 30e6,                                             # cohesion [Pa]
                        fr          = 20.0,                                             # friction angle	
                        A           = 6.6667e-12,                                       # radiogenic heat production [W/kg]
                        chSoftID    = 0,      	                                        # cohesion softening law ID
                        frSoftID    = 0,      	                                        # friction softening law ID
                        )

# Oceanic crust
oceanicCrust = Phase(   Name        = "oceanCrust",                                     
                        ID          = 1,                                                # phase id  [-]
                        rho         = 3300.0,                                           # density [kg/m3]
                        alpha       = 3e-5,                                             # coeff. of thermal expansion [1/K]
                        disl_prof   = "Plagioclase_An75-Ranalli_1995",
                        G           = 5e10,                                             # elastic shear module [MPa]
                        k           = 3,                                                # conductivity
                        Cp          = 1000.0,                                           # heat capacity
                        ch          = 5e6,                                              # cohesion [Pa]
                        fr          = 0.0,                                              # friction angle	
                        A           = 2.333e-10,                                        # radiogenic heat production [W/kg]
                     )
# Oceanic ML
oceanicLithosphere = copy_phase(    dryPeridotite,
                                    Name            = "oceanicLithosphere",
                                    ID              = 2
                                )
# Continental crust
continentalCrust = copy_phase(      oceanicCrust,
                                    Name            = "continentalCrust",
                                    ID              = 3,
                                    disl_prof       = "Quarzite-Ranalli_1995",
                                    rho             = 2700.0,  
                                    ch              = 30e6,
                                    fr              = 20.0,
                                    A         	    = 5.3571e-10,
                                    chSoftID  	    = 0,      	                                        
                                    frSoftID  	    = 0,      	                                        
                             )
# continental lithosphere
continentalLithosphere = copy_phase(    dryPeridotite,
                                        Name            = "continentalLithosphere",
                                        ID              = 4
                                )                                                             
# air
air         = Phase(    Name        = "air",                                     
                        ID          = 5,                                                # phase id  [-]
                        rho         = 50.0,                                             # density [kg/m3]                                           # coeff. of thermal expansion [1/K]
                        eta         = 1e19,
                        G           = 5e10,                                             # elastic shear module [MPa]
                        k           = 100,                                              # conductivity
                        Cp          = 1e6,                                              # heat capacity
                        ch          = 10e6,                                             # cohesion [MPa]
                        fr          = 0.0,                                              # friction angle	
                    )

#  Add phases to the model              
rm_phase!(model)
add_phase!( model, 
            dryPeridotite,
            oceanicCrust,
            oceanicLithosphere,
            continentalCrust,
            continentalLithosphere,
            air
          )

# add softening law          
add_softening!( model,softening)          


# Set solver options
model.Solver = Solver(  SolverType      = "multigrid",
                        MGLevels        = 3,
                        MGCoarseSolver 	= "mumps",
                        PETSc_options   = [ "-snes_ksp_ew",
                                            "-snes_ksp_ew_rtolmax 1e-4",
                                            "-snes_rtol 5e-3",			
                                            "-snes_atol 1e-4",
                                            "-snes_max_it 200",
                                            "-snes_PicardSwitchToNewton_rtol 1e-3", 
                                            "-snes_NewtonSwitchToPicard_it 20",
                                            "-js_ksp_type fgmres",
                                            "-js_ksp_max_it 20",
                                            "-js_ksp_atol 1e-8",
                                            "-js_ksp_rtol 1e-4",
                                            "-snes_linesearch_type l2",
                                            "-snes_linesearch_maxstep 10",
                                            "-da_refine_y 1"
                                        ]
                    )

try testing == true
    # if we run this as part of the test suite, use fewer timesteps
    run_lamem(model, 8, "-nstep_max 2 -nstep_out 1")       
catch
    run_lamem(model, 8)       
end