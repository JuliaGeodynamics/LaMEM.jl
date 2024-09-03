# This is a .jl version of the PassiveTracers example. 
# We use this .jl file to run the test but you can also run it independently.
# The ipynb file of this code with additional notes for initiating tracers and extracting their information is located in the same directory: "PassiveTracers.ipynb".

using LaMEM, GeophysicalModelGenerator, Plots

model  = Model(Grid(nel=(16,16,16), x=[-1,1], y=[-1,1], z=[-1,1]), PassiveTracers(Passive_Tracer=1, PassiveTracer_Box=[-1,1,-1,1,-1,1]))
matrix = Phase(ID=0,Name="matrix",eta=1e20,rho=3000)
sphere = Phase(ID=1,Name="sphere",eta=1e23,rho=3200)
add_phase!(model, sphere, matrix)
add_sphere!(model,cen=(0.0,0.0,0.0), radius=(0.5,))

run_lamem(model,1)