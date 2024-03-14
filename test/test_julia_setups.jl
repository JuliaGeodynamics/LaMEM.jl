# This tests running the full code from julia

using Test
using GeophysicalModelGenerator

@testset "Julia setup" begin

    # ===============================
    # Simple linear viscous setup with falling sphere

    # Main model setup
    model  = Model(Grid(nel=(16,16,16), x=[-2,2], coord_y=[-1,1], coord_z=[-1,1]),
                   Time(nstep_max=2, dt=1, dt_max=10), 
                   Solver(SolverType="multigrid", MGLevels=2),
                   Output(out_dir="example_1"))
    
    # Specify material properties
    matrix = Phase(ID=0,Name="matrix",eta=1e20,rho=3000)
    sphere = Phase(ID=1,Name="sphere",eta=1e23,rho=3200)
    add_phase!(model, sphere, matrix)

    # Add an initial geometry (using GeophysicalModelGenerator routines)
    add_sphere!(model,cen=(0.0,0.0,0.0), radius=(0.5, ))

    # run the simulation on 1 core
    run_lamem(model, 1);

    # read last timestep
    data,time = read_LaMEM_timestep(model,last=true);

    @test  sum(data.fields.velocity[3][:,:,:]) ≈ 0.10747005f0 rtol=1e-1 # check Vz
#    @test  sum(data.fields.velocity[3][:,:,:]) ≈ 0.10866211f0 # check Vz

    # cleanup the directory
    rm(model.Output.out_dir, force=true, recursive=true)
    # ===============================



end

@testset "velocity box" begin
    
    
# ===============================
# constant model with added velocity box
using LaMEM
using GeophysicalModelGenerator

    # %%
    # constant model with added velocity box

    # Main model setup
    model  = Model(Grid(nel=(16,16,16), x=[-2,2], coord_y=[-1,1], coord_z=[-1,1]),
                    Time(nstep_max=3, nstep_out=1, dt=1, dt_max=10, dt_min=1e-5), 
                    Solver(SolverType="multigrid", MGLevels=2),
                    BoundaryConditions(temp_bot=20),
                    Output(out_velocity=1, out_dir="example_1"))

    # Specify material properties
    matrix = Phase(ID=0,Name="matrix",eta=1e20,rho=3000)
    sphere = Phase(ID=1,Name="sphere",eta=1e20,rho=3000)
    add_phase!(model, sphere, matrix)

    # Add an initial geometry (using GeophysicalModelGenerator routines)
    add_sphere!(model,cen=(0.0,0.0,0.0), radius=(0.5, ))

    # Add a velocity box:
    vbox = VelocityBox(cenX=0, cenY=0, cenZ=0,
                        widthX=1, widthY=1, widthZ=1,
                        vx=1)

    add_vbox!(model, vbox)

    # # run the simulation on 1 core
    run_lamem(model, 1);

    # # read last timestep
    # read last timestep
    data,time = read_LaMEM_timestep(model,last=true);

    @test  sum(data.fields.velocity[1][8, 8, 8]) ≈ 1
    
    # cleanup the directory
    rm(model.Output.out_dir, force=true, recursive=true)
    # ===============================

end



@testset "phase transitions" begin

