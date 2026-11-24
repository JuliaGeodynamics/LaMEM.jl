# Model setup to simulate Etna in 3D, extended to make a 2D cross-section though the model
using GeophysicalModelGenerator, GMT, LaMEM, Interpolations
using Statistics
using Printf
using Base.Threads: @threads
include("generate_per_core_marker_files_utils.jl")
using .generate_per_core_marker_files_utils

function create_geometry!(Phases, Temp, Grid, Topo_model)

    X = Grid.X;
    Y = Grid.Y;
    Z = Grid.Z;
    ind = findall(Z .< 0.0)
    Phases[ind] .= 1
    
    Below = below_surface(Grid, Topo_model);
    Phases[Below] .= 2
    
    Phases[Z .< -20] .= 3    

    # Determine the distance to the surface, to set altered crust
    x_vec        = Topo_model.x.val[:, 1, 1]
    y_vec        = Topo_model.y.val[1, :, 1]
    interpol     = linear_interpolation((x_vec, y_vec), ustrip.(Topo_model.z.val[:, :, 1]))             # create interpolation object
    DepthSurface = interpol.(X, Y)
    DistanceSurf = Z - DepthSurface
    
    # Set phase to 4 when we are below the surface
    ind = findall(DistanceSurf.>-2.5 .&& DistanceSurf.<0.0)
    Phases[ind] .= 3

    Geotherm=30
    Temp .= -Z.*Geotherm;

    #cut off extreme values
    Temp[Temp.<20]    .=  20;
    Temp[Temp.>1350]  .=  1350;

    # return nothing
end

function get_topo_files(nx,ny,curdir,Generate_topo_files)

    if Generate_topo_files == 1
        # First time, you need to load topo:
        # Topo = import_topo([14.8,15.5,37.5,37.8], file="@earth_relief_01s")
        Topo          = import_topo([14.75,15.45,37.43,37.96], file="@earth_relief_01s")
        EGMS_velocity = load_GMG(joinpath(curdir,"data_EGMS_Etna_2019_2023"))       # INSAR data (to compare)

        proj      = ProjectionPoint(Lon=15.15, Lat=37.65)
        Topo_cart = convert2CartData(Topo, proj)
        EGMS_cart = convert2CartData(EGMS_velocity, proj)
        
        bounds   = [ minimum(Topo_cart.x.val),maximum(Topo_cart.x.val), minimum(Topo_cart.y.val),maximum(Topo_cart.y.val) ]
        x_coords = range(bounds[1],bounds[2],length=nx)
        y_coords = range(bounds[3],bounds[4],length=ny)
        Empty_cart_data = CartData(xyz_grid(x_coords,y_coords,0))

        Topo_model = project_CartData(Empty_cart_data, Topo, proj)
        EGMS_model = project_CartData(Empty_cart_data, EGMS_velocity, proj)
        
        
        save_GMG("Topo_model", Topo_model)
        save_GMG("EGMS_model", EGMS_model)

    else

        Topo_model = load_GMG(joinpath(curdir,"Topo_model")) # Topography data from disk
        EGMS_model = load_GMG(joinpath(curdir,"EGMS_model")) # EGMS data from disk

    end

    # write_paraview(Topo_model,"Topo_cart")
    # write_paraview(EGMS_model,"Topo_cart_EGMS")
    # Topo = drape_on_topo(Topo_model, EGMS_model)      # Drape the INSAR data on the topography

    return Topo_model,EGMS_model

end

function initialize_model( nx,ny,curdir,Generate_topo_files,ParamFile_name, n_ranks, Paraview_model_preview, directory )

    Topo_model, EGMS_model = get_topo_files(nx,ny,curdir,Generate_topo_files)

    check_markers_directory(joinpath(curdir ,directory))

    # Parse data from LaMEM input file
    Grid_info = get_LaMEM_grid_info(ParamFile_name)
    # Get domain partitioning info
    P         = setup_model_domain(Grid_info.coord_x, Grid_info.coord_y, Grid_info.coord_z, nx, ny, nz, n_ranks)

    p_dist    = get_particles_distribution(Grid_info,P)

    if Paraview_model_preview == 1

        # Preallocate to save for Paraview
        Tempnew  = zeros(Float64, Grid_info.nump_x, Grid_info.nump_y, Grid_info.nump_z)
        Phasenew = zeros(UInt8, Grid_info.nump_x, Grid_info.nump_y, Grid_info.nump_z)
        MPI_Rank = zeros(Int64, Grid_info.nump_x, Grid_info.nump_y, Grid_info.nump_z)

        return Grid_info, P, p_dist, Topo_model, EGMS_model, Tempnew, Phasenew, MPI_Rank

    end

    return Grid_info, P, p_dist, Topo_model, EGMS_model
    
