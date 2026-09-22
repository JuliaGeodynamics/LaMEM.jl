# This is the main LaMEM Model struct
using GeophysicalModelGenerator.GeoParams
import LaMEM.Run: run_lamem, run_lamem_save_grid, mpi_available
import LaMEM: passivetracer_time, project_onto_crosssection
using LaMEM.Run.LaMEM_jll

export Model, write_LaMEM_inputFile, create_initialsetup, run_lamem, prepare_lamem, project_onto_crosssection

"""
    Model

Structure that holds all the information to create a LaMEM input file

    $(TYPEDFIELDS)
"""
mutable struct Model
    "Scaling parameters"
    Scaling::Scaling
    
    "LaMEM Grid"
    Grid::Grid
    
    "Time options"
    Time

    "Free surface options"
    FreeSurface

    "Boundary conditions"
    BoundaryConditions

    "Global solution parameters"
    SolutionParams

    "Solver options and optional PETSc options"
    Solver

    "Model setup"
    ModelSetup

    "Output options"
    Output

    "Passive tracers"
    PassiveTracers

    "Material parameters for each of the phases"
    Materials

    
end

"""
    Model(;
        Scaling=Scaling(GEO_units()),
        Grid=Grid(), 
        Time=Time(),
        FreeSurface=FreeSurface(),
        BoundaryConditions=BoundaryConditions(),
        SolutionParams=SolutionParams(),
        Solver=Solver(),
        ModelSetup=ModelSetup(),
        Output=Output(),
        PassiveTracers=PassiveTracers(),
        Materials=Materials()
        )

Creates a LaMEM Model setup.

    $(TYPEDFIELDS)

"""
function Model(;
    Scaling=Scaling(GEO_units()),
    Grid=Grid(), 
    Time=Time(),
    FreeSurface=FreeSurface(),
    BoundaryConditions=BoundaryConditions(),
    SolutionParams=SolutionParams(),
    Solver=Solver(),
    ModelSetup=ModelSetup(),
    Output=Output(),
    PassiveTracers=PassiveTracers(),
    Materials=Materials()
    )

    return Model(Scaling, Grid, Time, FreeSurface, BoundaryConditions, 
                SolutionParams, Solver, ModelSetup, Output, PassiveTracers, Materials)
end

include("DefaultParams.jl")             # main LaMEM_Model

"""
    Model(args...)

Allow to define a model setup by specifying some of the basic objects

Example
===
```julia
julia> d = Model(Grid(nel=(10,2,20)), Scaling(NO_units()))
LaMEM Model setup
|
|-- Scaling             :  GeoParams.Units.GeoUnits{GeoParams.Units.NONE}
|-- Grid                :  nel=(10, 2, 20); xϵ(-10.0, 10.0), yϵ(-10.0, 0.0), zϵ(-10.0, 0.0) 
|-- Time                :  nstep_max=50; nstep_out=1; time_end=1.0; dt=0.05
|-- Boundary conditions :  noslip=[0, 0, 0, 0, 0, 0]
|-- Solution parameters :  
|-- Solver options      :  coupled_direct; mumps; penalty=1000.0
|-- Model setup options :  Type=geom; 
|-- Output options      :  filename=output; pvd=1; avd=0; surf=0
|-- Materials           :  1 phases;  

```

"""
function Model(args...)
    names_str = typeof.(args);  # this may have { } in them
    names_strip = ();
    for name in names_str
        name_str = split("$name","{")[1]
        name_str = split("$name_str",".")[end]
        
        names_strip = (names_strip..., name_str)
    end 
    args_tuple = NamedTuple{Symbol.(names_strip)}(args)

    model = Model(; args_tuple...)
    model = UpdateDefaultParameters(model)

    return model
end

# Show brief overview of Model
function show(io::IO, d::Model)
    println(io,"LaMEM Model setup")
    println(io,"|")
    show_short(io, d.Scaling)   
    show_short(io, d.Grid)     
    show_short(io, d.Time)      
    show_short(io, d.FreeSurface)   
    show_short(io, d.BoundaryConditions)   
    show_short(io, d.SolutionParams)   
    show_short(io, d.Solver)   
    show_short(io, d.ModelSetup)   
    show_short(io, d.Output)   
    show_short(io, d.PassiveTracers)   
    show_short(io, d.Materials)
end

