# Subduction with FastScape surface processes, in 2D and 3D.
#
# The setup follows the subduction model of the manuscript whose input files are on Zenodo
# (https://zenodo.org/records/21761705, `SubductionModel`): an oceanic plate that is pushed
# towards a continental plate and subducts along a weak zone dipping at 30 degrees, while
# FastScape erodes the topography that builds up and deposits the sediment (phase 8).
#
# `subduction_fastscape_model(ndim=2)` is the cross-section; `ndim=3` is the same model with an
# oceanic plateau on the subducting plate, which makes the subduction zone differ along strike.
# The manuscript ran the 3D model with 384x96x96 elements on 256 cores; the default
# resolutions here are far lower so that the models run on a laptop.
using LaMEM, GeophysicalModelGenerator

"""
    model = subduction_fastscape_model(; ndim=3, nel=nothing, out_dir=nothing, nstep_max=1000000, time_end=10.0, fs_refine=nothing)

Build the subduction model with FastScape. `ndim` is 2 or 3. `nel` is `(nx,nz)` in 2D and
`(nx,ny,nz)` in 3D (default `(96,24)` and `(96,24,24)`). `fs_refine` is the refinement of the
FastScape grid with respect to the LaMEM surface grid (the manuscript uses 6; default 2).
"""
function subduction_fastscape_model(; ndim=2, nel=nothing, out_dir=nothing, nstep_max=1000000,
                                      time_end=10.0, nstep_out=25, fs_refine=2)
    @assert ndim in (2,3) "ndim must be 2 or 3"
    nel     = isnothing(nel)     ? (ndim==2 ? (96,24) : (96,24,24)) : nel
    out_dir = isnothing(out_dir) ? "Subduction_FastScape_$(ndim)D" : out_dir
    @assert length(nel) == ndim "nel must have $ndim entries for a $(ndim)D model"

    # --- the domain [km]: 800 km long, 415 km deep (15 km of sticky air on top) -----------------
    x = [0.0, 800.0];  z = [-400.0, 15.0]
    grid = ndim == 2 ? Grid(nel=nel, x=x, z=z) :
                       Grid(nel=nel, x=x, y=[0.0, 200.0], z=z)
    ylim = (grid.coord_y[1], grid.coord_y[end])

    # --- surface processes: FastScape instead of the built-in erosion --------------------------
    # In 2D the surface of LaMEM is a line, which FastScape needs extended along strike (`fs2D`).
    fs = FastScape(fs2D = ndim == 2 ? 1 : 0, extendedRange = 100.0, extendedNodes = 101,
                   fs_refine = fs_refine, max_fs_dt = 0.001,
                   topo_boundary = "1111", vel_boundary = "0000",
                   sed_phases = 8,
                   kf = 1e-6, m = 0.4, n = 1.0, kd = 1e-2, p = -2.0, set_marine = 0)

    # The oceanic plate on the left is pushed towards the continent by a block that moves
    # 1000 km over 20 Myr (5 cm/yr), as in the manuscript.
    block = BCBlock(npath=2, theta=[0.0, 0.0], time=[0.2, 20.2], path=[0.0, 0.0, 1000.0, 0.0],
                    npoly=4, poly=[50.0, ylim[1]-100, 100.0, ylim[1]-100, 100.0, ylim[2]+100, 50.0, ylim[2]+100],
                    bot=-120.0, top=0.0)

    model = Model(grid,
        Scaling(GEO_units(temperature=1000, length=1km, viscosity=1e20Pa*s, stress=1e12Pa)),
        Time(time_end=time_end, dt=1e-4, dt_min=1e-6, dt_max=0.03, inc_dt=0.1,
             nstep_max=nstep_max, nstep_out=nstep_out),
        BoundaryConditions(temp_top=0.0, temp_bot=1500.0, open_top_bound=1, BCBlocks=[block]),
        SolutionParams(shear_heat_eff=1.0, Adiabatic_Heat=1.0, act_temp_diff=1,
                       eta_min=1e18, eta_ref=1e21, eta_max=1e24, min_cohes=1e3),
        FreeSurface(surf_use=1, surf_level=0.0, surf_air_phase=0, surf_max_angle=45.0,
                    surf_corr_phase=1, surf_mode=2, FastScape=fs),
        Output(out_dir=out_dir, out_file_name="sub", out_phase=1, out_density=1, out_visc_total=1,
               out_velocity=1, out_temperature=1, out_j2_dev_stress=1, out_j2_strain_rate=1,
               out_plast_strain=1, out_surf=1, out_surf_pvd=1, out_surf_topography=1,
               out_surf_velocity=1, out_surf_amplitude=1))

    # --- materials ------------------------------------------------------------------------------
    soft = Softening(ID=0, APS1=0.01, APS2=0.05, A=0.9)
    add_softening!(model, soft)

    olivine(ID, name) = Phase(ID=ID, Name=name, rho=3300.0, beta=1e-11, G=10e10, ch=1e7, fr=30.0,
                              eta_st=1e19, chSoftID=0, frSoftID=0, alpha=3e-5, Cp=1.2e3, k=3.5, A=6e-12,
                              diff_prof="Dry_Olivine_diff_creep-Hirth_Kohlstedt_2003",
                              disl_prof="Dry_Olivine_disl_creep-Hirth_Kohlstedt_2003")
    crust(ID, name)   = Phase(ID=ID, Name=name, rho=2900.0, beta=1e-11, G=5e10, ch=1e6, fr=5.0,
                              eta_st=1e19, chSoftID=0, frSoftID=0, alpha=3e-5, Cp=1.2e3, k=3.0, A=3e-11,
                              disl_prof="Wet_Quarzite-Ranalli_1995")
    add_phase!(model,
        Phase(ID=0, Name="air", rho=1.0, eta=1e18, alpha=3e-5, k=100.0, Cp=1e6, A=0.0),
        Phase(ID=1, Name="weak zone", rho=3200.0, beta=1e-11, G=5e10, eta=1e19, alpha=3e-5, k=3.0, Cp=1.2e3, A=0.0),
        olivine(2, "asthenosphere"),
        crust(3, "oceanic crust"),
        crust(4, "oceanic plateau"),
        crust(5, "continental crust"),
        olivine(6, "oceanic mantle lithosphere"),
        olivine(7, "continental mantle lithosphere"),
        Phase(ID=8, Name="sediment", rho=2500.0, beta=1e-11, G=2e10, ch=1e6, fr=10.0, eta_st=1e19,
              chSoftID=0, frSoftID=0, alpha=3e-5, Cp=1.2e3, k=2.5, A=4e-10,
              disl_prof="Wet_Quarzite-Ranalli_1995"))

    # --- thicknesses [km] and depths of the layers
    thick_oc, thick_sp, thick_op = 8.0, 90.0, 20.0           # oceanic crust, slab, plateau thickness
    z_oc, z_sp, z_left_oc = -thick_oc, -thick_oc - thick_sp, -thick_oc - 20.0

    # --- temperature [C]: adiabat in the mantle, a 70 Myr half-space cooling profile in the plates
    Tpot, dTdz = 1300.0, 0.5
    Z = model.Grid.Grid.Z
    model.Grid.Temp .= Tpot .- dTdz .* Z                     # Z is negative: T increases with depth
    add_box!(model; xlim=(x[1], x[2]), ylim=ylim, zlim=(z_sp, 0.0), phase=ConstantPhase(2),     # (the phases are assigned below)
             T=HalfspaceCoolingTemp(Tsurface=0.0, Tmantle=Tpot + thick_sp*dTdz, Age=70.0))
    model.Grid.Temp[Z .>= 0] .= 0.0                          # air

    # --- geometry [km] --------------------------------------------------------------------------
    X, Y, Z = model.Grid.Grid.X, model.Grid.Grid.Y, model.Grid.Grid.Z
    Phase_  = model.Grid.Phases
    Phase_ .= 2                                              # asthenosphere everywhere ...

    xl, wwz = 400.0, 15.0                                    # weak zone: left side, width
    xr      = xl + wwz
    k       = -tand(30.0)                                    # the weak zone dips at 30 degrees
    zk      = Z ./ k                                         # x-position of the weak zone at depth Z

    Phase_[Z .> 0]                                              .= 0   # sticky air
    Phase_[(Z .> z_oc) .& (Z .<= 0) .& (X .< zk .+ xl)]         .= 3   # subducting oceanic crust
    Phase_[(Z .> z_left_oc) .& (Z .<= z_oc)]                    .= 6   # oceanic mantle lithosphere
    Phase_[(Z .> z_sp) .& (Z .<= z_oc)]                         .= 6
    if ndim == 3                                                       # oceanic plateau
        Phase_[(Z .> -thick_op) .& (Z .<= 0) .& (X .> 275) .& (X .< 375) .& (Y .> 50) .& (Y .< 150)] .= 4
    end
    Phase_[(Z .> z_oc) .& (Z .<= 0) .& (X .>= zk .+ xr)]        .= 5   # overriding continental crust
    Phase_[(Z .> z_sp) .& (Z .<= z_oc) .& (X .>= zk .+ xr)]     .= 7   # ... and its mantle lithosphere
    Phase_[(X .>= zk .+ xl) .& (X .<= zk .+ xr) .& (Z .> z_sp) .& (Z .< 0)] .= 1   # weak zone

    # lithosphere that is hotter than the potential temperature is asthenosphere
    hot = ((Phase_ .== 6) .| (Phase_ .== 7)) .& (model.Grid.Temp .> Tpot)
    Phase_[hot] .= 2

    return model
end
