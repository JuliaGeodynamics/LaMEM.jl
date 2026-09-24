# Tests the Makie plotting extension. We use CairoMakie here rather than GLMakie, since it
# needs no interactive display and therefore also works on the CI runners.
using Test
using CairoMakie
using GeophysicalModelGenerator

@testset "Makie extension" begin
    pkg_dir = pkgdir(LaMEM)

    # the recipes only exist once a Makie backend is loaded
    @test !isempty(methods(LaMEM.crosssection!))
    @test !isempty(methods(LaMEM.topo!))
    @test !isempty(methods(LaMEM.phasediagram!))

    model = Model(Grid(nel=(16,16,16), x=[-2,2], coord_y=[-1,1], coord_z=[-1,1]),
                  Time(nstep_max=1, dt=1, dt_max=10),
                  Solver(SolverType="direct"),
                  Output(out_dir="makie_test"))
    rm_phase!(model)
    add_phase!(model, Phase(ID=0,Name="matrix",eta=1e20,rho=3000),
                      Phase(ID=1,Name="sphere",eta=1e23,rho=3200))
    add_sphere!(model, cen=(0.0,0.0,0.0), radius=0.5)

    # the initial setup can be plotted without having run LaMEM
    lab = axis_labels(model, :phase, x=0)
    @test lab.xlabel == "y"
    @test lab.ylabel == "z"
    @test lab.colorbar == "phase"

    fig = Figure()
    ax  = Axis(fig[1,1], xlabel=lab.xlabel, ylabel=lab.ylabel, title=lab.title)
    p   = crosssection!(ax, model, field=:phase, x=0)
    @test p isa Makie.Plot
    Colorbar(fig[1,2], p, label=lab.colorbar)

    # the non-mutating form makes its own figure
    @test crosssection(model, field=:phase, x=0) isa Makie.FigureAxisPlot

    run_lamem(model, 1)

    # a timestep of the run, and a component of a vector field
    lab2 = axis_labels(model, :velocity, dim=3, x=0, timestep=:last)
    @test lab2.colorbar == "velocity[3]"
    @test occursin("time=", lab2.title)          # the time is added to the title
    fig2 = Figure()
    ax2  = Axis(fig2[1,1])
    @test crosssection!(ax2, model, field=:velocity, dim=3, x=0, timestep=:last) isa Makie.Plot

    # ... and the same from a CartData set that was read separately
    data, _ = read_LaMEM_timestep(model, last=true)
    fig3 = Figure()
    ax3  = Axis(fig3[1,1])
    @test crosssection!(ax3, data, field=:phase, x=0) isa Makie.Plot

    # the figures actually render (this is what catches a broken recipe)
    file = joinpath(tempdir(), "LaMEM_makie_test.png")
    rm(file, force=true)
    save(file, fig)
    @test isfile(file)
    @test filesize(file) > 1000
    rm(file, force=true)

    # phase diagrams
    cur_dir = pwd()
    try
        cd(joinpath(pkg_dir,"test"))
        labpd = axis_labels("Rhyolite.in", :ρ)
        @test labpd.ylabel == "Pressure [kbar]"
        figpd = Figure()
        axpd  = Axis(figpd[1,1], xlabel=labpd.xlabel, ylabel=labpd.ylabel)
        @test phasediagram!(axpd, "Rhyolite.in", :ρ) isa Makie.Plot
    finally
        cd(cur_dir)
    end

    rm(model.Output.out_dir, force=true, recursive=true)
end
