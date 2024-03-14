# Contains a number of useful functions
import LaMEM.IO_functions: Read_LaMEM_simulation, Read_LaMEM_timestep

export  add_phase!, rm_phase!, rm_last_phase!, replace_phase!,
        add_vbox!, rm_last_vbox!, rm_vbox!,
        add_softening!, add_phasetransition!, add_phaseaggregate!,
        add_dike!, add_geom!, rm_geom!, cross_section,
        set_air, copy_phase,
        isdefault, hasplasticity,
        stress_strainrate_0D



"""
add_vbox!(model::Model, vbox::VelocityBox)
This adds a `vbox` (with its properties) to `model`
"""
function add_vbox!(model::Model, vbox::VelocityBox) 
    push!(model.BoundaryConditions.VelocityBoxes, vbox);
    return nothing
end

"""
    add_vbox!(model::Model, vboxes...)
Add several phases @ once.
"""
function add_vbox!(model::Model, vboxes...) 
    for vbox in vboxes
        push!(model.BoundaryConditions.VelocityBoxes, vbox);
    end
end


"""
rm_last_vbox!(model::Model)
This removes the last added `vbox` from `model`
"""
function rm_last_vbox!(model::Model) 
    if length(model.BoundaryConditions.VelocityBoxes)>0
        model.BoundaryConditions.VelocityBoxes = model.BoundaryConditions.VelocityBoxes[1:end-1]
    end
    return nothing
end

"""
    rm_vbox!(model::Model)
This removes all existing velocity boxes from `model`
"""
function rm_vbox!(model::Model) 
    model.BoundaryConditions.VelocityBoxes = []
    return nothing
end

"""
    add_phase!(model::Model, phase::Phase)
This adds a `phase` (with material properties) to `model`
"""
function add_phase!(model::Model, phase::Phase) 
    phase_added = add_geoparams_rheologies(phase)
    push!(model.Materials.Phases, phase_added);
    return nothing
end

"""
    add_phase!(model::Model, phases...) 
Add several phases @ once.
"""
function add_phase!(model::Model, phases...) 
    for phase in phases
        phase_added = add_geoparams_rheologies(phase)
        push!(model.Materials.Phases, phase_added);
    end
end


"""
    rm_last_phase!(model::Model, phase::Phase)
This removes the last added `phase` from `model`
"""
function rm_last_phase!(model::Model) 
    if length(model.Materials.Phases)>0
        model.Materials.Phases= model.Materials.Phases[1:end-1]
    end
    return nothing
end

"""
    rm_phase!(model::Model, ID::Int64)
This removes a phase with `ID` from `model`
"""
function rm_phase!(model::Model, ID::Int64) 
    id_vec = [phase.ID for phase in model.Materials.Phases]
    id = findall(id_vec .== ID)
    deleteat!(model.Materials.Phases,id)
    return nothing
end

"""
    rm_phase!(model::Model)
This removes all existing phases from `model`
"""
function rm_phase!(model::Model) 
    model.Materials.Phases = []
    return nothing
end

"""
    replace_phase!(model::Model, phase_new::Phase; ID::Int64=nothing, Name::String=nothing)

This replaces a `phase` within a LaMEM Model Setup `model` with `phase_new` either based on its `Name` or `ID`. 
Note that it is expected that only one such phase is present in the current setup.
"""
function replace_phase!(model::Model, phase_new::Phase; ID::Union{Nothing,Int64}=nothing, Name::Union{Nothing,String}=nothing) 
    id_vec   = [phase.ID for phase in model.Materials.Phases]
    name_vec = [phase.Name for phase in model.Materials.Phases]
    if !isnothing(ID)
        id = findfirst(id_vec .== ID)
    elseif !isnothing(Name)
        id = findfirst(name_vec .== Name)
    end
    model.Materials.Phases[id] = phase_new

    return nothing
end


"""
    add_petsc!(model::Model, option::String) 

Adds one or more PETSc options to the model 

Example
===
```julia
julia> d = Model()
julia> add_petsc!(d,"-snes_npicard 3")
```

"""
function add_petsc!(model::Model, args...) 
    for arg in args
        push!(model.Solver.PETSc_options , arg);
    end
    return nothing
end


function add_softening!(model::Model, args...) 
    for arg in args
        push!(model.Solver.PETSc_options , arg);
    end
    return nothing
end

"""
    add_softening!(model::Model, soft::Softening)
This adds a plastic softening law `soft` to `model`
"""
function add_softening!(model::Model, soft::Softening) 
    push!(model.Materials.SofteningLaws, soft);
    return nothing
end

"""
    add_phaseaggregate!(model::Model, phaseagg::PhaseAggregate)
This adds a phase aggregate law `phaseagg` to `model`
"""
function add_phaseaggregate!(model::Model, phaseagg::PhaseAggregate) 
    push!(model.Materials.PhaseAggregates, phaseagg);
    return nothing
end

