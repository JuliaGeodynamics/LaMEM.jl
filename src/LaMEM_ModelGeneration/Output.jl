# Output options


export Output, Write_LaMEM_InputFile

"""
    Structure that contains the LaMEM output options
    
    $(TYPEDFIELDS)
"""
Base.@kwdef mutable struct Output
    "output file name"
    out_file_name       = "output"

    "activate writing .pvd file"
    out_pvd             = 1     

    "dominant phase"
    out_phase           = 1     

    "density"
    out_density         = 1     

    "total (viscoelastoplastic) viscosity"
    out_visc_total      = 1     

    "creep viscosity"
    out_visc_creep      = 1     

    "velocity"
    out_velocity        = 1     

    "(dynamic) pressure"
    out_pressure        = 0     

    "total pressure"
    out_tot_press       = 0     

    "effective pressure"
    out_eff_press       = 0     

    out_over_press      = 0

    out_litho_press     = 0

    out_pore_press      = 0

    "temperature"
    out_temperature     = 0     

    "deviatoric strain rate tensor"
    out_dev_stress      = 0     

    "second invariant of deviatoric stress tensor"
    out_j2_dev_stress   = 0     

    "deviatoric strain rate tensor"
    out_strain_rate     = 0     

    "second invariant of strain rate tensor"
    out_j2_strain_rate  = 0     

    out_shmax           = 0

    out_ehmax           = 0

    out_yield           = 0

    "relative proportion of diffusion creep strainrate"
    out_rel_dif_rate    = 0     

    "relative proportion of dislocation creep strainrate"
    out_rel_dis_rate    = 0     

    "relative proportion of peierls creep strainrate"
    out_rel_prl_rate    = 0     

    "relative proportion of plastic strainrate"
    out_rel_pl_rate     = 0     

    "accumulated plastic strain"
    out_plast_strain    = 0     

    "plastic dissipation"
    out_plast_dissip    = 0     

    out_tot_displ       = 0

    out_moment_res      = 0

    out_cont_res        = 0

    out_energ_res       = 0

    out_melt_fraction   = 0

    out_fluid_density   = 0

    out_conductivity    = 0

    out_vel_gr_tensor   = 0 

    "activate surface output"
    out_surf            = 0 

    "activate writing .pvd file"
    out_surf_pvd        = 0 
    
    "surface velocity"
    out_surf_velocity   = 0

    "surface topography "
    out_surf_topography = 0

    "amplitude of topography (=topo-average(topo))"
    out_surf_amplitude  = 0

    "activate marker output"
    out_mark     = 0 

    "activate writing .pvd file"
    out_mark_pvd = 0 

    "activate AVD phase output"
    out_avd     = 0 

    "activate writing .pvd file"
    out_avd_pvd = 0 

    "AVD grid refinement factor"
    out_avd_ref = 0 

    "activate"
    out_ptr              = 0    

    "ID of the passive tracers"
    out_ptr_ID           = 0    

    "phase of the passive tracers"
    out_ptr_phase        = 0    

    "interpolated pressure"
    out_ptr_Pressure     = 0    

    "temperature"
    out_ptr_Temperature  = 0    

    "melt fraction computed using P-T of the marker"
    out_ptr_MeltFraction = 0    

    "option that highlight the marker that are currently active"
    out_ptr_Active       = 0    

    "option that allow to store the melt fraction seen within the cell"
    out_ptr_Grid_Mf      = 0    
end

# Print info about the structure
function show(io::IO, d::Output)
    Reference = Output();
    println(io, "LaMEM Output options: ")
    fields    = fieldnames(typeof(d))

    # print fields
    for f in fields
        col = gettext_color(d,Reference, f)
        printstyled(io,"  $(rpad(String(f),20)) = $(getfield(d,f)) \n", color=col)        
    end

  
    return nothing
end

function show_short(io::IO, d::Output)
    println(io,"|-- Output options      :  filename=$(d.out_file_name); pvd=$(d.out_pvd)")

    return nothing
end



"""
    Write_LaMEM_InputFile(io, d::Output)
Writes the free surface related parameters to file
"""
function Write_LaMEM_InputFile(io, d::Output)
    Reference = Solver();    # reference values
    fields    = fieldnames(typeof(d))

    println(io, "#===============================================================================")
    println(io, "# Output options")
    println(io, "#===============================================================================")
    println(io,"")

    for f in fields
        if getfield(d,f) != getfield(Reference,f) 
            # only print if value differs from reference value
            name = rpad(String(f),15)
            comment = get_doc(Output, f)
            data = getfield(d,f) 
            println(io,"    $name  = $(write_vec(data))     # $(comment)")
        end
    end


    println(io,"")
    return nothing
end