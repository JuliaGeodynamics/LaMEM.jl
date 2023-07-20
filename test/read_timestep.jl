using Test

@testset "read LaMEM output" begin

    # Read a timestep
    FileName="FB_multigrid"
    Timestep = 1
    data, time = Read_LaMEM_timestep(FileName,Timestep)
    @test  data.fields.phase[1000] ≈ 0.0f0
    @test  data.fields.strain_rate[1][1] ≈ -0.0010996389f0

    fields = Read_LaMEM_fieldnames(FileName)
    
    # with cell-data 
    FileName="FB_multigrid"
    DirName = "Timestep_00000001_6.72970343e+00"
    Timestep = 1
    data, time = Read_LaMEM_timestep(FileName,Timestep, phase=true)
    
    @test data.fields.phase[1000] == 0

    # read subduction setup
    data, time = Read_LaMEM_timestep("Subduction2D_FreeSlip_direct",1)
    @test data.fields.density[10000] ≈ 3200.0f0

    # Read PVD file 
    Timestep, FileNames, Time  = Read_LaMEM_simulation("Subduction2D_FreeSlip_direct")
    @test Time[2] ≈ 0.055
    
    # Read passive tracers 
    data, time = Read_LaMEM_timestep("PlumeLithosphereInteraction",10, passive_tracers=true)
    @test data.z[100] ≈ -298.4531f0
    @test data.fields.Temperature[100] ≈ 1350.0f0
    
    if !Sys.isapple()  # broken on mac  for LaMEM_jll 1.2.3 (should be fixed in next release)
        # Read surface data
        data, time = Read_LaMEM_timestep("Subduction2D_FreeSurface_direct",5, surf=true)
        @test data.z[100] ≈ 0.68236357f0
        @test  sum(data.fields.topography[:,1,1]) ≈ 1.2645866f0
    end
end

