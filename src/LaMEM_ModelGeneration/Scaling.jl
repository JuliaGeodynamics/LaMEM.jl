export Scaling, Write_LaMEM_InputFile 

"""
    Scaling{T} is a structure that contains the scaling info, employed in the current simulation
    
    $(TYPEDFIELDS)

"""
mutable struct Scaling{T}

    "Scaling object (as in GeoParams), which can be `GEO_units()`, `NO_units()`, or `SI_units()`"
    Scaling::T
    
    function Scaling(
        Scaling=GEO_units()
        )
        return new{typeof(Scaling)}(Scaling)
    end
    
end

# Show brief overview 
function show(io::IO, d::Scaling{T}) where T
    println(io,"$(d.Scaling)")
end

function show_short(io::IO, d::Scaling{T}) where T
    println(io,"|-- Scaling             :  $T")
end


function Write_LaMEM_InputFile(io, d::Scaling) 
    println(io, "#===============================================================================")
    println(io, "# Scaling")
    println(io, "#===============================================================================")
    println(io,"")
    if isa(d,Scaling{GeoUnits{GEO}}) || isa(d,Scaling{GeoUnits{SI}})
        if isa(d,Scaling{GeoUnits{GEO}})
            println(io,"    units = geo")
        elseif isa(d,Scaling{GeoUnits{SI}})
            println(io,"    units = si")
        end
        char_T = ustrip(d.Scaling.temperature)
        char_L = uconvert(u"m",d.Scaling.length);
        char_η = uconvert(u"Pa*s",d.Scaling.viscosity);
        char_τ = uconvert(u"Pa",d.Scaling.stress);
        println(io,"    unit_temperature = $char_T")
        println(io,"    unit_length      = $char_L")
        println(io,"    unit_viscosity   = $char_η")
        println(io,"    unit_stress      = $char_τ")

    elseif isa(d,Scaling{GeoUnits{NONE}}) 
        println(io,"    units = none")
    else
        error("unknown scaling")
    end
    println(io,"")

end
