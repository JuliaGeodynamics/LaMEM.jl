# this tests a julia setup that employs phase transitions
#
# We generate a "fake" setup with linear thermal gradiesnt 

using LaMEM, Test

model  = Model(Grid(nel=(16,1,16), x=[-100,100], y=[-1,1], z=[-100,0]),
               Time( nstep_max=4),
               Output(out_pressure=1, out_temperature=1, out_j2_dev_stress=1, out_file_name="test_phase_transitions", out_fluid_density=1, out_melt_fraction=1),
               SolutionParams(act_p_shift=1, mfmax=1.0) )

# Add thermal structure               
Z=model.Grid.Grid.Z;
γ = 10                  # geothermal gradient
model.Grid.Temp = -γ*Z;

model.BoundaryConditions.temp_bot = maximum(model.Grid.Temp)

# add heterogeneity
ind = findall(Z.<=-50 .&& Z.>=-60 .&& abs.(model.Grid.Grid.X).<10)
model.Grid.Temp[ind] .+= 2


pkg_dir = pkgdir(LaMEM)

pd_path = joinpath(pkg_dir,"test","input_files","Rhyolite")

matrix = Phase(ID=0,Name="matrix",eta=1e23,rho_ph=pd_path);
heter  = Phase(ID=1,Name="heter", eta=1e23,rho_ph=pd_path)
rm_phase!(model)    
add_phase!(model, heter, matrix)

# run
run_lamem(model)


# read back last timestep
data,time = Read_LaMEM_timestep(model,last=true);

ρ_num  =  data.fields.density[1,1,:];
ϕ_num  =  data.fields.melt_fraction[1,1,:];
ρf_num =  data.fields.fluid_density[1,1,:];
z_num =   data.z.val[1,1,:]
T_num =   data.fields.temperature[1,1,:]
P_num =   data.fields.pressure[1,1,:]


ParamFile = "Rhyolite.in";

pkg_dir = pkgdir(LaMEM)
PD = read_phase_diagram(joinpath(pkg_dir,"test","input_files",ParamFile));

@test sum(ϕ_num) ≈ 2.5262098f0

#=
intp = linear_interpolation((PD.T_K[:,1], PD.P_bar[1,:]), PD.ϕ, extrapolation_bc=Flat())

ϕ_PD  = zero(T_num)
for i in 1:length(T_num)
    ϕ_PD[i] = intp(T_num[i] .+ 273.15, P_num[i]*1e6/1e5)
end
=#
