using Test, Base.Sys
using LaMEM, GeophysicalModelGenerator

# Tests LaMEM's dylib_plugin feature: a user-defined phase-transition rule,
# written in Julia and compiled to a shared library with JuliaC.jl, loaded
# by LaMEM at runtime via `dylib_plugin = <path>` / `phase_transitions = dylib`
# in the .dat file (see LaMEM's src/dylib_plugins.h). The plugin uses the
# plugin ABI v3 (struct-based `lamem_phase_transition(markers, cells, step,
# scaling)`), which needs a LaMEM_jll whose loader speaks ABI v3.
#
# The second part does the same from a julia `Model`, through the
# `build_phase_transition_plugin` / `PhaseTransition(Type="dylib")` interface of LaMEM.jl.
#
# Building the plugin needs Julia >= 1.12 (`juliac --trim`); older versions
# skip. Everything else is a hard failure: the plugin is supported on Linux,
# macOS and Windows.

pkg_dir = pkgdir(LaMEM)
plugin_dir = joinpath(pkg_dir, "test", "dylib_plugin_test")

# Pkg.test runs the tests with JULIA_LOAD_PATH="@:<test env>", which has no
# @stdlib entry, so a child process started with its own --project cannot
# even `using Pkg`. Give the children a load path of their project + stdlibs.
# (the load-path separator is ';' on Windows, ':' elsewhere)
julia_cmd(args...) = addenv(`$(Base.julia_cmd()) --startup-file=no $(args)`,
                            "JULIA_LOAD_PATH" => join(("@", "@stdlib"), Sys.iswindows() ? ";" : ":"))

