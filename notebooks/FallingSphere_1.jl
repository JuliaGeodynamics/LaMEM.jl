### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ f744857e-20e6-11ee-1720-311279133704
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add(Pkg.PackageSpec(name="LaMEM", rev="bk-julia-model-setup"))
    using LaMEM, GeophysicalModelGenerator, Plots, PlutoUI
end

# ╔═╡ 78136b07-5d33-407a-afcf-e0a656181043
md"""
# Falling Sphere example using LaMEM

This is a first example that illustrates how to build a setup using the LaMEM.jl package, run it and visualize the results, all within a Pluto Notebook.

### Load packages
We start with loading a few packages.
"""

# ╔═╡ 03abfcd4-b3bb-44eb-ba97-c03d64126195
md"""
### Define model setup

Next, we define a general model setup, in which we specify the units with which we work (for most cases, you'll want to use the default `GEO` units), the size of the computational box and various timestepping parameters. In this case, we use a multigrid solver.
"""

# ╔═╡ 4a533c45-2ad6-4970-963b-abbbc798275b
  model  = Model(Grid(nel=(16,16,16), x=[-1,1], y=[-1,1], z=[-1,1]), 
  				 Time(nstep_max=20, dt_min=1e-3, dt=1, dt_max=10, time_end=100), 
                 Solver(SolverType="multigrid", MGLevels=2),
  				 Output(out_dir="example_1"))

# ╔═╡ b192e665-20f2-4f65-ace9-fe7fffd7b7c7
md"""
Note that each of the fields within `Model` has many additional and adjustable parameters. You can view that by typing `Model.Time`: 
"""

# ╔═╡ 965f3210-d4da-4a0b-8db5-cce85779fd58
model.Time

# ╔═╡ e85b89ee-7452-45dc-8484-1e2497cf3f7a
md"""
### Specify materials
Once this is specified, we need to set material properties for each of the `Phases` we will consider in the simulation. This can be done with the `Phase` structure. If you want to know which options are available, you can use the `Live Docs` within Pluto (right hand collumn) to get more info about `Phase`.
"""

# ╔═╡ bd63ef7e-af77-44d8-8127-456f7f6d38a6
md""" 
In this simulation, we will consider two materials, the matrix and a sphere with higher density. Since pluto is reactive (implying that all cells are updated once one changes), we start with removing any previously defined phases from the setup:
"""

# ╔═╡ be5335db-5535-49c6-95d2-49e53d644523
rm_phase!(model)

# ╔═╡ 6b59fe59-0d0f-4984-8464-c76c18bc8f19
md"""
Next, specify the matrix:
"""

# ╔═╡ 87dbe840-1d59-4608-a73b-d4dee2bd2c7a
matrix = Phase(ID=0,Name="matrix",eta=1e20,rho=3000)

# ╔═╡ 0c1c92d8-9846-4e31-9112-6c2b57e7a069
sphere = Phase(ID=1,Name="sphere",eta=1e23,rho=3200)

# ╔═╡ 78c4db3c-3f5d-4a91-9ab9-bd00ce0810af
md"""
And add them to the model:
"""

# ╔═╡ 2e88e435-288e-4d08-b482-e3d2398563f1
add_phase!(model, sphere, matrix)

# ╔═╡ 773314ed-bc12-4097-88a7-bad62b5b1b66
model

# ╔═╡ 5681b716-2959-4ff4-bd14-4c94641310a4
md"""
### Set initial model geometry

We also need to specify an initial model geometry. The julia package `GeophysicalModelGenerator` has a number of functions for that, which can be used here. For the current setup, we just add a sphere: 
"""

# ╔═╡ a3afc50b-2fcd-4067-895d-fde7fb7f8742
AddSphere!(model,cen=(0.0,0.0,0.0), radius=(0.5, ))

# ╔═╡ e0411cc1-60ae-43cf-9500-93a246e62e1b
md"""
It is often useful to plot the initial model setup. You can do this with the `heatmap` function from the `Plots.jl` package, for which we provide a LaMEM plugin that allows you to specify a cross-section through a 3D LaMEM setup:
"""

# ╔═╡ fb23a0a3-1485-4726-8b6e-1a810e50ce7a
heatmap(model, field=:phase, y=0)

# ╔═╡ 4e5cb7d3-f6c0-4dd9-b508-643e38335297
md"""
In the initial serup we define two fields: `:phase` which defines the rocktypes and `:temperature` which has the initial temperature. They are stored as 3D arrays in `model.Grid.Phases` and `model.Grid.Temp`.
"""

# ╔═╡ 0993d48a-e07a-4b28-bd0c-89b2a8f08af3
md"""
### Run LaMEM

At this stage we are ready to run a LaMEM simulation which can simply be done with the `run_lamem` command. By default, it will run on one processor. If you want to run this in parallel, you can specify the number of cores you want to use. Please note that running things in parallel is only worth the effort for large resolutions; for smaller setups it will be faster on one processor:
"""