end

function generate_setup_file(curdir,ParamFile_name)
    model = Model( 
                    Grid(               x               = [extrema(Grid_info.coord_x)...],
                                        y               = [extrema(Grid_info.coord_y)...],
                                        z               = [extrema(Grid_info.coord_z)...],
                                        nel             = (nx,ny,nz)   ), 
                    
                    BoundaryConditions( temp_bot        = 20.0,                     # we set temperature, but it is not used in this model
                                        temp_top        = 20.0,
                                        open_top_bound  = 1,                        # we do not want a freesurface, yet!
                                        noslip          = [0, 0, 0, 0, 0, 0]),      # [left, right, front, back, bottom, top]

                    # set timestepping parameters
                    Time(               time_end        = 10.0,                     # Time is always expressed in Myrs (input/output definition)
                                        dt              = 0.00001,                  # Target timestep, here 10k years
                                        dt_min          = 0.00000001,               # Minimum dt allowed, this is useful for more complex simulations
                                        dt_max          = 0.001,                    # max dt, here 1k years
                                        nstep_max       = 10,                       # Number of wanted timesteps
                                        nstep_out       = 5 ),                      # save output every nstep_out

                    # set solution parameters
                    SolutionParams(     eta_min         = 1e17,
                                        eta_ref         = 1e20,
                                        eta_max         = 1e23),
                    ModelSetup(
                                        msetup           =  "files",
                                        rand_noise       =  1,
                                        bg_phase         =  0,
                                        advect           =  "basic",
                                        interp           =  "stag",
                                        mark_ctrl        =  "subgrid",
                                        nmark_sub        =  2 ),

                # what will be saved in the output of the simulation

                Output(             out_file_name       = "etna_flank",
                                    param_file_name     = ParamFile_name,
                                    write_VTK_setup     = false,
                                    out_dir             = out_dir,
                                    out_tot_displ       = 1,
                                    out_surf            = 1, 	
                                    out_surf_pvd        = 1,
                                    out_surf_topography = 1,
                                    out_surf_velocity   = 1,
                                    out_moment_res      = 1,
                                    out_cont_res        = 1,
                                    out_temperature     = 1,
                                    out_yield           = 1 ),) 

    #set air and water properties
    air = set_air(alpha=3e-5, G=3e10, nu=0.2, 
                    #ch=10e6, 
                    #fr=30
                    )
    #air.eta_vp = 1e21
    water=copy_phase(air, rho=1000.0, Name="water", ID=1 );

    crust      = Phase(Name="Elastic Crust", 
                    ID=2, rho=2900, 
                    alpha=3e-5, 
                    eta = 1e23,
                    #disl_prof="Mafic_Granulite-Ranalli_1995",
                    G=3e10, 
                    nu=0.2, 
                    k=3, 
                    Cp=1000, 
                    )

    crust_alt  = copy_phase(crust  , ID=3, Name="AlteredCrust")

    # to be activated with a phase transition                
    ϕ        = 0.0;
    cohesion = 3e6
    ηvp      = 1e18

    air_plastic          = copy_phase(air  ,     ID=4, Name="AirPlastic",            fr=ϕ,       ch=cohesion,    eta_vp=ηvp)
    water_plastic        = copy_phase(water,     ID=5, Name="WaterPlastic",          fr=ϕ,       ch=cohesion,    eta_vp=ηvp)
    water                = copy_phase(water_plastic, ID=1)
    air                  = copy_phase(air_plastic, ID=0)

    crust_plastic        = copy_phase(crust,     ID=6, Name="CrustPlastic",          fr=30.0,    ch=400e6,       eta_vp=ηvp)
    #crust_plastic       = copy_phase(crust,     ID=6, Name="CrustPlastic",          fr=ϕ,    ch=cohesion,       eta_vp=ηvp)
    crust_alt_plastic    = copy_phase(crust_alt, ID=7, Name="CrustAlteredPlastic",   fr=ϕ,       ch=cohesion,     eta_vp=ηvp)

    rm_phase!(model)
    add_phase!(model, air, water, crust, crust_alt, air_plastic, water_plastic, crust_plastic,  crust_alt_plastic)

    # add phase transitions to activate plasticity after an initial stress state was established (after a certain time)
    phase_transition_crust           = PhaseTransition(ID=0, 
                                                Type="Constant", 
                                                Parameter_transition="t", 
                                                ConstantValue = 4e-5,                # in Myrs
                                                PhaseBelow=[0; 1; 2; 3], 
                                                PhaseAbove=[4; 5; 6; 7], 
                                                number_phases=4, 
                                                PhaseDirection="BelowToAbove")
    model.Materials.PhaseTransitions = [phase_transition_crust]

    write_LaMEM_inputFile(model, joinpath(curdir,model.Output.param_file_name))

    return model

