<#
 
.SYNOPSIS
This gets CPU and OS information about a machine
 
.DESCRIPTION

 
.EXAMPLE
'COMPUTER1', 'localhost', 'SERVER1' | Get-MachineInfo


'COMPUTER1', 'localhost', 'SERVER1' | Get-MachineInfo -Path Output.csv
 
.NOTES
Cannot reliably get NumberOfLogicalProcessors or NumberOfCores http://support.microsoft.com/kb/932370 
 
.LINK
 
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
            Write-Error "Error Connecting to $ComputerName $_.Message"
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
            Write-Error "ERROR: $($_.Exception.Message)"
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