# .dat output of a user-defined phase transition (PhaseTransition(Type="dylib")), without running LaMEM
@testset "dylib phase transition input file" begin
    # the helper files shipped with LaMEM.jl must be the ones the fixtures (synced with LaMEM's
    # scripts/dylib_plugins/) were tested with
    @test isfile(LaMEMPlugin_path())
    @test read(LaMEMPlugin_path()) == read(joinpath(plugin_dir, "LaMEMPlugin.jl"))
    @test read(joinpath(pkg_dir, "src", "dylib_plugins", "build_plugin.jl")) == read(joinpath(plugin_dir, "build_plugin.jl"))

    # the docs show the example verbatim
    example  = read(joinpath(pkg_dir, "example_scripts", "PhaseTransitionPlugin.jl"), String)
    rule     = read(joinpath(pkg_dir, "example_scripts", "ptlib_melting.jl"), String)
    docspage = read(joinpath(pkg_dir, "docs", "src", "phase_transition_plugins.md"), String)
    @test occursin(example, docspage)
    @test occursin(rule, docspage)

    # the value of a keyword LaMEM reads, e.g. "    dylib_plugin       =  /path   # comment"
    dat_value(dat, key) = (m = match(Regex("^\\s*$key\\s+=\\s+(\\S+)", "m"), dat); isnothing(m) ? nothing : String(m.captures[1]))

    builtin = PhaseTransition(ID=0, Type="Constant", Parameter_transition="T", PhaseBelow=[0], PhaseAbove=[1], ConstantValue=1000)
    function write_dat(phase_transitions...)
        model = Model(Grid(nel=(8,8)), Output(write_VTK_setup=false),
                      Materials(PhaseTransitions=[phase_transitions...]))
        add_phase!(model, Phase(ID=0, Name="matrix"), Phase(ID=1, Name="sphere"))
        add_sphere!(model, cen=(0.0,0.0,-5.0), radius=2.0)
        mktempdir() do dir
            fname = joinpath(dir, "plugin.dat")
            write_LaMEM_inputFile(model, fname)
            return read(fname, String), model
        end
    end

    # no plugin: nothing is written, and LaMEM uses its built-in phase transitions only
    dat, model = write_dat(builtin)
    @test isnothing(dat_value(dat, "dylib_plugin"))
    @test isnothing(dat_value(dat, "phase_transitions"))
    @test model.SolutionParams.Phasetrans == 1
    @test isnothing(PhaseTransition().library)

    # a plugin: two top-level keywords instead of a <PhaseTransitionStart> block; the built-in
    # transitions are written as before
    lib = "/some/dir/build_myrule/lib/libptlib_myrule.so"
    dat, model = write_dat(builtin, PhaseTransition(Type="dylib", library=lib))
    @test dat_value(dat, "dylib_plugin") == lib
    @test dat_value(dat, "phase_transitions") == "dylib"
    @test count("<PhaseTransitionStart>", dat) == 1
    @test isnothing(dat_value(dat, "library"))
    @test dat_value(dat, "Type") == "Constant"
    @test findfirst("dylib_plugin", dat)[1] < findfirst("<PhaseTransitionStart>", dat)[1]
    @test model.SolutionParams.Phasetrans == 1
    @test occursin("PhaseTransition(Type=dylib,library=$lib)", sprint(show, model.Materials))

    # the plugin alone does not need Phasetrans; a relative path is written as given
    dat, model = write_dat(PhaseTransition(Type="dylib", library="build_myrule/lib/libptlib_myrule.so"))
    @test dat_value(dat, "dylib_plugin") == "build_myrule/lib/libptlib_myrule.so"
    @test dat_value(dat, "phase_transitions") == "dylib"
    @test !occursin("<PhaseTransitionStart>", dat)
    @test model.SolutionParams.Phasetrans == 0

    # a library is only used with Type="dylib"
    dat, _ = @test_logs (:warn, r"is ignored") match_mode=:any write_dat(PhaseTransition(ID=0, Type="Constant", Parameter_transition="T", PhaseBelow=[0], PhaseAbove=[1], ConstantValue=1000, library=lib))
    @test isnothing(dat_value(dat, "dylib_plugin"))
    @test isnothing(dat_value(dat, "library"))

    # mistakes are caught before LaMEM runs: no library, two plugins, paths LaMEM cannot read
    @test_throws ErrorException write_dat(PhaseTransition(Type="dylib"))
    @test_throws ErrorException write_dat(PhaseTransition(Type="dylib", library=lib), PhaseTransition(Type="dylib", library=lib))
    @test_throws ErrorException write_dat(PhaseTransition(Type="dylib", library="/my dir/libptlib_x.so"))
    @test_throws ErrorException write_dat(PhaseTransition(Type="dylib", library="/dir#1/libptlib_x.so"))
end