end

curdir="/local/home/iskander/projects/CHEESE2/etna_model/setups"
out_dir = ""
cd(curdir)

ParamFile_name = "Etna_setup_2.dat"

Paraview_model_preview  = 0;          # Generate vtr file to preview model after marker generation. Turn off for bigger models
Generate_topo_files     = 0;          # Generate jld files for topography and velocity model
n_ranks                 = 64;         # Number of processors
RandomNoise             = false ;     # add random noise to particles, does not work
verbose                 = true;       # print info
num_prop                = 5;          # Number of properties, do not change
directory               = "markers" # do not change

# Resolution
nx = 128
ny = nx
nz = div(nx, 4)

# Generate setup file
model = generate_setup_file(curdir, ParamFile_name)

Grid_info, P, p_dist, Topo_model, EGMS_model = initialize_model( nx,ny,curdir,Generate_topo_files,ParamFile_name, n_ranks, Paraview_model_preview, directory )
# Grid_info, P, p_dist, Topo_model, EGMS_model, Tempnew, Phasenew, MPI_Rank = initialize_model( nx,ny,curdir,Generate_topo_files,ParamFile_name, n_ranks, Paraview_model_preview, directory )

Nproc     = P.nProcX*P.nProcY*P.nProcZ

# Get the global coordinates of the grid
x_global = Grid_info.coord_x;
y_global = Grid_info.coord_y;
z_global = Grid_info.coord_z;

# Loop over all processors partition
# proc_num=1
@threads for proc_num in 1:Nproc
# for proc_num in 1:Nproc

    # % Generate grid for current processor
    proc_bounds = get_proc_bound(Grid_info,p_dist,proc_num)
    Grid        = get_proc_grid(Grid_info,p_dist,proc_bounds,proc_num,RandomNoise)

    Phase       = zeros(UInt8, size(Grid.X))
    Temp        = zeros(size(Phase))

    create_geometry!(Phase, Temp, Grid, Topo_model)
    
    if Paraview_model_preview == 1
        # % Save whole model for paraview output (optional)
        Tempnew[p_dist.x_start[proc_num]:p_dist.x_end[proc_num],p_dist.y_start[proc_num]:p_dist.y_end[proc_num],p_dist.z_start[proc_num]:p_dist.z_end[proc_num]].=Temp;
        Phasenew[p_dist.x_start[proc_num]:p_dist.x_end[proc_num],p_dist.y_start[proc_num]:p_dist.y_end[proc_num],p_dist.z_start[proc_num]:p_dist.z_end[proc_num]].=Phase;
        MPI_Rank[p_dist.x_start[proc_num]:p_dist.x_end[proc_num],p_dist.y_start[proc_num]:p_dist.y_end[proc_num],p_dist.z_start[proc_num]:p_dist.z_end[proc_num]].=proc_num;
    end

    num_particles = size(Grid.X,1)* size(Grid.Y,2) * size(Grid.Z,3);
    lvec_info = num_particles;
    lvec_prtcls = zeros(Float64, num_prop * num_particles);

    lvec_prtcls[1:num_prop:end] = Grid.X[:];
    lvec_prtcls[2:num_prop:end] = Grid.Y[:];
    lvec_prtcls[3:num_prop:end] = Grid.Z[:];
    lvec_prtcls[4:num_prop:end] = Phase[:];
    lvec_prtcls[5:num_prop:end] = Temp[:];

    fname = @sprintf "%s/mdb.%1.8d.dat"  joinpath(curdir,directory) (proc_num - 1)    # Name

    if verbose
        println("Writing LaMEM marker file -> $fname")                   # print info
    end
    lvec_output = [lvec_info; lvec_prtcls];           # one vec with info about length

    GeophysicalModelGenerator.PetscBinaryWrite_Vec(fname, lvec_output)            # Write PETSc vector as binary file

end


if Paraview_model_preview == 1
    # % Make structure for paraview
    println("Writing Paraview data")
    Grid_glob = read_LaMEM_inputfile(ParamFile_name)
    Model3D_paraview_data = ParaviewData(Grid_glob, (Phases=Phasenew,Temp=Tempnew,MPI_Rank=MPI_Rank));
    name_paraview_file="Etna_setup_model" * string(nx) * "_" * string(ny) * "_" * string(nz)
    write_paraview(Model3D_paraview_data, name_paraview_file)  # Save model to Paraview
