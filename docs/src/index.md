---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: LaMEM.jl
  text: Geodynamic modelling in Julia
  tagline: Set up, run and analyse LaMEM simulations directly from Julia — no manual PETSc or MPI installation required.
  actions:
    - theme: brand
      text: Get Started
      link: /installation
    - theme: alt
      text: Julia model setup
      link: /juliasetups
    - theme: alt
      text: View on GitHub
      link: https://github.com/JuliaGeodynamics/LaMEM.jl
  image:
    src: /assets/logo_LaMEM.png
    alt: LaMEM.jl logo

features:
  - icon: 🚀
    title: Easy installation
    details: Automatically downloads LaMEM binaries with the correct PETSc and MPI for your platform (Linux, macOS, Windows).
    link: /installation

  - icon: 🛠️
    title: Julia ecosystem
    details: Define geometry, materials, boundary conditions and solver options entirely in Julia with sensible defaults. Read LaMEM output back into Julia.
    link: /juliasetups

  - icon: ▶️
    title: Run in parallel
    details: Launch LaMEM on multiple cores with a single function call — no manual mpiexec configuration needed.
    link: /runlamem

  - icon: 🖥️
    title: HPC ready
    details: Prepare model files on a workstation and copy to a cluster to run large models there.
    link: /installation_HPC
---

## What is LaMEM?

`LaMEM` (**L**ithosphere **a**nd **M**antle **E**volution **M**odel) is a parallel 3D numerical code for thermo-mechanical geodynamical simulations. Key features include:

- Visco-elasto-plastic rheologies for mantle-lithosphere interaction
- Geomechanical problems, (compressible) poroelasticity, and a gravity solver
- Adjoint inversion framework
- Marker-in-cell approach with staggered finite difference discretization
- Built on top of PETSc — runs on anything from a laptop to a massively parallel machine
- (Galerkin) multigrid and iterative solvers for linear and non-linear rheologies, using Picard and quasi-Newton solvers
- Tested on large parallel machines on up to 458'752 cores

`LaMEM.jl` provides a Julia interface to `LaMEM` that handles installation, model setup, job execution and postprocessing.

## Citation

If you use LaMEM in your research, please cite the original peer-reviewed extended abstract that describes it: 

- Kaus, B.J.P., Popov, A.A., Baumann, T., Pusok, A., Bauville, A., Fernandez, N., Collignon, M. (2016). Forward and Inverse Modelling of Lithospheric Deformation on Geological Timescales. *NIC Series*, 48, 299-306, [ISBN:978-3-95806-109-5](https://juser.fz-juelich.de/record/507751/files/nic_2016_kaus.pdf).

A more recent publication that gives some more recent details is:

- Schuler, C., Kaus, B.J.P., Breton, E.L., Riel, N., Popov, A.A., 2025. Mantle Dynamics in the Mediterranean and Plate Motion of the Adriatic Microplate: Insights From 3D Thermomechanical Modeling. Geochemistry, Geophysics, Geosystems 26, e2024GC011996. https://doi.org/10.1029/2024GC011996


And for reproducibility reasons, you should always cite the correct version number you use. For LaMEM.jl that is given by the most recent version of the code on [zenodo](https://zenodo.org/records/18842336).


## Funding

LaMEM is an open source software project mainly developed at the Johannes-Gutenberg University in Mainz (Germany).
The key funding came from:
- The European Research Council through Grants ERC StG 258830 (MODEL), ERC PoC 713397 (SALTED) and ERC CoG 771143 (MAGMA)
- The German ministry of Science and Eduction (BMBF) through projects SECURE, PERMEA, and PERMEA2.
- Priority programs of the German research foundation (DFG), specifically the [4DMB](http://www.spp-mountainbuilding.de) and [Habitable Earth](https://habitableearth.uni-koeln.de) projects. 

The development of the Julia interface to LaMEM was supported by the European Research Council under grant ERC CoG #771143 - [MAGMA](https://magma.uni-mainz.de) and by the EuroHPC Center of Excellence [ChEESE-2p](https://cheese2.eu).
