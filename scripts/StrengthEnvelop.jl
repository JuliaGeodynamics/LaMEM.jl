using LaMEM, CairoMakie

model  = Model(Grid(nel=(4,32), x=[-1,1], z=[-30,1]), 
               Time(nstep_max=25, dt_min=1e-4, dt=1e-3, dt_max=10, time_end=100), 
               BoundaryConditions(exx_strain_rates=[1e-15]),
               Solver(SolverType="direct"),
               Output(out_dir="example_1"))

Z = model.Grid.Grid.Z
ind = findall( Z .<  0.0 )               
model.Grid.Phases[ind] .= 1;

Tgradient =  20;
model.Grid.Temp .= .- Z .* Tgradient;
model.Grid.Temp[model.Grid.Temp .< 0.0] .= 0.0;
model.BoundaryConditions.temp_bot = maximum(model.Grid.Temp )

air   = Phase(Name="Air",     ID=0, rho=100,  eta=1e18, G=5e10, ch=10, fr=30)
crust = Phase(Name="Crust",   ID=1, rho=3000, G=5e10, disl_prof="Dry_Upper_Crust-Schmalholz_Kaus_Burg_2009", ch=10, fr=30)
rm_phase!(model)
add_phase!(model, air, crust)

run_lamem(model,1)

data,_ = read_LaMEM_timestep(model, last=true)

#Create plot
fig1 = Figure(size=(800,800))
ax = Axis(fig1[1,1], xlabel = "τII [MPa]", ylabel = "Depth [km]",title="Geotherm=$(Tgradient)°C/km")

lines!(ax, data.fields.j2_dev_stress[1,1,:], data.z.val[1,1,:], label="t=$time")
display(fig1)
