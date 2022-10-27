# The routines specified in this module read a LaMEM timestep and return 2D or 3D
# Scalar or Vector Data to julia, for further quantitative analysis
# 
                  
# Make these routines easily available outside the module:
using GeophysicalModelGenerator: CartData, XYZGrid
using Glob

export Read_VTR_File, field_names, readPVD, Read_VTU_File


function vtkXMLPRectilinearGridReader(FileName)
  reader1  = pyvtk.vtkXMLPRectilinearGridReader()
  reader1.SetFileName(FileName)
  reader1.Update()
  data    = reader1.GetOutput()
  return data
end

function vtkXMLPUnstructuredGridReader(FileName)
    reader1  = pyvtk.vtkXMLPUnstructuredGridReader()
    reader1.SetFileName(FileName)
    reader1.Update()
    data    = reader1.GetOutput()
    return data
  end

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
function ReadField_3D_pVTR(data, FieldName)
    
    x               =   data.GetXCoordinates();
    y               =   data.GetYCoordinates();
    z               =   data.GetZCoordinates();
    
    nx              =   PythonCall.pyconvert(Int, x.GetSize());
    ny              =   PythonCall.pyconvert(Int, y.GetSize());
    nz              =   PythonCall.pyconvert(Int, z.GetSize());
    isCell          =   false;
    
    # First assume they are point data
    data_f          =   data.GetPointData().GetArray(FieldName)
    if PythonCall.pyisnone(data_f)
        data_f          =   data.GetCellData().GetArray(FieldName)      # Try Cell Data
    end
    numData = PythonCall.pyconvert(Int,data_f.GetDataSize())
    data_Field      =   PythonCall.pyconvert(Array, data_f);
    if  size(data_Field,1) != nx*ny*nz
        isCell = true;
        nx = nx-1;
        ny = ny-1;
        nz = nz-1;
    end

    if size(data_Field,2) == 1
        data_Field  =   reshape(data_Field     ,(nx,ny,nz))
        if typeof(data_Field[1])==UInt8
            data_Field = Int64.(data_Field)
        end

        data_Tuple  =   (data_Field, )
    elseif size(data_Field,2) == 3
        Vx          =   reshape(data_Field[:,1],(nx,ny,nz));
        Vy          =   reshape(data_Field[:,2],(nx,ny,nz));
        Vz          =   reshape(data_Field[:,3],(nx,ny,nz));
        data_Tuple  =   ((Vx,Vy,Vz),)
    elseif size(data_Field,2) == 9
        xx          =   reshape(data_Field[:,1],(nx,ny,nz));
        xy          =   reshape(data_Field[:,2],(nx,ny,nz));
        xz          =   reshape(data_Field[:,3],(nx,ny,nz));
        yx          =   reshape(data_Field[:,4],(nx,ny,nz));
        yy          =   reshape(data_Field[:,5],(nx,ny,nz));
        yz          =   reshape(data_Field[:,6],(nx,ny,nz));
        zx          =   reshape(data_Field[:,7],(nx,ny,nz));
        zy          =   reshape(data_Field[:,8],(nx,ny,nz));
        zz          =   reshape(data_Field[:,9],(nx,ny,nz));
        
        data_Tuple  =   ((xx,xy,xz,yx,yy,yz,zx,zy,zz),)
    else
        error("Not yet implemented for this size $(size(data_Field,2))")
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
function ReadField_3D_pVTU(data, FieldName)
    
    n               =   PythonCall.pyconvert(Int, data.GetNumberOfPoints());
    coords          =   PythonCall.pyconvert(Array,data.GetPoints().GetData()); # coordinates of points
 
    # First assume they are point data
    data_f          =   data.GetPointData().GetArray(FieldName)
    if PythonCall.pyisnone(data_f)
        data_f          =   data.GetCellData().GetArray(FieldName)      # Try Cell Data
    end
    numData = PythonCall.pyconvert(Int,data_f.GetDataSize())
    data_Field      =   PythonCall.pyconvert(Array, data_f);
   
    if size(data_Field,2) == 1
        data_Field  =   data_Field;
        if typeof(data_Field[1])==UInt8
            data_Field = Int64.(data_Field)
        end

        data_Tuple  =   (data_Field, )
    elseif size(data_Field,2) == 3
        Vx          =   data_Field[:,1]
        Vy          =   data_Field[:,2]
        Vz          =   data_Field[:,3]
        data_Tuple  =   ((Vx,Vy,Vz),)
    elseif size(data_Field,2) == 9
        xx          =   data_Field[:,1]
        xy          =   data_Field[:,2]
        xz          =   data_Field[:,3]
        yx          =   data_Field[:,4]
        yy          =   data_Field[:,5]
        yz          =   data_Field[:,6]
        zx          =   data_Field[:,7]
        zy          =   data_Field[:,8]
        zz          =   data_Field[:,9]
        
        data_Tuple  =   ((xx,xy,xz,yx,yy,yz,zx,zy,zz),)
    else
        error("Not yet implemented for this size $(size(data_Field,2))")
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
    names = field_names(data)

