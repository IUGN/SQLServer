
function Execute-DBCC
{
    param (
        [parameter(Mandatory = $true)][string]$serverInstance
    )

    $connString = "Server=$serverInstance;Integrated Security=SSPI;Database=master;Application Name=$ScriptName"
    $masterConn = new-object ('System.Data.SqlClient.SqlConnection') $connString
    $masterCmd = new-object System.Data.SqlClient.SqlCommand 
    $masterCmd.Connection = $masterConn

    $masterCmd.CommandText = "EXECUTE master.sys.sp_MSforeachdb 'DBCC CHECKDB([?]) WITH TABLERESULTS'"
    $masterConn.Open()
    $reader = $masterCmd.ExecuteReader()

    if ($reader.HasRows -eq $true) 
    {
        while ($reader.Read()) 
        {
            $messageText = $reader["MessageText"]

            if ($reader["Level"] -gt 10) 
                { Write-Host $messageText -backgroundcolor Yellow -foregroundcolor Red  } 
            else 
                { Write-Host $messageText  }
        }

        $reader.Close()
    }

    $masterConn.Close() 
}




[void][reflection.assembly]::LoadWithPartialName("System.Data.SqlClient")

$servers = @(Get-Content ".\servers.txt")

$servers | %{
    Execute-DBCC $_
}