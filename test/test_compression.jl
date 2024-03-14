# This tests compression of the files

using Test
using GeophysicalModelGenerator

@testset "filesize compression" begin
    if !Sys.iswindows()
        # Main model setup
        model  = Model(Grid(nel=(8,16,32), x=[-2,2], coord_y=[-1,1], coord_z=[-3,3]),
        Time(nstep_max=5, dt=1, dt_max=1, time_end=100), 
        Solver(SolverType="multigrid", MGLevels=2),
        Output(out_dir="example_1", out_avd=1, out_avd_pvd=1, out_avd_ref=3))

        # Specify material properties
        matrix = Phase(ID=0,Name="matrix",eta=1e20,rho=3000)
        sphere = Phase(ID=1,Name="sphere",eta=1e23,rho=3200)
        add_phase!(model, sphere, matrix)

        # Add an initial geometry (using GeophysicalModelGenerator routines)
        add_sphere!(model,cen=(0.0,0.0,0.0), radius=(0.5, ))

        # run the simulation on 4 core
        run_lamem(model, 4);

        dir=model.Output.out_dir
        out = compress_pvd("output.pvd", Dir=dir, delete_original_files=true)
        @test out == "output_compressed.pvd"

        out = compress_pvd("output_phase.pvd", Dir=dir, delete_original_files=true)
        @test out == "output_phase_compressed.pvd"
    end

end