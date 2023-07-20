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
    AddSphere!(model,cen=(0.0,0.0,0.0), radius=(0.5, ))

    # run the simulation on 1 core
    run_lamem(model, 1);

    # read last timestep
    data,time = Read_LaMEM_timestep(model,last=true);

    @test  sum(data.fields.velocity[3][:,:,:]) ≈ 0.10747005f0 # check Vz

    # cleanup the directory
    rm(model.Output.out_dir, force=true, recursive=true)
    # ===============================



end