end

#= Some previous version routines
# PartitioningFile = run_lamem_save_grid(ParamFile_name, n_ranks; verbose=true );
# PartitioningFile ="ProcessorPartitioning_64cpu_8.4.2.bin"
# P         = get_processor_partitioning_info(PartitioningFile)
=#


#= TEST WITH GLOBAL AGAIN
particles_cell = 3;
bounds=[minimum(Topo_model.x.val),maximum(Topo_model.x.val), minimum(Topo_model.y.val),maximum(Topo_model.y.val)]
x_coords=range(bounds[1],bounds[2],length=nx*particles_cell)
y_coords=range(bounds[3],bounds[4],length=ny*particles_cell)
Grid_3D = CartData(xyz_grid(x_coords,y_coords,range(-6.4,6.4,length=nz*particles_cell))) # 256x256x64 model is 3456 MB
Phase       = zeros(UInt8, size(Grid_3D.x))
Temp        = zeros(size(Phase))
create_geometry!(Phase, Temp, Grid_3D, Topo_model)
Grid_glob = read_LaMEM_inputfile(ParamFile_name)
Model3D_paraview_data = ParaviewData(Grid_glob, (Phases=Phase,Temp=Temp,MPI_Rank=MPI_Rank));
write_paraview(Model3D_paraview_data, "Etna_setup_model_test_glob")  # Save model to Paraview
=#


#=
ParamFile="Etna_setup_1.dat"
lamem_exe=" /local/home/iskander/software/LAMEM/lamem_cuda/lamem_petsc_gitmain/LaMEM/bin/opt/LaMEM "
sruncommand="  /local/home/iskander/software/petsc_3_22_cuda/petsc/petsc_3_22_cuda/bin/mpiexec -n 32768 --map-by :OVERSUBSCRIBE " #--map-by :OVERSUBSCRIBE  --mca orte_base_help_aggregate 0
lamem_exe=" /local/home/iskander/software/LAMEM/lamem_petsc_gitmain/LaMEM/bin/opt/LaMEM "
$sruncommand $lamem_exe -ParamFile Etna_setup_1.dat -mode save_grid

sruncommand="  /local/home/iskander/software/petsc_3_22_cuda/petsc/petsc_3_22_cuda/bin/mpiexec "
ParamFile=" /local/home/iskander/projects/CHEESE2/etna_model/setups/Etna_setup_1.dat "
lamem_exe=" /local/home/iskander/software/LAMEM/lamem_petsc_gitmain/LaMEM/bin/opt/LaMEM "
nc=64
mglevels=3
petsc_options=" \
-snes_max_it 50 \
-snes_type newtonls \
-js_ksp_type fgmres \
-js_ksp_max_it 1000 \
-js_ksp_rtol 1e-6 \
-snes_ksp_ew \
-snes_ksp_ew_version 3 \
-snes_ksp_ew_rtol0   1e-2 \
-snes_ksp_ew_rtolmax 1e-2 \
-snes_ksp_ew_gamma   0.9 \
-snes_ksp_ew_alpha   2.0 \
-snes_rtol 1e-3	\
-snes_atol 1e-3	\
-snes_PicardSwitchToNewton_rtol 1e-3 \
-snes_NewtonSwitchToPicard_it 10 \
-snes_linesearch_type l2 \
-snes_linesearch_max_it 5 \
-snes_linesearch_minlambda 0.05 \
-snes_linesearch_maxstep 1.0 \
-pcmat_type mono \
-matmatmatmult_via scalable \
-pc_view  "

multigrid_options=" \
-jp_type mg \
-gmg_pc_type mg \
-gmg_pc_mg_log \
-gmg_pc_mg_galerkin \
-gmg_pc_mg_type multiplicative \
-gmg_pc_mg_cycle_type v \
-gmg_mg_levels_ksp_type fgmres \
-gmg_mg_levels_ksp_max_it 10 \
-gmg_mg_levels_pc_type bjacobi \
-gmg_mg_coarse_ksp_type preonly \
-gmg_mg_coarse_ksp_type fgmres \
-gmg_mg_coarse_ksp_max_it 240 \
-gmg_mg_coarse_pc_type bjacobi "

$sruncommand -n $nc --map-by :OVERSUBSCRIBE $lamem_exe -ParamFile $ParamFile ${resolution_options} ${petsc_options} ${multigrid_options} -gmg_pc_mg_levels ${mglevels} ${petsc_view} \

=#