# ╔═╡ 0873aa40-111d-421b-a72c-9ed8240a8782
run_lamem(model,1)

# ╔═╡ 319aa787-f641-42ab-bdfa-76b04e6e478a
md"""
### Visualize results

Once the simulation is done, you can look at the results using the same `heatmap` function, but by specifying a timestep, which will read that timestep and plot a cross-section though it:
"""

# ╔═╡ eaa307f7-5655-4cf3-8638-47faa28a6a4b
md"""
We can read all timesteps of the simulation with:
"""

# ╔═╡ 3040c159-7281-4971-80ad-8104abb3a6d9
timesteps,_,_ = Read_LaMEM_simulation(model)

# ╔═╡ b7ca7625-4910-4faf-919c-4b785438c574
md"""
Lets add a slider to move through the timesteps:
"""

# ╔═╡ b99498a4-ba99-4d60-ac9e-fc70b227f91e
md"""Timestep $(@bind t Slider(timesteps, show_value=true, default=0))"""

# ╔═╡ 651f376e-e686-4288-b070-4fc14b66fb80
md"""
And use that to slice through time
"""

# ╔═╡ 66d66323-71a4-455a-9a7b-bd1ec3d5ae1c
heatmap(model, y=0, timestep=t, field=:phase, dim=3)	

# ╔═╡ 2cb9ffa5-48da-4d48-8381-51c5d8f65da5
md"""
If you want to know which fields have been saved, you can read a timestep back into julia:
"""

# ╔═╡ c72ffd0d-dbf7-4b88-af5e-de4f76d5ec33
data_cart, time = Read_LaMEM_timestep(model,1)

# ╔═╡ e73a3f02-c1f4-46d8-a0c2-c6f6058e1ca1
md"""
The results are saved to disk and you can also visualize the results with paraview.
"""

# ╔═╡ f7147dc1-17d6-47af-8d92-2f780d471e91
md"""
### Changing parameters

Since we are using Pluto, changing values in one cell will update the full notebook. You can therefore change, for example, the maximum number of timesteps of the simulation at the top of this notebook (`nstep_max`) and it'll redo the simulation but for longer. Try it out!
"""

# ╔═╡ 778d540b-5e56-463f-87a3-d14f17e452ba


# ╔═╡ Cell order:
# ╟─78136b07-5d33-407a-afcf-e0a656181043
# ╠═f744857e-20e6-11ee-1720-311279133704
# ╟─03abfcd4-b3bb-44eb-ba97-c03d64126195
# ╠═4a533c45-2ad6-4970-963b-abbbc798275b
# ╟─b192e665-20f2-4f65-ace9-fe7fffd7b7c7
# ╠═965f3210-d4da-4a0b-8db5-cce85779fd58
# ╟─e85b89ee-7452-45dc-8484-1e2497cf3f7a
# ╟─bd63ef7e-af77-44d8-8127-456f7f6d38a6
# ╠═be5335db-5535-49c6-95d2-49e53d644523
# ╟─6b59fe59-0d0f-4984-8464-c76c18bc8f19
# ╠═87dbe840-1d59-4608-a73b-d4dee2bd2c7a
# ╠═0c1c92d8-9846-4e31-9112-6c2b57e7a069
# ╟─78c4db3c-3f5d-4a91-9ab9-bd00ce0810af
# ╠═2e88e435-288e-4d08-b482-e3d2398563f1
# ╠═773314ed-bc12-4097-88a7-bad62b5b1b66
# ╟─5681b716-2959-4ff4-bd14-4c94641310a4
# ╠═a3afc50b-2fcd-4067-895d-fde7fb7f8742
# ╟─e0411cc1-60ae-43cf-9500-93a246e62e1b
# ╠═fb23a0a3-1485-4726-8b6e-1a810e50ce7a
# ╟─4e5cb7d3-f6c0-4dd9-b508-643e38335297
# ╟─0993d48a-e07a-4b28-bd0c-89b2a8f08af3
# ╠═0873aa40-111d-421b-a72c-9ed8240a8782
# ╟─319aa787-f641-42ab-bdfa-76b04e6e478a
# ╟─eaa307f7-5655-4cf3-8638-47faa28a6a4b
# ╠═3040c159-7281-4971-80ad-8104abb3a6d9
# ╟─b7ca7625-4910-4faf-919c-4b785438c574
# ╟─b99498a4-ba99-4d60-ac9e-fc70b227f91e
# ╟─651f376e-e686-4288-b070-4fc14b66fb80
# ╠═66d66323-71a4-455a-9a7b-bd1ec3d5ae1c
# ╟─2cb9ffa5-48da-4d48-8381-51c5d8f65da5
# ╠═c72ffd0d-dbf7-4b88-af5e-de4f76d5ec33
# ╟─e73a3f02-c1f4-46d8-a0c2-c6f6058e1ca1
# ╟─f7147dc1-17d6-47af-8d92-2f780d471e91
# ╠═778d540b-5e56-463f-87a3-d14f17e452ba