"""
    add_phasetransition!(model::Model, phase_trans::PhaseTransition)
This adds a phase transition `phase_trans` to `model`
"""
function add_phasetransition!(model::Model, phase_trans::PhaseTransition) 
    push!(model.Materials.PhaseTransitions, phase_trans);
    return nothing
end

"""
    add_dike!(model::Model, dike::Dike)
This adds a phase transition `phase_trans` to `model`
"""
function add_dike!(model::Model, dike::Dike)
    push!(model.Materials.Dikes, dike);
    return nothing
end


"""
    add_geom!(model::Model, geom_object)
This adds an internal geometric primitive object `geom_object` to the LaMEM Model Setup `model`.

Currently available primitive geom objects are:
- `geom_Sphere`
- `geom_Ellipsoid`
- `geom_Box`
- `geom_Layer`
- `geom_Cylinder`
- `geom_RidgeSeg`
- `geom_Hex`

"""
function add_geom!(model::Model, geom_object)
    push!(model.ModelSetup.geom_primitives, geom_object);
    model.ModelSetup.msetup = "geom";
    
    #set_geom!(model, geom_object)

    return nothing
end


"""
    add_geom!(model::Model, geom_object)
Add several geometric objects @ once.
"""
function add_geom!(model::Model, geom_objects...) 
    for geom_object in geom_objects
        add_geom!(model, geom_object)
    end
end

"""
    rm_geom!(model::Model)
This removes all existing geometric objects from `model`
"""
function rm_geom!(model::Model) 
    model.ModelSetup.geom_primitives = []
    return nothing
end

"""

This sets the geometry 
"""
function set_geom!(model::Model, d::geom_Sphere)
   
    cen = (d.center...,)
    radius = d.radius
    phase  =  ConstantPhase(d.phase)
    T = d.Temperature
    if !isnothing(T)
        T=ConstantTemp(T)
    end

    # call a GMG routine
    add_sphere!(model.Grid.Phases,model.Grid.Temp,model.Grid.Grid, cen=cen, radius=radius, phase=phase, T=T)

    return nothing
end


"""
    Timestep, FileNames, Time = Read_LaMEM_simulation(model::Model; phase=false, surf=false, passive_tracers=false)

Reads a LaMEM simulation as specified in `model` and returns the timesteps, times and filenames of that simulation once it is finished.
"""
Read_LaMEM_simulation(model::Model; kwargs...) = Read_LaMEM_simulation(model.Output.out_file_name,model.Output.out_dir; kwargs...)

"""
    data, time = Read_LaMEM_timestep(model::Model, TimeStep::Int64=0; fields=nothing, phase=false, surf=false, last=true)

Reads a specific `Timestep` from a simulation specified in `model`
"""
function Read_LaMEM_timestep(model::Model, TimeStep::Int64=0; kwargs...) 
    FileName    = model.Output.out_file_name

    cur_dir = pwd(); 
    if !isempty(model.Output.out_dir)
        cd(model.Output.out_dir)
    end

    data, time = Read_LaMEM_timestep(FileName,TimeStep; kwargs...)
    
    cd(cur_dir)

    return data, time
end



"""
    data_tuple, axes_str = cross_section(model::LaMEM.Model, field=:phases; x=nothing, y=nothing, z=nothing)

This creates a cross-section through the initial model setup & returns a 2D array
"""
function cross_section(model::Model, field::Symbol=:phase; x=nothing, y=nothing, z=nothing)
    Model3D = CartData(model.Grid.Grid, (phase=model.Grid.Phases,temperature=model.Grid.Temp));
    
    data_tuple, axes_str = cross_section(Model3D, field; x=x, y=y, z=z)
    
    return data_tuple, axes_str
end

"""
    Cross = cross_section(cart::CartData, field::Symbol =:phase; x=nothing, y=nothing, z=nothing)

Creates a cross-section through the data and returns `x,z` coordinates
"""
function cross_section(cart::CartData, field::Symbol=:phase; x=nothing, y=nothing, z=nothing)
    
    if !isnothing(z); Depth_level = z*km; else Depth_level=nothing; end
    if !isnothing(x); Lon_level = x; else Lon_level=nothing; end
    if !isnothing(y); Lat_level = y; else Lat_level=nothing; end
    
    Cross = CrossSectionVolume(cart, Depth_level=Depth_level, Lat_level=Lat_level, Lon_level=Lon_level)

    data_tuple, axes_str = flatten(Cross, field,x,y,z)
    return data_tuple, axes_str
end