# ===============================
# constant model with phase transitions
using LaMEM
using GeophysicalModelGenerator

    # Create a model setup with phase transitions; this corresponds to t16
    # Main model setup
    model  = Model(Grid(nel=(64,1,64), x=[-500,500], coord_y=[-10,10], coord_z=[-1000,50]),
                    Time(nstep_max=30, nstep_out=5, dt=0.01, dt_max=1, dt_min=1e-5), 
                    Scaling(GEO_units(length = 100km) ),
                    BoundaryConditions(temp_bot=1300, noslip=[0,0,0,0,1,0], open_top_bound=1),
                    SolutionParams(init_lith_pres=1),
                    Output(out_velocity=1, out_file_name="Plume_PhaseTransitions_new", out_dir="example_phase", out_temperature=1))

    # Specify material properties
    air     = Phase(ID=0,Name="Air",     eta=1e22, rho=3300, alpha=3e-5,  k=100, Cp=1e6)
    Ocrust  = Phase(ID=1,Name="OCrust",  eta=1e24, rho=3300, alpha=3e-5, k=3, Cp=1050)
    Omantle = Phase(ID=2,Name="Omantle", eta=1e23, rho=3300, alpha=3e-5, k=3, Cp=1050)
    Umantle = Phase(ID=3,Name="Umantle", eta=1e20, rho=3300, alpha=3e-5, k=3, Cp=1050)
    Plume   = Phase(ID=4,Name="Plume",   eta=1e20, rho=3300, alpha=3e-5, k=3, Cp=1050)
    Lmantle = Phase(ID=5,Name="Lmantle", eta=1e21, rho=3300, alpha=3e-5, k=3, Cp=1050)
    Plume2  = Phase(ID=6,Name="Plume2",  eta=1e20, rho=3300, alpha=3e-5, k=3, Cp=1050)
    Umantle2= Phase(ID=7,Name="Umantle2",eta=1e20, rho=3300, alpha=3e-5, k=3, Cp=1050)
    rm_phase!(model)
    add_phase!(model, air, Ocrust, Omantle, Umantle, Plume, Lmantle, Plume2, Umantle2)

    # Add phase transitions---
    # T dependent phase transition
    PT0 = PhaseTransition(ID=0, Type="Constant", Parameter_transition="T",      PhaseBelow = [2], PhaseAbove=[3], PhaseDirection="BothWays",     ConstantValue=1200)
    
    # Depth dependent phase transition
    PT1 = PhaseTransition(ID=1, Type="Constant", Parameter_transition="Depth",  PhaseBelow = [4], PhaseAbove=[6], PhaseDirection="BelowToAbove", ConstantValue=-400, ResetParam="APS")

    # Clapeyron slope
    PT2 = PhaseTransition(ID=2, Type="Clapeyron", Name_Clapeyron="Mantle_Transition_660km",  PhaseBelow = [3], PhaseAbove=[5], PhaseDirection="BothWays")

	# Box-like region with T-condition
    PT3 = PhaseTransition(ID=3, Type="Box", PTBox_Bounds=[200,400,-100,100,-1000,-500], PhaseInside=[7], PhaseOutside=[3], PhaseDirection="BothWays", PTBox_TempType="linear", PTBox_topTemp=20, PTBox_botTemp=1300, ResetParam="APS")
    
    model.Materials.PhaseTransitions = [PT0, PT1, PT2, PT3]
    # -------------------------
    
    # Add geometry ---
    Z=model.Grid.Grid.Z;
    
    # Define mantle and lithosphere 
    add_box!(model, zlim=(-1000.0, 0.0),  xlim=(model.Grid.coord_x...,), phase=ConstantPhase(3), T=HalfspaceCoolingTemp(Age=100))

    # Define oceanic crust (for Phase)
    add_box!(model, zlim=(-10.0, 0.0),  xlim=(model.Grid.coord_x...,), phase=ConstantPhase(1))

    add_sphere!(model, cen=(0.0,0.0,-550.0), radius=100.0,   phase=ConstantPhase(4), T=ConstantTemp(1400))
    # -------------------------

    # run the simulation on 1 core
    run_lamem(model, 1);

    # read last timestep
    data,time = read_LaMEM_timestep(model,last=true);

    @test  sum(data.fields.phase) ≈ 29060.664f0
    
    # cleanup the directory
    rm(model.Output.out_dir, force=true, recursive=true)
    # ===============================


end


@testset "phase diagrams" begin
    # This tests requires an update of LaMEM, to allow phase diagram names that are longer
    #include("test_julia_setup_phase_diagrams.jl")
end



@testset "build-in geometries" begin
    # This tests the ability to write output files when we have build-in geometrical objects,
    # such as spheres, boxes, etc. as opoosed to doing this through the GeophysicalModelGenerator
    model  = Model(Grid(nel=(16,16), x=[-2,2], z=[-1,1]),
                    Time(nstep_max=2, dt=1, dt_max=10), 
                    Solver(SolverType="direct"),
                    Output(out_dir="example_1"))

    # Specify material properties
    matrix = Phase(ID=0,Name="matrix",eta=1e20,rho=3000)
    sphere = Phase(ID=1,Name="sphere",eta=1e23,rho=3200)
    add_phase!(model, sphere, matrix)

    geom_sphere = GeomSphere();
    rm_geom!(model)
    add_geom!(model, geom_sphere)
    out = run_lamem(model)
    @test isnothing(out)

    geom_ellipsoid = GeomEllipsoid();
    geom_box = GeomBox();
    geom_layer = GeomLayer();
    geom_cylinder = GeomCylinder();
    geom_ridge = GeomRidgeSeg();
    geom_hex = GeomHex();

    add_geom!(model, geom_ellipsoid, geom_box, geom_layer, geom_cylinder, geom_ridge, geom_hex)
    out = run_lamem(model)
    @test isnothing(out)


    
end