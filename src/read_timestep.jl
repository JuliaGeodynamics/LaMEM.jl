# The routines specified in this module read a LaMEM timestep and return 2D or 3D
# Scalar or Vector Data to julia, for further quantitative analysis
# 
                  
# Make these routines easily available outside the module:
using GeophysicalModelGenerator: CartData, XYZGrid
using Glob, ReadVTK

export Read_LaMEM_PVTR_File, Read_LaMEM_PVTS_File, Read_LaMEM_PVTU_File
export Read_LaMEM_simulation, Read_LaMEM_timestep, Read_LaMEM_fieldnames
export PassiveTracer_Time

""" 
    output, isCell = ReadField_3D_pVTR(data, FieldName::String)

Extracts a 3D data field from a pVTR data structure `data`

Input:
- `data`:       Data structure obtained with Read_VTR_File
- `FieldName`:  Exact name of the field as specified in the *.vtr file
    
Output:
- `data_field`, `isCell`:   3D field with data, and a flag that indicates whether it is Cell data (PointData otherwise)
                               `data_field` is a tuple of size 1, or 3 depending on whether it is a scalar or vector field
    
"""
function ReadField_3D_pVTR(pvtk, FieldName)
    isCell          =   false;

    # first try to get point data 
    data_f = get_point_data(pvtk)
    # if empty then load cell data
    if isempty(keys(data_f)) 
        data_f      = get_cell_data(pvtk)
        data_Field  = get_data_reshaped(data_f[FieldName], cell_data=true)

        if typeof(data_Field[1])==UInt8
            data_Field = Int64.(data_Field)
        end

        data_Field  = ArrayToTuple(data_Field);
        
        data_Tuple  = (data_Field,)
        isCell      =   true;
    else
        data_Field = get_data_reshaped(data_f[FieldName]);
        
        data_Field = ArrayToTuple(data_Field);

        data_Tuple = (data_Field,)
    end

    name = filter(x -> !isspace(x), FieldName)  # remove white spaces
    
    id   = findfirst("[", name)
    if !isnothing(id)
        name = name[1:id[1]-1]      # strip out "[" signs
    end
    data_out = NamedTuple{(Symbol(name),)}(data_Tuple,);

    return data_out, isCell
end

"""
    data_Field = ArrayToTuple(data_Field)
Transfers a n by 3D array (n>1) to 
"""
function ArrayToTuple(data_Field)
    if length(size(data_Field))>3
        # this a vector or tensor field. For compatibility with GMG, we need to make a tuple out of this
        n = size(data_Field)[1]
        data_t=();
        for i=1:n
            data_t = (data_t..., data_Field[i,:,:,:])
        end
        data_t
    else
        data_t = data_Field
    end
    return data_t
end

function ReadField_3D_pVTS(pvts, FieldName)
    isCell          =   false;
    
    # first try to get point data 
    data_f = get_point_data(pvts)
    # if empty then load cell data
    if isempty(keys(data_f)) 
        data_f      = get_cell_data(pvts)
        data_Field  = get_data_reshaped(data_f[FieldName], cell_data=true)[:,:,:,1]

        if typeof(data_Field[1])==UInt8
            data_Field = Int64.(data_Field)
        end
        data_Tuple  = (data_Field,)
        isCell      =   true;
    else
        data_Tuple  = (get_data_reshaped(data_f[FieldName])[:,:,:,1],)
    end

    name = filter(x -> !isspace(x), FieldName)  # remove white spaces
    
    id   = findfirst("[", name)
    if !isnothing(id)
        name = name[1:id[1]-1]      # strip out "[" signs
    end
    data_out = NamedTuple{(Symbol(name),)}(data_Tuple,);

    return data_out, isCell
end


