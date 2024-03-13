# Create a 2D subduction setup with particles, but with no temperature structure

# Load package that contains LaMEM I/O routines
using GeophysicalModelGenerator, LaMEM  

pkg_dir = pkgdir(LaMEM)

# Load LaMEM particles grid
ParamFile_2 =   "input_files/Subduction2D_FreeSlip_Particles_Linear_DirectSolver.dat"
ParamFile_2 =   joinpath(pkg_dir,"test", ParamFile_2);
Grid_LaMEM  =   readLaMEM_InputFile(ParamFile_2)

# Specify slab parameters
Trench_x_location   = -500;     # trench location
Length_Subduct_Slab =  200;     # length of subducted slab
Length_Horiz_Slab   =  1500;    # length of overriding plate of slab
Width_Slab          =  750;     # Width of slab (in case we run a 3D model)         

SubductionAngle     =   34;     # Subduction angle
ThicknessCrust      =   10;     
ThicknessML         =   75;     # Thickness of mantle lithosphere
T_mantle            =   1350;   # in Celcius
T_surface           =   0;

ThicknessSlab = ThicknessCrust+ThicknessML

Phases      =   zeros(Int64, size(Grid_LaMEM.X));             # Rock numbers
Temp        =   ones(Float64,size(Grid_LaMEM.X))*T_mantle;    # Temperature in C    

# Create horizontal part of slab with crust & mantle lithosphere
addBox!(Phases,Temp,Grid_LaMEM,
        xlim=(Trench_x_location, Trench_x_location+Length_Horiz_Slab), 
        zlim=(-ThicknessSlab   , 0.0),
        phase=LithosphericPhases(Layers=[ThicknessCrust ThicknessML], Phases=[1 2 0]) );               

# Add inclined part of slab                            
addBox!(Phases,Temp,Grid_LaMEM,
        xlim=(Trench_x_location-Length_Subduct_Slab, Trench_x_location), 
        zlim=(-ThicknessSlab   , 0.0),
        DipAngle=-SubductionAngle,
        Origin=(Trench_x_location,0,0),
        phase=LithosphericPhases(Layers=[ThicknessCrust ThicknessML], Phases=[1 2 0]) );               

# Save julia setup 
Model3D     =   CartData(Grid_LaMEM, (Phases=Phases,Temp=Temp))   # Create LaMEM model:
write_Paraview(Model3D,"LaMEM_ModelSetup")                  # Save model to paraview   (load with opening LaMEM_ModelSetup.vts in paraview)  

# Save LaMEM markers
dir =   joinpath(pkg_dir,"test","input_files");
cur_dir = pwd()
cd(dir)

if !isdir(dir);  mkdir(dir); end # create directory if needed
cd(dir)



@show pwd(), dir
save_LaMEMMarkersParallel(Model3D)                          # Create LaMEM marker input on 1 core
cd(cur_dir)