@testset "dylib_plugin" begin
    if VERSION < v"1.12"
        @test_skip "building the plugin needs Julia >= 1.12 (juliac --trim)"
    else
        # Build the plugin bundle with JuliaC.jl in a temporary, isolated
        # Julia environment so this does not touch the user's own project.
        build_env = mktempdir()
        run(julia_cmd("--project=$build_env", "-e", "using Pkg; Pkg.add(\"JuliaC\")"))

        # A bundle left over from an earlier run makes JuliaC's artifact copy
        # fail ("... exists. `force=true` is required"), so start clean.
        rm(joinpath(plugin_dir, "build_constant"); force = true, recursive = true)

        rule_file = joinpath(plugin_dir, "ptlib_constant.jl")
        build_script = joinpath(plugin_dir, "build_plugin.jl")
        run(julia_cmd("--project=$build_env", build_script, rule_file, plugin_dir))

        # JuliaC's bundles are <out>/lib/*.{so,dylib} on Unix, but flat under
        # <out>/bin/ on Windows.
        bundle_path = if Sys.iswindows()
            joinpath(plugin_dir, "build_constant", "bin", "libptlib_constant.dll")
        else
            joinpath(plugin_dir, "build_constant", "lib", "libptlib_constant.$(Sys.isapple() ? "dylib" : "so")")
        end
        @test isfile(bundle_path)

        ParamFile = joinpath(plugin_dir, "PT0_only_plugin.dat")
        logfile = joinpath(plugin_dir, "dylib_plugin_test.log")

        out = run_lamem(ParamFile, 1, "-dylib_plugin $bundle_path"; logfile = logfile)
        @test isnothing(out)

        # The plugin reimplements the .dat's built-in "Constant" phase
        # transition; on this setup it flips a known number of markers
        # from phase 2 to phase 3 at the very first step. Checking that
        # count (rather than just that LaMEM exits cleanly) confirms the
        # plugin library was actually loaded and its rule actually ran,
        # not just that LaMEM ignored the option.
        @test isfile(logfile)
        log = read(logfile, String)
        @test occursin("Dylib plugin", log)
        # plugin ABI v3 (struct-based lamem_phase_transition); LaMEM prints
        # the version the loaded library reports in its parameter block
        @test occursin("Plugin ABI version                      : 3", log)
        # per-step summary: "Dylib plugin  : N marker(s) changed phase,
        # M marker(s) changed temperature, K marker(s) changed other fields"
        m = match(r"Dylib plugin\s*:\s*(\d+) marker\(s\) changed phase", log)
        @test !isnothing(m)
        if !isnothing(m)
            @test parse(Int, m.captures[1]) == 27512
        end

        # ----------------------------------------------------------------------------------
        # The same rule from a julia Model setup: built with build_phase_transition_plugin and
        # added as PhaseTransition(Type="dylib"), without touching a .dat file or CLI options.
        # ptlib_constant.jl turns phase 2 into phase 3 where T >= 1200 °C (and back below).
        # ----------------------------------------------------------------------------------
        library = build_phase_transition_plugin(rule_file; output_dir = mktempdir(), julia_env = build_env)
        @test isfile(library)
        @test isabspath(library)
        @test basename(library) == basename(bundle_path)

        model = Model(Grid(nel=(16,16), x=[-50,50], z=[-50,0]),
                      Time(nstep_max=2, dt=0.001, dt_max=0.001),
                      Output(out_dir="dylib_plugin_model", write_VTK_setup=false))
        add_phase!(model, Phase(ID=0, Name="mantle", eta=1e22, rho=3300),
                          Phase(ID=1, Name="unused", eta=1e21, rho=3000),
                          Phase(ID=2, Name="below",  eta=1e21, rho=2800),
                          Phase(ID=3, Name="above",  eta=1e21, rho=2700))
        model.Grid.Temp .= 1300.0       # hot, but phase 0 is not touched by the rule
        add_box!(model, xlim=(-50,50), zlim=(-30,0), phase=ConstantPhase(2), T=ConstantTemp(1000))  # stays phase 2
        add_sphere!(model, cen=(0,0,-15), radius=8, phase=ConstantPhase(2), T=ConstantTemp(1300))  # becomes phase 3
        add_phasetransition!(model, PhaseTransition(Type="dylib", library=library))
        @test maximum(model.Grid.Phases) == 2
        @test model.SolutionParams.Phasetrans == 0      # not needed for the plugin

        run_lamem(model, 1; logfile = "plugin")
        log = read(joinpath(model.Output.out_dir, "plugin.log"), String)
        @test occursin("Dylib plugin parameters:", log)
        @test occursin("Plugin ABI version                      : 3", log)
        @test occursin("Phase transitions                       : dylib", log)
        m = match(r"Dylib plugin\s*:\s*(\d+) marker\(s\) changed phase", log)   # first step
        @test !isnothing(m) && parse(Int, m.captures[1]) > 0

        data, _ = read_LaMEM_timestep(model, last = true)
        @test any(data.fields.phase .> 2.5)          # the hot sphere is phase 3 now
        @test any(data.fields.phase .< 0.5)          # the hot mantle is still phase 0
        rm(model.Output.out_dir; force = true, recursive = true)
        rm(dirname(dirname(library)); force = true, recursive = true)
    end
end
