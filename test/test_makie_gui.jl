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

    # the controls are there: four menus (field, colormap, contour overlay, slice axis),
    # three sliders (timestep, slice, iso level) each with a text box beside it for an exact
    # value, two toggles (isosurface, arrows) and the play button
    contents = collect(values(fig.content))
    menus   = filter(c -> c isa Makie.Menu,   contents)
    sliders = filter(c -> c isa Makie.Slider, contents)
    toggles = filter(c -> c isa Makie.Toggle, contents)
    buttons = filter(c -> c isa Makie.Button, contents)
    @test length(menus)   == 4
    @test length(sliders) == 3
    @test length(toggles) == 2
    @test length(buttons) == 1
    @test length(filter(c -> c isa Makie.Textbox, contents)) == 3

    # the field menu lists the scalars, and one entry per component of the velocity
    labels = [e[1] for e in first(menus).options[]]
    @test "phase" in labels
    @test "velocity[3]" in labels          # a vector field is expanded per component

    # moving the timestep slider changes what is displayed, without throwing
    step_slider = only(filter(sl -> collect(sl.range[]) == [1,2], sliders))
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

    # the contour menu offers "none" plus the fields, and starts on the chosen one.
    # `fig.content` is not in construction order, so find each menu by what it holds.
    menus2d = filter(c -> c isa Makie.Menu, collect(values(fig2d.content)))
    over    = only(filter(m -> "none" in [e[1] for e in m.options[]], menus2d))
    @test over.selection[] == (:temperature, 1)

    # the slice axis can be chosen, which rescales the position slider to that axis
    axis_menu = only(filter(m -> [e[1] for e in m.options[]] == ["x","y","z"], menus2d))
    # identify the position slider by its range: it spans the model, not 1:n or 0:1
    sliders2d = filter(c -> c isa Makie.Slider, collect(values(fig2d.content)))
    pos2d     = only(filter(sl -> length(sl.range[]) == 401, sliders2d))
    axis_menu.i_selected[] = 1                       # slice along x instead
    @test extrema(collect(pos2d.range[])) == (-1000.0, 1000.0)

    # and an exact position can be typed into the box beside the slider: the box that
    # currently shows the slider's own value is the one bound to it
    boxes2d = filter(c -> c isa Makie.Textbox, collect(values(fig2d.content)))
    shown(b) = tryparse(Float64, something(b.displayed_string[], ""))
    pos_box  = first(filter(b -> !isnothing(shown(b)) &&
                                 isapprox(shown(b), pos2d.value[]; atol=1e-3), boxes2d))
    pos_box.stored_string[] = "-300"
    @test pos2d.value[] ≈ -300 atol=10

    # the arrows are subsampled to a fixed count, not a fixed stride, so a high-resolution
    # model does not end up with a black mass of them
    ext3 = Base.get_extension(LaMEM, :MakieExt)
    function arrow_count(nel)
        mm = Model(Grid(x=[-2000.,2000.], z=[-660,40], nel=nel), Output(out_dir="arrow_test"))
        dd = CartData(mm.Grid.Grid.X, mm.Grid.Grid.Y, mm.Grid.Grid.Z,
                      (phase=mm.Grid.Phases,
                       velocity=(mm.Grid.Grid.X, mm.Grid.Grid.Y, mm.Grid.Grid.Z)))
        return length(ext3.velocity_arrows(dd, :y, 0.0).x)
    end
    @test arrow_count((512,128)) < 400          # the high-resolution case from the report
    @test arrow_count((32,16))   < 400
    @test arrow_count((512,128)) > 20           # but still enough to read the flow

    # switching the displayed field must not throw either: `phase` is an integer field and
    # the temperature a float one, so an observable typed from the first value cannot hold
    # both (`InexactError: Int32(1543.6...)`)
    field_menu_2d = first(filter(m -> "phase" in [e[1] for e in m.options[]] &&
                                      !("none" in [e[1] for e in m.options[]]),
                                 filter(c -> c isa Makie.Menu, collect(values(fig2d.content)))))
    # (not `@test_nowarn`: a constant field makes PlotUtils warn about tick placement,
    # which is cosmetic and unrelated)
    for i in eachindex(field_menu_2d.options[])
        field_menu_2d.i_selected[] = i
        @test field_menu_2d.selection[] == field_menu_2d.options[][i][2]
    end
    field_menu_2d.i_selected[] = 1

    # choosing a contour field after the viewer opened must not throw: the overlay
    # observable starts on `nothing`, and a plain `lift` would type it `Observable{Nothing}`
    over_2 = only(filter(m -> "none" in [e[1] for e in m.options[]],
                         filter(c -> c isa Makie.Menu, collect(values(fig2d.content)))))
    over_2.i_selected[] = 1                                   # back to "none"
    @test over_2.selection[] === nothing
    idx_T = findfirst(e -> e[1] == "temperature", over_2.options[])
    if !isnothing(idx_T)
        @test_nowarn over_2.i_selected[] = idx_T              # this used to throw
        @test over_2.selection[] == (:temperature, 1)
    end

    file2d = joinpath(tempdir(), "LaMEM_viewer_2d.png")
    rm(file2d, force=true)
    save(file2d, fig2d)
    @test isfile(file2d)
    @test filesize(file2d) > 1000
    rm(file2d, force=true)

    rm(model2d.Output.out_dir, force=true, recursive=true)

    # a `Model` says whether it is 2D itself: LaMEM needs two elements in every direction,
    # so `nel_y == 2` is exactly what `Grid(nel=(nx,nz))` gives
    ext2 = Base.get_extension(LaMEM, :MakieExt)
    @test ext2.is_2d(Model(Grid(x=[-2000.,2000.], z=[-660,40], nel=(512,128)),
                           Output(out_dir="is2d_test_2d")))
    @test !ext2.is_2d(Model(Grid(nel=(16,16,16), x=[-1,1], y=[-1,1], z=[-1,1]),
                            Output(out_dir="is2d_test_3d")))

    # Without the model, it is inferred from the grid, which has to hold for the marker grid
    # of a setup as well as for LaMEM output. A 2D
    # setup written as `Grid(nel=(nx,nz))` has three points across in its output but six in
    # its marker grid, so an absolute threshold is not enough; and a genuinely thin 3D model
    # must not be mistaken for a 2D one.
    flat(dims) = CartData(zeros(dims...), zeros(dims...), zeros(dims...), (phase=zeros(dims...),))
    @test ext2.is_2d(flat((1536, 6, 384)))      # 2D setup, markers, nel=(512,128)
    @test ext2.is_2d(flat((96, 6, 48)))         # 2D setup, markers, nel=(32,16)
    @test ext2.is_2d(flat((33, 3, 17)))         # 2D output
    @test !ext2.is_2d(flat((17, 17, 17)))       # 3D output
    @test !ext2.is_2d(flat((48, 48, 48)))       # 3D setup, markers
    @test !ext2.is_2d(flat((33, 33, 9)))        # thin, but genuinely 3D

    # the outline of the slice plane must be five points, not a flattened list of
    # coordinates: `[corners; corners[1]]` splats the trailing point, since a Point3f is
    # itself iterable, and Makie then recurses on it
    ext = Base.get_extension(LaMEM, :MakieExt)
    outline = ext.slice_outline((-1.0,1.0), (-1.0,1.0), (-1.0,1.0), :x, 0.0)
    @test length(outline) == 5
    @test eltype(outline) <: Makie.Point3
    @test outline[1] == outline[end]            # closed

    # `threed=false` leaves the 3D panel out of a 3D model as well
    fig_flat = view_model(model, field=:phase, threed=false)
    @test isempty(filter(c -> c isa Makie.Axis3, collect(values(fig_flat.content))))

    # a model without output cannot be animated, and should say so
    empty_model = Model(Grid(nel=(8,8,8), x=[-1,1], coord_y=[-1,1], coord_z=[-1,1]),
                        Output(out_dir="makie_gui_empty"))
    @test_throws ErrorException save_movie(joinpath(tempdir(),"never.mp4"), empty_model)

    rm(model.Output.out_dir, force=true, recursive=true)
end