"""
    write_LaMEM_inputFile(d::Model,fname::String; dir=pwd())

Writes a LaMEM input file based on the data stored in Model
"""
function write_LaMEM_inputFile(d::Model, fname::String="input.dat"; dir=pwd(), warn_constant_grid=true)
    Check_LaMEM_Model(d; warn_constant_grid)    # check for mistakes in input

    if d.Output.write_VTK_setup
        # If we want to write an input file 
        write_paraview(CartData(d.Grid.Grid, (Phases=d.Grid.Phases,Temp=d.Grid.Temp,APS=d.Grid.APS)),"Model3D")
    end
    
    if any(hasplasticity.(d.Materials.Phases))
        # We have plasticity, so we likely want to see that
        d.Output.out_plast_strain    = 1     # accumulated plastic strain
        d.Output.out_plast_dissip    = 1      # plastic dissipation
    end

    io = open(fname,"w")
    try
        write_LaMEM_inputFile(io, d.Scaling)
        write_LaMEM_inputFile(io, d.Grid)
        write_LaMEM_inputFile(io, d.Time)
        write_LaMEM_inputFile(io, d.FreeSurface)
        write_LaMEM_inputFile(io, d.BoundaryConditions)
        write_LaMEM_inputFile(io, d.SolutionParams)
        write_LaMEM_inputFile(io, d.Solver)
        write_LaMEM_inputFile(io, d.ModelSetup)
        write_LaMEM_inputFile(io, d.Output)
        write_LaMEM_inputFile(io, d.PassiveTracers)
        write_LaMEM_inputFile(io, d.Materials)

        write_LaMEM_inputFile_PETSc(io, d.Solver)   # add PETSc options last
    finally
        # Always close the file, also if writing throws. On windows an open handle
        # prevents the enclosing directory from being removed ("permission denied").
        close(io)
    end
end


"""
    run_lamem(model::Model, cores::Int64=1, args::String=""; wait=true, add_APS=false, logfile=nothing)

Performs a LaMEM run for the parameters specified in `model`.

- `cores`: number of MPI cores to use
- `args`: additional command-line arguments passed to LaMEM
- `wait`: if `true`, wait for the simulation to finish before returning
- `add_APS`: if `true`, write accumulated plastic strain (APS) to marker files.
  Requires LaMEM ≥ 2.2.1 (header 1211215). Default is `false` (LaMEM ≥ 2.2.0).
- `logfile`: if given, the LaMEM output is written to this file *in addition* to being
  shown in the REPL. A name without an extension gets `".log"` appended, and a relative
  name ends up in `model.Output.out_dir`, next to the other output of the run.

# Example
```julia
julia> run_lamem(model, 1, logfile="test")   # output is shown, and saved to <out_dir>/test.log
```
"""
function run_lamem(model::Model, cores::Int64=1, args::String=""; wait=true, add_APS=false, warn_constant_grid=true, logfile=nothing)

    cur_dir = pwd();

    #if !isdir(model.Output.out_dir); mkdir(model.Output.out_dir); end # create directory if needed
    create_initialsetup(model, cores, args; add_APS, warn_constant_grid);
    
    try
        if !isempty(model.Output.out_dir)
            cd(model.Output.out_dir)
        end

        # note: we are inside out_dir here, so a relative logfile is written there
        run_lamem(model.Output.param_file_name, cores, args; wait=wait, logfile=logfile)
    finally
        # Always return to the original directory, also if the run throws. On windows a
        # directory cannot be deleted while it is the current directory of a process, so
        # leaving the cwd inside out_dir makes a later `rm(out_dir)` fail.
        cd(cur_dir)
    end

    return nothing
end

"""
    prepare_lamem(model::Model, cores::Int64=1, args::String=""; verbose=false, add_APS=false)

Prepares a LaMEM run for the parameters specified in `model`, without running the simulation:
    1) Create the `*.dat` file
    2) Write markers to disk in case we use a "files" setup

This is useful if you want to prepare a model on one machine but run it on another one (e.g. a cluster).

- `add_APS`: if `true`, write accumulated plastic strain (APS) to marker files (requires LaMEM ≥ 2.2.1)

Set `model.Output.write_VTK_setup` to `true` if you want to write a `VTK` file of the model setup.
"""
function prepare_lamem(model::Model, cores::Int64=1, args::String=""; verbose=false, add_APS=false, warn_constant_grid=true)

    println("Creating LaMEM input files in the directory: $(model.Output.out_dir)")
    cur_dir = pwd();

    try
        create_initialsetup(model, cores, args; verbose, add_APS, warn_constant_grid);
    finally
        # always restore the cwd, also on error (windows cannot delete the cwd of a process)
        cd(cur_dir)
    end

    println("Generated output generated for $cores cores:")
    println("   Base directory       : $(pwd())")
    println("   LaMEM parameter file : $(model.Output.out_dir)/$(model.Output.param_file_name)")
    println("   Marker files         : $(model.Output.out_dir)/markers/")
    println("Copy these files over to the computer where you want to run your simulation")

    return nothing
