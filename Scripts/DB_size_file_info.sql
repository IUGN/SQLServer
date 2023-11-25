select 
    f.type_desc as [Type]
    ,f.name as [FileName]
    ,fg.name as [FileGroup]
    ,f.physical_name as [Path]
    ,f.size / 128.0 as [CurrentSizeMB]
    ,f.size / 128.0 - convert(int,fileproperty(f.name,'SpaceUsed')) / 
        128.0 as [FreeSpaceMb]
from 
    sys.database_files f with (nolock) left outer join 
        sys.filegroups fg with (nolock) on
            f.data_space_id = fg.data_space_id
option (recompile)