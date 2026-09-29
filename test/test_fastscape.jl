using Test, GeophysicalModelGenerator
using LaMEM

# LaMEM_jll >= 3.2.0 is built with FastScape (surf_mode = 2); this runs the upstream
# t37_Collision_FastScape input with a simplified marker setup on one core.
@testset "FastScape surface processes" begin
    info = readchomp(`$(LaMEM.LaMEM_jll.LaMEM()) -fastscape_info`)
    @test occursin("FASTSCAPE_ENABLED", info)

    ParamFile = "Collision_FastScape.dat"
    dir = mktempdir()
    cp(joinpath(pkgdir(LaMEM), "test", "input_files", ParamFile), joinpath(dir, ParamFile))
    cd(dir) do
        Grid = read_LaMEM_inputfile(ParamFile)
        X, Y, Z = Grid.X, Grid.Y, Grid.Z

        # air (0) over a continental lithosphere (upper crust 3, lower crust 4, mantle
        # lithosphere 5) with a dipping weak zone (1); asthenosphere (2) below
        Phase = fill(2, size(X))
        Phase[Z .> 0] .= 0
        Phase[(Z .<= 0) .& (Z .> -20)] .= 3
        Phase[(Z .<= -20) .& (Z .> -40)] .= 4
        Phase[(Z .<= -40) .& (Z .> -120)] .= 5
        k = -tand(30.0)
        Phase[(X .>= Z ./ k .+ 900) .& (X .<= Z ./ k .+ 920) .& (Z .> -120) .& (Z .<= 0)] .= 1

        # linear geotherm to 1300 C at 120 km depth, adiabatic (0.5 K/km) below
        Temp = clamp.(-Z .* (1300.0 / 120.0), 0.0, 1300.0) .+ max.(-Z .- 120.0, 0.0) .* 0.5

        Model3D = CartData(Grid, (Phases=Phase, Temp=Temp))
        save_LaMEM_markers_parallel(Model3D, directory="./markers", verbose=false)

        @test isnothing(run_lamem(ParamFile, 1))
        @test isfile("Collision_fs.pvd")
    end
end

@testset "FastScape Julia setup" begin
    # the block is only written for surf_mode = 2
    io = IOBuffer(); write_LaMEM_inputFile(io, FreeSurface(surf_use=1, surf_level=0.0, surf_air_phase=0))
    @test !occursin("<FastScapeStart>", String(take!(io)))

    model = Model(Grid(nel=(32,8,16), x=[-50,50], y=[-10,10], z=[-50,10]),
                  Scaling(GEO_units(stress=1000MPa, viscosity=1e20Pa*s)),
                  Time(dt=1e-3, dt_min=1e-5, dt_max=1e-2, nstep_max=3, nstep_out=1, time_end=1),
                  FreeSurface(surf_use=1, surf_level=0.0, surf_air_phase=0, surf_mode=2,
                              FastScape=FastScape(sed_phases=2, max_fs_dt=1e-3, fs_refine=2,
                                                  topo_boundary="1111", vel_boundary="0000")),
                  Output(out_dir="fastscape_test_folder"))

    add_box!(model; xlim=(-50, 50), ylim=(-10, 10), zlim=(0, 10),   phase=ConstantPhase(0), T=nothing)
    add_box!(model; xlim=(-50, 50), ylim=(-10, 10), zlim=(-50, 0),  phase=ConstantPhase(1), T=nothing)
    add_box!(model; xlim=(-10, 10), ylim=(-10, 10), zlim=(-50, 2),  phase=ConstantPhase(1), T=nothing)   # plateau

    air      = Phase(ID=0, Name="Air",      eta=1e19, rho=50)
    crust    = Phase(ID=1, Name="crust",    eta=1e21, rho=2700)
    sediment = Phase(ID=2, Name="sediment", eta=1e20, rho=2500)
    add_phase!(model, air, crust, sediment)

    run_lamem(model, 1, logfile="fastscape")
    log = read(joinpath(model.Output.out_dir, "fastscape.log"), String)
    @test occursin("Begin FastScape", log)
    @test occursin("SOLUTION IS DONE", log)

    input = read(joinpath(model.Output.out_dir, model.Output.param_file_name), String)
    @test occursin("surf_mode        =  2", input)
    @test occursin("<FastScapeStart>", input)
    @test occursin("sed_phases            =  2", input)
    @test !occursin("sealevel", input)      # marine parameters are only written for set_marine = 1
    @test isfile(joinpath(model.Output.out_dir, model.Output.out_file_name * "_fs.pvd"))

    rm(model.Output.out_dir, force=true, recursive=true)
end

@testset "Phase injection (t_inject)" begin
    # a box of phase 1 that is stamped onto the markers after the 2nd time step
    box = GeomBox(phase=1, bounds=[-0.25, 0.25, -0.25, 0.25, -0.25, 0.25], t_inject=[1.5])
    @test box.n_inject == 1
    @test isnothing(GeomBox().n_inject)

    model = Model(Grid(nel=(16,16,16), x=[-1,1], y=[-1,1], z=[-1,1]),
                  Time(nstep_max=3, dt=1, dt_max=1, nstep_out=1, time_end=100),
                  ModelSetup(msetup="geom"),
                  Output(out_dir="inject_test_folder"))
    add_phase!(model, Phase(ID=0, Name="matrix", eta=1e20, rho=3000), Phase(ID=1, Name="block", eta=1e22, rho=3200))
    add_geom!(model, box)
    run_lamem(model, 1, logfile="inject")

    input = read(joinpath(model.Output.out_dir, model.Output.param_file_name), String)
    @test occursin("n_inject", input) && occursin("t_inject", input)

    data0, _ = read_LaMEM_timestep(model, 0)
    data3, _ = read_LaMEM_timestep(model, last=true)
    @test maximum(data0.fields.phase) < 0.5       # not present at t = 0
    @test maximum(data3.fields.phase) > 0.5       # injected later

    rm(model.Output.out_dir, force=true, recursive=true)
end
