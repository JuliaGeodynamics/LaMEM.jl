# Tests the interactive viewer of the Makie extension.
#
# We use CairoMakie here, so that this runs on a machine (or CI runner) without a display.
# Note that CairoMakie cannot rasterize `volume`/3D `contour`, so the 3D panel stays empty
# here; what we check is that the viewer is built, that its controls are wired up, and that
# it renders. The 3D view itself needs GLMakie.
using Test
using CairoMakie
using GeophysicalModelGenerator

@testset "Makie viewer" begin

    model = Model(Grid(nel=(16,16,16), x=[-2,2], coord_y=[-1,1], coord_z=[-1,1]),
                  Time(nstep_max=2, nstep_out=1, dt=1, dt_max=10),
                  Solver(SolverType="direct"),
                  Output(out_dir="makie_gui_test", out_velocity=1, out_temperature=1))
    rm_phase!(model)
    add_phase!(model, Phase(ID=0,Name="matrix",eta=1e20,rho=3000),
                      Phase(ID=1,Name="sphere",eta=1e23,rho=3200))
    add_sphere!(model, cen=(0.0,0.0,0.0), radius=0.5)

    # the viewer opens on a model that has not been run, showing the initial setup
    fig_setup = view_model(model)
    @test fig_setup isa Makie.Figure

    run_lamem(model, 1)

    fig = view_model(model, field=:phase, arrows=true)
    @test fig isa Makie.Figure

    # the controls are there: three menus (field, colormap, contour overlay), three sliders
    # (timestep, slice, iso level), two toggles (isosurface, arrows) and the play button
    contents = collect(values(fig.content))
    menus   = filter(c -> c isa Makie.Menu,   contents)
    sliders = filter(c -> c isa Makie.Slider, contents)
    toggles = filter(c -> c isa Makie.Toggle, contents)
    buttons = filter(c -> c isa Makie.Button, contents)
    @test length(menus)   == 3
    @test length(sliders) == 3
    @test length(toggles) == 2
    @test length(buttons) == 1

    # the field menu lists the scalars, and one entry per component of the velocity
    labels = [e[1] for e in first(menus).options[]]
    @test "phase" in labels
    @test "velocity[3]" in labels          # a vector field is expanded per component

    # moving the timestep slider changes what is displayed, without throwing
    step_slider = argmax(s -> length(s.range[]) == 2 ? 1 : 0, sliders)
    @test_nowarn step_slider.value[] = 1

    # the toggles switch the isosurface and the arrows
    for t in toggles
        @test_nowarn t.active[] = !t.active[]
    end

    # and the figure renders
    file = joinpath(tempdir(), "LaMEM_viewer_test.png")
    rm(file, force=true)
    save(file, fig)
    @test isfile(file)
    @test filesize(file) > 1000
    rm(file, force=true)

    # a movie of the simulation can be written to disk
    movie = joinpath(tempdir(), "LaMEM_viewer_test.mp4")
    rm(movie, force=true)
    @test save_movie(movie, model, field=:phase) == movie
    @test isfile(movie)
    @test filesize(movie) > 1000
    rm(movie, force=true)

    # --- a 2D model gets no 3D panel, and can take contours of a second field -----------
    model2d = Model(Grid(nel=(32,16), x=[-1000,1000], z=[-660,20]),
                    Time(nstep_max=1, dt=0.01, dt_max=0.5),
                    Solver(SolverType="direct"),
                    Output(out_dir="makie_gui_2d", out_velocity=1, out_temperature=1))
    rm_phase!(model2d)
    add_phase!(model2d, Phase(ID=0,Name="air",eta=1e18,rho=1),
                        Phase(ID=1,Name="mantle",eta=1e20,rho=3200))
    add_box!(model2d; xlim=(-1000,1000), zlim=(-660,0), phase=ConstantPhase(1),
             T=LinearTemp(Ttop=0,Tbot=1350))
    run_lamem(model2d, 1)

    fig2d = view_model(model2d, field=:phase, contours=:temperature)
    @test fig2d isa Makie.Figure

    # one Axis and no Axis3: the 3D panel is left out for a 2D model
    axes2d = filter(c -> c isa Makie.Axis,  collect(values(fig2d.content)))
    axes3d = filter(c -> c isa Makie.Axis3, collect(values(fig2d.content)))
    @test length(axes2d) == 1
    @test isempty(axes3d)

    # while a 3D model keeps both
    axes3d_of_3d = filter(c -> c isa Makie.Axis3, collect(values(fig.content)))
    @test length(axes3d_of_3d) == 1

    # the contour menu offers "none" plus the fields, and starts on the chosen one
    menus2d = filter(c -> c isa Makie.Menu, collect(values(fig2d.content)))
    over    = last(menus2d)
    @test "none" in [e[1] for e in over.options[]]
    @test over.selection[] == (:temperature, 1)

    file2d = joinpath(tempdir(), "LaMEM_viewer_2d.png")
    rm(file2d, force=true)
    save(file2d, fig2d)
    @test isfile(file2d)
    @test filesize(file2d) > 1000
    rm(file2d, force=true)

    rm(model2d.Output.out_dir, force=true, recursive=true)

    # a model without output cannot be animated, and should say so
    empty_model = Model(Grid(nel=(8,8,8), x=[-1,1], coord_y=[-1,1], coord_z=[-1,1]),
                        Output(out_dir="makie_gui_empty"))
    @test_throws ErrorException save_movie(joinpath(tempdir(),"never.mp4"), empty_model)

    rm(model.Output.out_dir, force=true, recursive=true)
end
