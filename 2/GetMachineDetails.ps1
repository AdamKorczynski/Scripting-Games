<#
 
.SYNOPSIS
Gets CPU, memory and operating system information about a machine
 
.DESCRIPTION
This will try to get operating system, memory and CPU information from a machine. It uses CIM over DCOM to communicate with the remote machine. Before attempting to retrive information, the target machine will 
be pinged once to ensure it is available. A CIM session is esablished to reduce connection overhead. 
The information returned is limited to statistics which are accurate accross all versions of Windows from Server 2000 onward. This means only the number of physical processors can be retrieved.
The output can be exported to CSV or displayed as a table to the host.

.PARAMETER ComputerName
The name of the computer which will be queries for information. This can be a local machine or accross the network. It must run Windows 2000 or higher
 
.PARAMETER Path
The destination csv location. If this is provided the resultant mahine information will be saved the CSV. Otherwise it will be directed to the host.

.EXAMPLE
'COMPUTER1', 'localhost', 'SERVER1' | Get-MachineInfo
This queries three computers and outputs to the screen

'COMPUTER1', 'localhost', 'SERVER1' | Get-MachineInfo -Path Output.csv
This queries three computers and outputs to a CSV
 
.LINK
http://support.microsoft.com/kb/932370 
#>
Function Get-MachineInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [string] $ComputerName,

        [Parameter(Mandatory=$False)]
        [string] $Path
    )

    begin {
        $MB = 1024 * 1024
        $GB = $MB * 1024
        $rows = @()

        if($Path.Length -gt 0)
        {
            $dir = Split-Path $Path
            if($dir.Length -gt 0)
            {
                if(-not (Test-Path $dir))
                {
                    Write-Error "Directory '$dir' doesn't exist"
                }
            }
        }

        $ErrorActionPreference = "Stop"
    }
    
    process {

        try
        {
            Write-Verbose "Perform operation 'Ping Computer' with following parameters, ''computerName' = $ComputerName"
            Test-Connection $ComputerName -Count 1 | Out-Null
            Write-Verbose "Operation 'Ping Computer' complete"

        }
        catch
        {
            Write-Error "Error Connecting to '$ComputerName' $_.Message"
            return
        }

        try
        {
            Write-Verbose "Perform operation 'Establish CIM Session' with following parameters, ''ComputerName' = $ComputerName, 'protocol' = DCOM"
            $sessionOption = New-CimSessionOption –Protocol DCOM
            $session = New-CImSession -ComputerName $computerName -SessionOption $sessionOption 
            Write-Verbose "Operation 'Establish CIM Session' complete"

        }
        catch
        {
            Write-Error "Error establishing CIM session $($_.Exception.Message)"
            return
        }

        Write-Verbose "Perform operation 'Retrieve system data'"
        $os = Get-CimInstance -CimSession $session -Class CIM_OperatingSystem | 
        select Caption, Version, CSDVersion

        $csInfo = Get-CimInstance -CimSession $session -Class CIM_ComputerSystem | 
        select TotalPhysicalMemory, NumberOfProcessors
        Write-Verbose "Operation 'Retrieve system data' complete"


        if($csInfo.TotalPhysicalMemory / $GB -gt 0) {
            $Memory = "{0:N0} GB" -f ($csInfo.TotalPhysicalMemory / $GB)
        }
        else {
            $Memory = "{0:N0} MB" -f ($csInfo.TotalPhysicalMemory / $MB)
        }

        $properties = @{
            'OSName'= "$($os.Caption) $($os.CSDVersion)"
            'OSVersion' = $os.Version
            'Memory'= $Memory
            'Processors' = $csInfo.NumberOfProcessors 
        }
        
        $rows += New-Object –TypeName PSObject –Property $properties
    }

    end {

        Write-Verbose "$($rows.Length) device(s) found"

        if($Path.Length -gt 0)
        {
                Write-Verbose "Writing output to $Path"
                $rows | Export-Csv $Path -NoTypeInformation
        }
        else
        {
            $rows | Format-Table
        }

    }
}