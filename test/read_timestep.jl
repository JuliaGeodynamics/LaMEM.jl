using Test
using LaMEM

@testset "read LaMEM output" begin

    # Read a timestep
    FileName="FB_multigrid.pvtr"
    DirName = "Timestep_00000001_6.72970343e+00"

    data    = Read_LaMEM_PVTR_File(DirName, FileName)
    @test  sum(data.fields.phase) ≈ 736.36414f0
    @test  sum(data.fields.strain_rate[1,:,:,:]) ≈ -0.019376338f0

    fields = field_names(DirName, FileName)

    # with cell-data 
    FileName="FB_multigrid_phase.pvtr"
    DirName = "Timestep_00000001_6.72970343e+00"
    data    = Read_LaMEM_PVTR_File(DirName, FileName)
    @test sum(data.fields.phase) == 19822

    # read subduction setup
    data    = Read_LaMEM_PVTR_File("Timestep_00000001_5.50000000e-02", "Subduction2D_FreeSlip_direct.pvtr")
    @test sum(data.fields.density) ≈ 1.60555f8

    # Read PVD file 
    FileNames, Time = readPVD("Subduction2D_FreeSlip_direct.pvd")
    @test Time[2] ≈ 0.055
    
    # Read passive tracers 
    data    = Read_LaMEM_PVTU_File("Timestep_00000010_1.09635548e+00", "PlumeLithosphereInteraction_passive_tracers.pvtu")
    @test data.z[100] ≈ -298.4531f0
    @test data.fields.Temperature[100] ≈ 1350.0f0
    
    # Read surface data
    data    = Read_LaMEM_PVTS_File("Timestep_00000005_7.59607376e-02", "Subduction2D_FreeSurface_direct_surf.pvts")
    @test data.z[100] ≈ 0.6830405f0
    @test  sum(data.fields.topography[:,1,1]) ≈ 1.2634416f0
end