""" 
    output, isCell = ReadField_3D_pVTU(data, FieldName::String)
Extracts a 3D data field from a pVTU data structure `data`
Input:
- `data`:       Data structure obtained with Read_VTR_File
- `FieldName`:  Exact name of the field as specified in the *.vtr file
    
Output:
- `data_field`: Array with data, `data_field` is a tuple of size 1, 3 or 9 depending on whether it is a scalar, vector or tensor field
    
"""
function ReadField_3D_pVTU(pvtu, FieldName)

    # first try to get point data 
    data_f = get_point_data(pvtu)
    # if empty then load cell data
    if isempty(keys(data_f)) 
        data_f      = get_cell_data(pvtk)
        data_Field  = get_data(data_f[FieldName], cell_data=true)[1]

        if typeof(data_Field[1])==UInt8
            data_Field = Int64.(data_Field)
        end
        data_Tuple  = (data_Field,)

    else
        data_Tuple  = (get_data(data_f[FieldName])[1],)
    end

    name = filter(x -> !isspace(x), FieldName)  # remove white spaces
    
    id   = findfirst("[", name)
    if !isnothing(id)
        name = name[1:id[1]-1]      # strip out "[" signs
    end
    data_out = NamedTuple{(Symbol(name),)}(data_Tuple,);

    return data_out
end

 # The FileName can contain a directory as well; deal with that here
function split_path_name(DirName_base::String, FileName::String)
    FullName = joinpath(DirName_base,FileName)
    id       = findlast("/", FullName)[1];
    
    DirName  = FullName[1:id-1]
    File     = FullName[id+1:end]

    return DirName, File
end


"""
    data_output = Read_LaMEM_PVTR_File(DirName, FileName; fields=nothing)

Reads a 3D LaMEM timestep from VTR file `FileName`, located in directory `DirName`. 
By default, it will read all fields. If you want you can only read a specific `field`. See the function `fieldnames` to get a list with all available fields in the file.

It will return `data_output` which is a `CartData` output structure.

"""
function Read_LaMEM_PVTR_File(DirName_base::String, FileName::String; fields=nothing)
    CurDir = pwd();

    DirName, File = split_path_name(DirName_base, FileName)
    
    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    pvtk        = PVTKFile(File)

    # Fields stored in this data file:    
    names = keys(get_point_data(pvtk))
    if isempty(names)
        names = keys(get_cell_data(pvtk))
    end

    isCell  = true
    if isnothing(fields)
        # read all data in the file
        data_fields = NamedTuple();

        for FieldName in names
            dat, isCell = ReadField_3D_pVTR(pvtk, FieldName);
            data_fields = merge(data_fields,dat)
        end

    else
        # read the data sets specified
        data_fields = NamedTuple();
        for field in fields
            ind = findall(contains.(names,field))
            # check that it exists
            if isempty(ind)
                error("the field $field does not exist in the data file")
            else
                field_name = names[ind[1]]
                dat, isCell = ReadField_3D_pVTR(pvtk, field_name)
            end
            data_fields = merge(data_fields,dat)
        end
    end
    cd(CurDir)

    coords_read = get_coordinates(pvtk)

    # Read coordinates
    x = coords_read[1]
    y = coords_read[2]
    z = coords_read[3]

    if isCell 
        # In case we have cell data , coordinates are center of cell
        x = (x[1:end-1] + x[2:end])/2
        y = (y[1:end-1] + y[2:end])/2
        z = (z[1:end-1] + z[2:end])/2
    end

    X,Y,Z = XYZGrid(x,y,z)
    data_output     =   CartData(X,Y,Z, data_fields)
    return data_output   
end


"""

    FileNames, Time, Timestep = readPVD(FileName::String)

This reads a PVD file & returns the `FileNames`, `Time` and `Timesteps`
"""
function readPVD(FileName::String)

    lines = readlines(FileName)
    start_line = findall(lines .== "<Collection>")[1] + 1
    end_line   = findall(lines .== "</Collection>")[1] - 1
    
    FileNames = Vector{String}()
    Time      = Vector{Float64}()
    Timestep  = Vector{Int64}()
    for i=start_line:end_line
        line = lines[i]
        time = split(line)[2]; time = parse(Float64,time[11:end-1])
        file = split(line)[3]; file = String.(file[7:end-3]);

        FileNames = push!(FileNames, file)
        Time = push!(Time, time)

        # retrieve the timestep 
        file_name = split(file,Base.Filesystem.path_separator)[1];
        
        timestep = parse(Int64,split(file_name,"_")[2]);
        Timestep = push!(Timestep, timestep)
        
    end

    return FileNames, Time, Timestep
end


