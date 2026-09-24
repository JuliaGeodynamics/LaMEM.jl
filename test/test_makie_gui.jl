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

    # the controls are there: two menus (field, colormap), three sliders (timestep, slice,
    # iso level), two toggles (isosurface, arrows) and the play button
    contents = collect(values(fig.content))
    menus   = filter(c -> c isa Makie.Menu,   contents)
    sliders = filter(c -> c isa Makie.Slider, contents)
    toggles = filter(c -> c isa Makie.Toggle, contents)
    buttons = filter(c -> c isa Makie.Button, contents)
    @test length(menus)   == 2
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

    # a model without output cannot be animated, and should say so
    empty_model = Model(Grid(nel=(8,8,8), x=[-1,1], coord_y=[-1,1], coord_z=[-1,1]),
                        Output(out_dir="makie_gui_empty"))
    @test_throws ErrorException save_movie(joinpath(tempdir(),"never.mp4"), empty_model)

    rm(model.Output.out_dir, force=true, recursive=true)
end
