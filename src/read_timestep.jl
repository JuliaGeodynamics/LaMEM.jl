# The routines specified in this module read a LaMEM timestep and return 2D or 3D
# Scalar or Vector Data to julia, for further quantitative analysis
# 
                  
# Make these routines easily available outside the module:
using GeophysicalModelGenerator: CartData, XYZGrid
using Glob, ReadVTK

export Read_LaMEM_PVTR_File, Read_LaMEM_PVTS_File, field_names, readPVD, Read_LaMEM_PVTU_File

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
        data_Tuple  = (data_Field,)
        isCell      =   true;
    else
        data_Tuple  = (get_data_reshaped(data_f[FieldName]),)
    end

    name = filter(x -> !isspace(x), FieldName)  # remove white spaces
    
    id   = findfirst("[", name)
    if !isnothing(id)
        name = name[1:id[1]-1]      # strip out "[" signs
    end
    data_out = NamedTuple{(Symbol(name),)}(data_Tuple,);

    return data_out, isCell
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



"""
    data_output = Read_LaMEM_PVTR_File(DirName, FileName; field=nothing)

Reads a 3D LaMEM timestep from VTR file `FileName`, located in directory `DirName`. 
By default, it will read all fields. If you want you can only read a specific `field`. See the function `fieldnames` to get a list with all available fields in the file.

It will return `data_output` which is a `CartData` output structure.

"""
function Read_LaMEM_PVTR_File(DirName, FileName; field=nothing)
    CurDir = pwd();

    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    pvtk        = PVTKFile(FileName)

    cd(CurDir)

    # Fields stored in this data file:    
    names = keys(get_point_data(pvtk))
    if isempty(names)
        names = keys(get_cell_data(pvtk))
    end

    isCell  = true
    if isnothing(field)
        # read all data in the file
        data_fields = NamedTuple();

        for FieldName in names
            dat, isCell = ReadField_3D_pVTR(pvtk, FieldName);
            data_fields = merge(data_fields,dat)
        end

    else
        # read just a single data set
        ind = findall(contains.(field, names))
        # check that it exists
        if isempty(ind)
            error("the field $field does not exist in the data file")
        else
            data_fields, isCell = ReadField_3D_pVTR(data, field)
        end
    end

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

    FileNames, Time = readPVD(FileName::String)

This reads a PVD file & returns the timesteps and corresponding filenames
"""
function readPVD(FileName::String)

    lines = readlines(FileName)
    start_line = findall(lines .== "<Collection>")[1] + 1
    end_line   = findall(lines .== "</Collection>")[1] - 1
    
    FileNames = [];
    Time      = [];
    for i=start_line:end_line
        line = lines[i]
        time = split(line)[2]; time = parse(Float64,time[11:end-1])
        file = split(line)[3]; file = String.(file[7:end-3]);

        FileNames = [FileNames; file]
        Time      = [Time;      time]
    end

    return FileNames, Time
end


"""
    data_output = Read_LaMEM_PVTU_File(DirName, FileName; field=nothing)

Reads a 3D LaMEM timestep from VTU file `FileName`, located in directory `DirName`. Typically this is done to read passive tracers back into julia. 
By default, it will read all fields. If you want you can only read a specific `field`. See the function `fieldnames` to get a list with all available fields in the file.

It will return `data_output` which is a `CartData` output structure.

"""
function Read_LaMEM_PVTU_File(DirName, FileName; field=nothing)
    CurDir = pwd();

    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    pvtu        = PVTKFile(FileName)

    cd(CurDir)

    # Fields stored in this data file:    
    names = keys(get_point_data(pvtu))
    if isempty(names)
        names = keys(get_cell_data(pvtu))
    end

    isCell  = true
    if isnothing(field)
        # read all data in the file
        data_fields = NamedTuple();
        for FieldName in names
            dat         = ReadField_3D_pVTU(pvtu, FieldName);
            data_fields = merge(data_fields,dat)
        end

    else
        # read just a single data set
        ind = findall(contains.(field, names))
        # check that it exists
        if isempty(ind)
            error("the field $field does not exist in the data file")
        else
            data_fields = ReadField_3D_pVTU(data, field)
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
function Read_LaMEM_PVTS_File(DirName, FileName; field=nothing)
    CurDir = pwd();

    # read data from parallel rectilinear grid
    cd(DirName)
    pvts        = PVTKFile(FileName)
    cd(CurDir)

    # Fields stored in this data file:    
    name = keys(get_point_data(pvts))
    if !isnothing(field)
        if any(occursin.(name,field))
            name = tuple(field);
        else
            error("the field $field does not exist in the data file which has fields: $(name)")
        end
    end

    # Read coordinates
    X,Y,Z = get_coordinates(pvts)
    
    # read all data in the file
    data_fields = NamedTuple();
    for FieldName in name
        dat, _ = LaMEM.ReadField_3D_pVTS(pvts, FieldName);
        if length(dat[1])>length(X)
            dat_tup = ntuple(i->dat[1][i,:,:,:], size(dat[1],1))
            dat = NamedTuple{keys(dat)}(tuple(dat_tup)) 
        end
        data_fields = merge(data_fields,dat)               
    end

    data_output     =   CartData(X,Y,Z, data_fields)
    return data_output      
end