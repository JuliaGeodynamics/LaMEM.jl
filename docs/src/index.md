# LaMEM.jl

This is the julia interface to LaMEM, which does a number of handy things:

- It will automatically download a binary installation of LaMEM, along with the correct version of PETSc and mpiexec for your system. You can also use these binaries directly from your terminal, so you are not limited to julia. Gone are the days where you had to first spend hours or days to install PETSc on your system!
- We provide a simple function to run LaMEM from julia (also in parallel).
- We provide functions to read timesteps back into julia. 