end



"""
    passivetracer_time(model::Model, cores::Int64=1, args::String=""; wait=true)

Placeholder for passive tracer time evolution using the configuration in `model`.
See the `passivetracer_time(ID, model::Model)` method to retrieve tracer data by particle ID.
"""
function  passivetracer_time(model::Model, cores::Int64=1, args::String=""; wait=true)

end

"""
    PT = passivetracer_time(ID::Union{Vector{Int64},Int64}, model::Model)

This reads passive tracers with `ID` from a LaMEM simulation specified by `model`, and returns a named tuple with the temporal 
evolution of these passive tracers. We return `x`,`y`,`z` coordinates and all fields specified in `FileName` for particles number `ID`.

"""
function passivetracer_time(ID::Union{Vector{Int64},Int64}, model::Model)
    return passivetracer_time(ID, model.Output.out_file_name, model.Output.out_dir)
end

"""
    create_initialsetup(model::Model, cores::Int64=1, args::String=""; verbose=verbose)

Creates the initial model setup of LaMEM from `model`, which includes:
- Writing the LaMEM (*.dat) input file

and in case we do not employ geometric primitives to create the setup:

- Write the VTK file (if requested when `model.Output.write_VTK_setup=true`)
- Write the marker files to disk (if `model.ModelSetup.msetup="files"`)

"""
function create_initialsetup(model::Model, cores::Int64=1, args::String=""; verbose=true, add_APS=false, warn_constant_grid=true)

    # Move to the working directory
    cur_dir = pwd()
    try
        if !isempty(model.Output.out_dir)
            if !isdir(model.Output.out_dir);  mkdir(model.Output.out_dir); end # create directory if needed
            cd(model.Output.out_dir)
        end

        write_LaMEM_inputFile(model, model.Output.param_file_name; warn_constant_grid)

        # corrections for certain platforms (e.g., windows):
        model, cores = adjust_for_platforms(model, cores)

        if !isnothing(model.FreeSurface.Topography)
            save_LaMEM_topography(model.FreeSurface.Topography, model.FreeSurface.surf_topo_file)
        end

        if model.ModelSetup.msetup=="files"
            # write marker files to disk before running LaMEM
            Model3D = CartData(model.Grid.Grid, (Phases=model.Grid.Phases,Temp=model.Grid.Temp,APS=model.Grid.APS));

            if cores>1
                PartFile = run_lamem_save_grid(model.Output.param_file_name, cores)

                save_LaMEM_markers_parallel(Model3D, PartitioningFile=PartFile, verbose=verbose, add_APS=add_APS)
            else
                save_LaMEM_markers_parallel(Model3D, verbose=verbose, add_APS=add_APS)
            end
        end
    finally
        # always restore the cwd, also on error (windows cannot delete the cwd of a process)
        cd(cur_dir)
    end
    return nothing
end


"""
    model, cores =  adjust_for_platforms(model, cores::Int64)

A `LaMEM_jll` without MPI cannot run in parallel and has no MUMPS, so the model falls back to
PETSc's built-in sequential LU. Windows builds were the only such platform; they are MPI-enabled
since LaMEM_jll 3.1.0 (PETSc_jll 3.25.4), so this now adjusts nothing there.
"""
function adjust_for_platforms(model, cores::Int64)

    if !mpi_available()
        println("This LaMEM_jll has no MPI library; using a sequential direct solver")
        model.Solver.direct_solver_type = "default"  # PETSc's built-in LU (sequential); MUMPS needs MPI
        model.Solver.coarse_solver = "direct"
    end

    return model, cores
end


"""
    project_onto_crosssection(model::Model, Cross::CartData)

Reads the output of a LaMEM simulation and projects it onto a 2D cross-section `Cross`
"""
project_onto_crosssection(model::Model, Cross::CartData) = project_onto_crosssection(model.Output.out_file_name, Cross)
