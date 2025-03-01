# This tests erosion of the files

using Test
using LaMEM
using GeophysicalModelGenerator

@testset "sedimentation erosion" begin
    if !Sys.iswindows()
        # Main model setup
        model = Model(Grid(nel=(50,1,50), x=[-50,50], z=[-50,50], y=[-1,1] ), 
        Scaling(GEO_units(stress=1000MPa, viscosity=1e20Pa*s)),
        Time(dt=1e-2, dt_min=1e-5, dt_max=1e-1, nstep_out=5, nstep_max=200, time_end=5),
        Output(out_dir="sedimentation_test_folder"))

        # add an air phase, phase =0 
        add_box!(model;  xlim = (-50, 50), ylim = (model.Grid.coord_y...,), zlim = (50, -25),
                phase   = ConstantPhase(0), T = nothing )    

        # add a crust phase, phase =1
        add_box!(model;  xlim = (-50, 50), ylim = (model.Grid.coord_y...,), zlim    = (-50.0, -25.0),
                phase   = ConstantPhase(1), T = nothing )   

        model.FreeSurface = FreeSurface(    surf_use        = 1,                # free surface activation flag
                                            surf_corr_phase = 1,                # air phase ratio correction flag (due to surface position)
                                            surf_level      = -25.0,            # initial level
                                            surf_air_phase  = 0,                # phase ID of sticky air layer
                                            surf_max_angle  = 40.0,             # maximum angle with horizon (smoothed if larger))

                                            sediment_model  = 1,                # 1-prescribed rate with given level
                                            sed_num_layers  = 1,                # number of sediment layers
                                            sed_time_delims = [1],              # sediment layers time delimiters (one less than number)
                                            sed_rates       = [0.5,0.5],        # sediment rates in different time periods (0.5cm/yr = 5 km/Myr)
                                            sed_levels      = [0,0],            # levels below which we apply constant sediment rates in different time periods                               
                                            sed_phases      = [1]               # sediment layers phase numbers in different time periods
                                            )        
        #plot_cross_section(model, y=0, field=:phase)

        air    = Phase(ID=0, Name="Air",    eta=1e19, rho=50, ch=10e6, fr=0);
        crust  =  Phase(ID=1, Name="crust",  eta=1e21, rho=2700, ch=30e6, fr=20);
        rm_phase!(model)
        add_phase!(model, air, crust)

        run_lamem(model,1);

        # read last timestep
        data,time = read_LaMEM_timestep(model,last=true);

        @test  sum(data.fields.phase[32,1,:]) ≈ 25.683678f0 # check sum of phase along a vertical profile
        
        # cleanup the directory
        rm(model.Output.out_dir, force=true, recursive=true)

    end

end