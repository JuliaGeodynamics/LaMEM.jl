using Test
using GeoParams, LaMEM


@testset "GeoParams 0D rheology" begin

    T0 = 1100;
    ε_vec  = 10.0.^Vector(-17.0:1.0:-13.0);

    
    # compute stress for given strainrate 
    
    # 1) Linear viscous rheology
    rheology = Phase(ID=0,Name="matrix",eta=1e20,rho=3000)
    @show rheology
    τ_linear = stress_strainrate_0D(rheology, ε_vec, T=T0, nstep_max=2)
    τ_anal = 2.0 .* rheology.eta .* ε_vec ./ 1e6;
    @show τ_linear τ_anal
    @test sum(τ_linear-τ_anal) ≈ 0.0 atol=1e-6 # check stress

    # 2) Dislocation creep rheology
    # Serpentinite --- 
    rheology = Phase(ID=0,Name="matrix",disl_prof="Tumut_Pond_Serpentinite-Raleigh_Paterson_1965", rho=3000)
    τ_num1 = stress_strainrate_0D(rheology, ε_vec; T=T0)

    g = SetDislocationCreep(GeoParams.Dislocation.serpentinite_Raleigh_1965)
    rheology1 = add_geoparams_rheologies(Phase(ID=0,Name="rheology",GeoParams=[g], rho=3000))
    τ_num2 = stress_strainrate_0D(rheology1, ε_vec; T=T0)
    @show τ_num1 τ_num2
    @test sum(τ_num1-τ_num2) ≈ 0.0 atol=1e-6 # check stress

    # Olivine ---
    rheology = Phase(ID=0,Name="matrix",disl_prof="Dry_Olivine-Ranalli_1995", Vn=0.0, rho=3000)
    τ_num1 = stress_strainrate_0D(rheology, ε_vec; T=T0)

    g = SetDislocationCreep(GeoParams.Dislocation.Dislocation.dry_olivine_Gerya_2019)
    rheology1 = add_geoparams_rheologies(Phase(ID=0,Name="matrix",GeoParams=[g], rho=3000))
    τ_num2 = stress_strainrate_0D(rheology1, ε_vec, T=T0)
    @test sum(τ_num1-τ_num2) ≈ 0.0 atol=1e-6 # check stress

    # Quartzite --- 
    rheology = Phase(ID=0,Name="rheology",disl_prof="Wet_Quarzite-Ueda_et_al_2008", rho=3000)
    τ_num1 = stress_strainrate_0D(rheology, ε_vec; T=T0)
    #    (disl)   : Bn = 1.53539e-17 [1/Pa^n/s]  En = 154000. [J/mol]  n = 2.3 [ ]  
    #    (disl)   : Bn = 1.53539e-17 [1/Pa^n/s]  En = 154000. [J/mol]  n = 2.3 [ ]  

    g = SetDislocationCreep(GeoParams.Dislocation.wet_quartzite_Ueda_2008)
    rheology1 = add_geoparams_rheologies(Phase(ID=0,Name="rheology",GeoParams=[g], rho=3000))
    τ_num2 = stress_strainrate_0D(rheology1, ε_vec; T=T0)
    @test sum(τ_num1-τ_num2) ≈ 0.0 atol=1e-6 # check stress
    
    
    # 3) Diffusion creep rheology
    #
    # Note: diffusion creep is grain size sensitive. Whereas the current version of LaMEM does not include grain size
    # we take it into account through a prefactor (d0). In GeoParams, grainsize should be added as a parameter
    # Yet, to convert one to the other, we need to specify grainsize in the Phase info 
    rheology = Phase(ID=0,Name="rheology",diff_prof="Dry_Plagioclase_RybackiDresen_2000", rho=3000)
    τ_num1 = stress_strainrate_0D(rheology, ε_vec; T=T0)

    g = SetDiffusionCreep(GeoParams.Diffusion.dry_anorthite_Rybacki_2006)
    rheology1 = Phase(ID=0,Name="rheology",GeoParams=[g], rho=3000, grainsize=100e-6)
    τ_num2 = stress_strainrate_0D(rheology1, ε_vec; T=T0)
    @test sum(τ_num1-τ_num2) ≈ 0.0 atol=1e-6 # check stress
 
    # Note: many of the other diffusion creep laws have a slightly different V exponent in GeoParams vs. LaMEM,
    # and as of now we don't have a way yet to override this in GeoParams (to be added)
    # Thats why we only have one test now

end