"""
    data_output = Read_LaMEM_PVTU_File(DirName, FileName; fields=nothing)

Reads a 3D LaMEM timestep from VTU file `FileName`, located in directory `DirName`. Typically this is done to read passive tracers back into julia. 
By default, it will read all fields. If you want you can only read a specific `field`. See the function `fieldnames` to get a list with all available fields in the file.

It will return `data_output` which is a `CartData` output structure.

"""
function Read_LaMEM_PVTU_File(DirName_base, FileName; fields=nothing)
    CurDir = pwd();

    DirName, File = split_path_name(DirName_base, FileName)
    
    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    pvtu        = PVTKFile(File)

    cd(CurDir)

    # Fields stored in this data file:    
    names = keys(get_point_data(pvtu))
    if isempty(names)
        names = keys(get_cell_data(pvtu))
    end

    isCell  = true
    if isnothing(fields)
        # read all data in the file
        data_fields = NamedTuple();
        for FieldName in names
            dat         = ReadField_3D_pVTU(pvtu, FieldName);
            data_fields = merge(data_fields,dat)
        end

    else
        # read the data sets specified
        data_fields = NamedTuple();
        for field in fields
            ind = findall(contains.(field, names))
            # check that it exists
            if isempty(ind)
                error("the field $field does not exist in the data file")
            else
                dat, isCell = ReadField_3D_pVTU(pvtk, field)
            end
            data_fields = merge(data_fields,dat)
        end
    end

    points  = get_points(pvtu)

    # Read coordinates
    x = points[1][1,:]
    y = points[1][2,:]
    z = points[1][3,:]

    data_output     =   CartData(x,y,z, data_fields)
    return data_output     
end


"""
    data_output = Read_LaMEM_PVTS_File(DirName, FileName; field=nothing)

Reads a 3D LaMEM timestep from VTS file `FileName`, located in directory `DirName`. Typically this is done to read passive tracers back into julia. 
By default, it will read all fields. If you want you can only read a specific `field`. See the function `fieldnames` to get a list with all available fields in the file.

It will return `data_output` which is a `CartData` output structure.

"""
function Read_LaMEM_PVTS_File(DirName_base::String, FileName::String; fields=nothing)
    CurDir = pwd();

    DirName, File = split_path_name(DirName_base, FileName)
    
    # read data from parallel rectilinear grid
    cd(DirName)
    pvts        = PVTKFile(File)
    cd(CurDir)

    # Fields stored in this data file:    
    names = keys(get_point_data(pvts))
    if isempty(names)
        names = keys(get_cell_data(pvts))
    end

    # Read coordinates
    X,Y,Z = get_coordinates(pvts)
    
    # read all data in the file
    data_fields = NamedTuple();
    for FieldName in names
        dat, _ = ReadField_3D_pVTS(pvts, FieldName);
        if length(dat[1])>length(X)
            dat_tup = ntuple(i->dat[1][i,:,:,:], size(dat[1],1))
            dat = NamedTuple{keys(dat)}(tuple(dat_tup)) 
        end
        data_fields = merge(data_fields,dat)               
    end

    data_output     =   CartData(X,Y,Z, data_fields)
    return data_output      
end


"""
    data, time = Read_LaMEM_timestep(FileName::String, TimeStep::Int64=0, DirName::String=""; fields=nothing, phase=false, surf=false, last=false)

This reads a LaMEM timestep.

Input Arguments:
- `FileName`: name of the simulation, w/out extension
- `Timestep`: timestep to be read, unless `last=true` in which case we read the last one
- `DirName`: name of the main directory (i.e. where the `*.pvd` files are located)
- `fields`: Tuple with optional fields; if not specified all will be loaded
- `phase`: Loads the phase information of LaMEM if true
- `surf`: Loads the free surface of LaMEM if true
- `passive_tracers`: Loads passive tracers if true
- `last`: Loads the last timestep

Output:
- `data`: Cartesian data struct with LaMEM output
- `time`: The time of the timestep

"""
function Read_LaMEM_timestep(FileName::String, TimeStep::Int64=0, DirName::String=pwd(); fields=nothing, phase=false, surf=false, passive_tracers=false, last=false)

    Timestep, FileNames, Time  = Read_LaMEM_simulation(FileName, DirName; phase=phase, surf=surf, passive_tracers=passive_tracers);
    
    ind = findall(Timestep.==TimeStep)
    
    if last==true; ind = length(Time); end
    if isempty(ind); error("this timestep does not exist"); end

    # Read file
    if surf==true
        data = Read_LaMEM_PVTS_File(DirName, FileNames[ind[1]], fields=fields)
    elseif passive_tracers==true
        data = Read_LaMEM_PVTU_File(DirName, FileNames[ind[1]], fields=fields)
    else
        data = Read_LaMEM_PVTR_File(DirName, FileNames[ind[1]], fields=fields)
    end

    return data, Time[ind]