Returns the names of all fields stored in the vtr data structure `data`.
"""
function field_names(data)
    names = [];
    
    # Get Names of PointData arrays
    pdata = data.GetPointData()
    num = PythonCall.pyconvert(Int,pdata.GetNumberOfArrays())
    for i=1:num
        names = [names; PythonCall.pyconvert(String,pdata.GetArrayName(i-1))]
    end

     # Get Names of CellData arrays
     cdata = data.GetCellData()
     num = PythonCall.pyconvert(Int,cdata.GetNumberOfArrays())
     for i=1:num
         names = [names; PythonCall.pyconvert(String,cdata.GetArrayName(i-1))]
     end

    return names;
end

"""
    names = field_names(DirName, FileName)

Returns the names of all fields stored in the vtr file in the directory `Directory` and file `FileName`.
"""
function field_names(DirName, FileName)
    CurDir = pwd();

    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    data = vtkXMLPRectilinearGridReader(FileName);      # this is how it should be done within modules
    cd(CurDir)

    # Fields stored in this data file:     
    names = field_names(data);

    return names;
end


"""
    data_output = Read_VTR_File(DirName, FileName; field=nothing)

Reads a 3D LaMEM timestep from VTR file `FileName`, located in directory `DirName`. 
By default, it will read all fields. If you want you can only read a specific `field`. See the function `fieldnames` to get a list with all available fields in the file.

It will return `data_output` which is a `CartData` output structure.

"""
function Read_VTR_File(DirName, FileName; field=nothing)
    CurDir = pwd();

    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    data = vtkXMLPRectilinearGridReader(FileName);      # this is how it should be done within modules
    cd(CurDir)

    # Fields stored in this data file:     
    names = field_names(data);
    isCell  = true
    if isnothing(field)
        # read all data in the file
        data_fields = NamedTuple();
        for FieldName in names
            dat, isCell = ReadField_3D_pVTR(data, FieldName);
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

    # Read coordinates
    x               =   PythonCall.pyconvert(Array,data.GetXCoordinates());
    y               =   PythonCall.pyconvert(Array,data.GetYCoordinates());
    z               =   PythonCall.pyconvert(Array,data.GetZCoordinates());
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
    data_output = Read_VTU_File(DirName, FileName; field=nothing)

Reads a 3D LaMEM timestep from VTU file `FileName`, located in directory `DirName`. Typically this is done to read passive tracers back into julia. 
By default, it will read all fields. If you want you can only read a specific `field`. See the function `fieldnames` to get a list with all available fields in the file.

It will return `data_output` which is a `CartData` output structure.

"""
function Read_VTU_File(DirName, FileName; field=nothing)
    CurDir = pwd();

    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    data = vtkXMLPUnstructuredGridReader(FileName);      # this is how it should be done within modules
    cd(CurDir)

    # Fields stored in this data file:     
    names = field_names(data);
    isCell  = true
    if isnothing(field)
        # read all data in the file
        data_fields = NamedTuple();
        for FieldName in names
            dat         = ReadField_3D_pVTU(data, FieldName);
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

    # Read coordinates
    coords          =   PythonCall.pyconvert(Array,data.GetPoints().GetData()); # coordinates of points
    x               =   coords[:,1];
    y               =   coords[:,2];
    z               =   coords[:,3];
   
    data_output     =   CartData(x,y,z, data_fields)
    return data_output   
end