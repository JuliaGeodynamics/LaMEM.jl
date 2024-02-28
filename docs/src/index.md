# LaMEM.jl

This is the julia interface to LaMEM, which does a number of handy things:

- It will automatically download a binary installation of LaMEM, along with the correct version of PETSc and mpiexec for your system. You can also use these binaries directly from your terminal, so you are not limited to julia. Gone are the days where you had to first spend hours or days to install PETSc on your system!
- It provides the functionality to setup a model, run it and plot the results with a few lines of julia.
- We provide many default options
- You can do this with Jupyter or Pluto notebooks
- We provide a simple function to run LaMEM from julia (also in parallel), using classical LaMEM `*.dat` files
- We provide functions to read timesteps back into julia and compress out 