end


""" 
    Timestep, FileNames, Time = Read_LaMEM_simulation(FileName::String, DirName::String=""; phase=false, surf=false, passive_tracers=false)

Reads a LaMEM simulation `FileName` in directory `DirName` and returns the timesteps, times and filenames of that simulation.
"""
function Read_LaMEM_simulation(FileName::String, DirName::String=""; phase=false, surf=false, passive_tracers=false)

    if phase==true
        pvd_file=FileName*"_phase.pvd"
    elseif surf==true
        pvd_file=FileName*"_surf.pvd"
    elseif passive_tracers==true
        pvd_file=FileName*"_passive_tracers.pvd"
    else
        pvd_file=FileName*".pvd"
    end

    FileNames, Time, Timestep = readPVD(joinpath(DirName,pvd_file))

    return Timestep, FileNames, Time
end

"""
    Read_LaMEM_fieldnames(FileName::String, DirName_base::String=""; phase=false, surf=false, tracers=false)

Returns the names of the datasets stored in `FileName`
"""
function Read_LaMEM_fieldnames(FileName::String, DirName_base::String=""; phase=false, surf=false, tracers=false)

    _, FileNames, _  = Read_LaMEM_simulation(FileName, DirName_base; phase=phase, surf=surf);
    
    # Read file
    DirName, File = split_path_name(DirName_base, FileNames[1])
    
    # change to directory
    cur_dir = pwd();

    # read data from parallel rectilinear grid
    cd(DirName)
    if !tracers
        pvtk = PVTKFile(File)
    else
        pvtk = PVTUFile(File)
    end
    cd(cur_dir)

    # Fields stored in this data file:   
    if phase==false 
        names = keys(get_point_data(pvtk))
    else
        names = keys(get_cell_data(pvtk))
    end

    return names
end


"""
    PT = PassiveTracer_Time(ID::Union{Vector{Int64},Int64}, FileName::String, DirName::String="")

This reads passive tracers with `ID` from a LaMEM simulation, and returns a named tuple with the temporal 
evolution of these passive tracers. We return `x`,`y`,`z` coordinates and all fields specified in the `FileName` for particles number `ID`.

"""
function PassiveTracer_Time(ID::Union{Vector{Int64},Int64}, FileName::String, DirName::String="")
    Timestep, _, Time_Myrs  = Read_LaMEM_simulation(FileName, DirName,passive_tracers=true)

    # read first timestep
    data0, _ = Read_LaMEM_timestep(FileName, Timestep[1], DirName,  passive_tracers=true)
    
    nt = extract_passive_tracers_CartData(data0, ID );
    for timestep in Timestep
        data, t = Read_LaMEM_timestep(FileName, timestep, DirName,  passive_tracers=true);

        nt1 = extract_passive_tracers_CartData(data, ID );
        if timestep>Timestep[1]
            # We already added the first one above
            nt  = combine_named_tuples(nt,nt1)
        end
    end
    nt = merge(nt, (; Time_Myrs) )

    return nt
end


# This extracts one timestep and returns a NamedTuple
function extract_passive_tracers_CartData(data0::CartData, ID )
    flds = keys(data0.fields)
    flds = flds[ findall(flds .!= :ID)]; # remove ID field 

    x = Float64.(data0.x.val[ID.+1])
    y = Float64.(data0.y.val[ID.+1])
    z = Float64.(data0.z.val[ID.+1])
    nt = (; x,y,z)
    for f in flds
        nt_temp = NamedTuple{(f,)}( (Float64.(data0.fields[f][ID.+1]),) ) 
        nt = merge(nt, nt_temp)
    end

    return nt
end

# Ctreaye
function combine_named_tuples(nt,nt1)
    flds = keys(nt);

    for f in flds
        nt_temp = NamedTuple{(f,)}( (hcat(nt[f],nt1[f]),) ) 
        nt = merge(nt, nt_temp)
    end

    return nt
end