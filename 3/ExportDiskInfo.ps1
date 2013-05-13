<#
.SYNOPSIS
Exports hard disk information to HTML

.DESCRIPTION
Queries a machine, by name, to extract disk drive information and export to an HTML file in the destination directory provided.

.PARAMETER ComputerName
This is the name of the target machine which will be queried.

.PARAMETER Path
This is the destination directory to which the disk info exported. If it does not exist, it will not be created and the export will fail.

.EXAMPLE

@("RemoteMachine1", $env:COMPUTERNAME) | Export-DiskInfo "C:\PD\2013\Scripting Games\3"
reports the disk information of RemoteMachine1 and the machine on which the script is executed. Produces two reports in C:\PD\2013\Scripting Games\3\RemoteMachine1.html and C:\PD\2013\Scripting Games\3\<local machine name>.html

.EXAMPLE

Export-DiskInfo -ComputerName "RemoteMachine1" -Destination "C:\PD\2013\Scripting Games\3" 
Exports disk info for RemoteMachine1 to C:\PD\2013\Scripting Games\3\RemoteMachine1.html

#>
#requires -version 3.0
Function Export-DiskInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $True, 
            ValueFromPipeline = $True, 
            HelpMessage = 'The name of the machine you want to report against')]
        [string[]] 
        $ComputerName,
        
        [Alias("Destination")]
        [Parameter(
            Mandatory = $True, 
            HelpMessage = 'The directory where the HTML files will be created')]
        [string] 
        $Path
    )

    Begin {
        Write-Verbose "Checking for existence of directory '$Path'"
        if(!(Test-Path $Path)) {
            $exception = New-Object System.IO.DirectoryNotFoundException "Directory '$Path' doesn't exist"
            $errorID = 'DirectoryNotFound'
            $category = [Management.Automation.ErrorCategory]::ObjectNotFound
            $target = $Path
            $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $category, $target
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
        Write-Verbose "Checking for existence of directory '$Path' complete"
    }

    Process {
        foreach ($computer in $ComputerName) {
            
            Write-Verbose "Pinging Computer $computer"
            $reachable = Test-Connection $ComputerName -Count 1 -Quiet
            Write-Verbose "Pinging Computer $computer complete"

            if(!$reachable) {
                $exception = New-Object ArgumentException "Target machine '$computer' cannot be reached"
                $errorID = 'RemoteMachineUnavailable'
                $category = [Management.Automation.ErrorCategory]::ConnectionError
                $target = $computer
                $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $category, $target
                Write-Error $errorRecord
                continue
            }

            $title = "Disk Free Space Report"
            $heading = "<h2>Local Fixed Disk Report - $computer</h2>"
            $footer = "<hr/>$(Get-Date)"
            $outFile = Join-Path $Path "$computer.html"

            Write-Verbose "Establish CIM Session with ''ComputerName' = $computer"
            $sessionOption = New-CimSessionOption –Protocol DCOM
            $session = New-CimSession -ComputerName $computer -SessionOption $sessionOption 
            Write-Verbose "Establish CIM Session complete"

            Write-Verbose "Get disk info"
            $diskInfo = Get-CimInstance -CimSession $session -Class CIM_LogicalDisk -Filter "Name like 'p%'" | 
            foreach {
                $properties = @{
                    "Drive" = $PSItem.DeviceId
                    "Size (GB)" = [Math]::Round($PSItem.Size / 1GB, 2)
                    "Free Space (MB)" = [Math]::Round($PSItem.FreeSpace / 1MB, 2)
                }

                New-Object –TypeName PSObject –Property $properties
            }
            Write-Verbose "Get disk info complete, found $($diskInfo.Length) disks"

            Write-Verbose "Writing report to '$outFile'"
            $diskInfo |
            ConvertTo-Html -Title $title -PreContent $heading -PostContent $footer | 
            Set-Content $outFile
            Write-Verbose "Writing report to '$outFile' complete"
        }
    }
}