"""
Creates a 2D array out of a cross-section and a specified data field
"""
function flatten(cross::CartData, field::Symbol,x,y,z)
    dim     =   findall(size(cross.x.val) .== 1)[1]
    X       =   dropdims(cross.x.val, dims=dim)
    Y       =   dropdims(cross.y.val, dims=dim)
    Z       =   dropdims(cross.z.val, dims=dim)
    data_or =   getfield(cross.fields,field)

    # flatten data array
    if isa(data_or, Array)
        data = dropdims(data_or, dims=dim)
    elseif isa(data_or,Tuple)
        # vectors or tensors
        data = ()
        for d in data_or
            data = (data..., dropdims(d, dims=dim) )
        end
    end

    if  dim==1
        title_str = "x = $x"
        x_str,z_str = "y","z"
        x, z = Y[:,1],  Z[1,:]
    elseif  dim==2
        title_str = "y = $y"
        x_str,z_str = "x","z"
        x, z = X[:,1],  Z[1,:]
    elseif dim==3
        title_str = "z = $z"
        x_str,z_str = "x","y"
        x, z = X[:,1],  Y[1,:]
    end
    axes_str = (x_str=x_str, z_str=z_str, title_str=title_str)
    data_tuple = (x=x,z=z,data=data)
    return data_tuple, axes_str
end

    
"""
    set_air(; Name="air", ID=0, rho=1, alpha=nothing, eta=1e17, G=nothing, nu=nothing, fr=nothing, ch=nothing, k=30,Cp=1000)
Sets an air phase, with high conductivity 
"""
function set_air(; Name="air", ID=0, rho=1, alpha=nothing, eta=1e17, G=nothing, nu=nothing, fr=nothing, ch=nothing,
                k=30,Cp=1000)
    return Phase(Name=Name, ID=ID, rho=100, alpha=alpha, eta=eta, G=G, nu=nu, k=k, Cp=Cp, fr=fr, ch=ch)
end


"""
    copy_phase(phase::Phase; kwargs...)

This copies a phase with material properties, while allowing to change some parameters
"""
function copy_phase(phase::Phase; kwargs...)
    phase_new = deepcopy(phase)
    # update fields
    for ph in keys(kwargs)
        setfield!(phase_new,ph, kwargs[ph])
    end

    return phase_new
end


"""
    add_topography!(model::Model, topography::CartData; surf_air_phase=0, surf_topo_file="topography.txt", open_top_bound=1,  surf_level=0.0)

Adds the topography surface to the model
"""
function add_topography!(model::Model, topography::CartData; surf_air_phase=0, surf_topo_file="topography.txt", 
            open_top_bound=1, surf_level=0.0)
    if !is_rectilinear(topography)
        error("topography grid must be rectilinear")
    end
    if !within_bounds(model, topography)
        error("topography grid must be larger than the model")
    end

    model.FreeSurface.Topography = topography # add topo
    model.FreeSurface.surf_use = 1
    model.FreeSurface.surf_air_phase = surf_air_phase
    model.FreeSurface.surf_level = surf_level
    if isempty(model.FreeSurface.surf_topo_file)
        model.FreeSurface.surf_topo_file = surf_topo_file
    end

    # usually we want an open top boundary when we have a free surface:
    model.BoundaryConditions.open_top_bound=open_top_bound

    return nothing
end


"""
    isdefault(s1::S, s_default::S) 

Checks whether a struct `s1` has default parameters `s_default`
"""
function isdefault(s1, s_default)

    default = true
    for f in fieldnames(typeof(s1))
        if getfield(s1,f) !=   getfield(s_default,f)
            default = false
        end
    end

    return default
end

"""
    hasplasticity(p::Phase)

`true` if `p` contains plastic parameters (cohesion or friction angle)
"""
function hasplasticity(p::Phase)
    plastic = false
    if !isnothing(p.ch) || !isnothing(p.fr)
        plastic = true
    end
    return plastic
end



"""
    τ = stress_strainrate_0D(rheology, ε_vec::Vector; n=8, T=700, nstep_max=2, clean=true)

Computes the stress for a given strain rate and 0D rheology setup, for viscous creep rheologies. 
    `n` is the resolution in `x,z`, `T` the temperature, `nstep_max` the number of time steps, `ε_vec`
    the strainrate vector (in 1/s). 

"""
function stress_strainrate_0D(rheology, ε_vec::Vector; n=8, T=700, nstep_max=2, clean=true)

    # Main model setup
    model  = Model( Grid(nel=(n, n), x=[-1,1], z=[-1,1]),
                    Time(nstep_max=nstep_max, dt=1e-6, dt_max=1, dt_min=1e-10, time_end=100), 
                    BoundaryConditions(exx_strain_rates=[1e-15] ),   
                    Output(out_dir="0D_1"))

    rm_phase!(model)
    add_phase!(model, rheology)
    model.Grid.Temp.=T;
                
    τ = zero(ε_vec)
    for (i,ε) in enumerate(ε_vec)
        # run the simulation on 1 core
        model.Output.out_dir="0D_$i"
        model.BoundaryConditions.exx_strain_rates = [ε]
        run_lamem(model, 1); #run
        data,_ = Read_LaMEM_timestep(model, last=true) # read
        
        @show extrema(data.fields.j2_dev_stress)

        τ[i] = Float64.(sum(extrema(data.fields.j2_dev_stress))/2) # in MPa

        if clean
            rm("0D_$i",recursive=true)
        end
    end
   
    return τ
end
