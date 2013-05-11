<#
.SYNOPSIS
Exports hard disk information to HTML

.DESCRIPTION

.PARAMETER ComputerName

.PARAMETER Path

.EXAMPLE

#>
Function Export-DiskInfo
{
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, HelpMessage='You must specify a ComputerName')]
        [string[]] $ComputerName
        ,
        
        [Parameter(Mandatory=$True, HelpMessage='')]
        [string] $Path = "C:\PD\2013\Scripting Games\3"
    )

    Begin {
        if(!(Test-Path $Path)) {
            $exception = New-Object System.IO.DirectoryNotFoundException "Directory '$Path' doesn't exist"
            $errorID = 'DirectoryNotFound'
            $category = [Management.Automation.ErrorCategory]::ObjectNotFound
            $target = $Path
            $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $category, $target
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    Process {
        foreach ($computer in $ComputerName) {
            
            Write-Verbose "Perform operation 'Ping Computer' with following parameters: ''computerName' = $ComputerName"
            $reachable = Test-Connection $ComputerName -Count 1 -Quiet
            Write-Verbose "Operation 'Ping Computer' complete"

            if(!$reachable) {
                $exception = New-Object System.IO.DirectoryNotFoundException "Target machine '$computer' cannot be reached"
                $errorID = 'DirectoryNotFound'
                $category = [Management.Automation.ErrorCategory]::ObjectNotFound
                $target = $computer
                $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $category, $target
                Write-Error $errorRecord
                continue
            }

            Write-Verbose "Perform operation 'Establish CIM Session' with following parameters, ''ComputerName' = $ComputerName"
            $sessionOption = New-CimSessionOption –Protocol DCOM
            $session = New-CimSession -ComputerName $computerName -SessionOption $sessionOption 
            Write-Verbose "Operation 'Establish CIM Session' complete"

            $title = "Disk Free Space Report"
            $heading = "<h2>Local Fixed Disk Report - $ComputerName</h2>"
            $footer = "<hr/>$(Get-Date)"
            $outFile = Join-Path $Path "$ComputerName.html"

            $diskInfo = Get-CimInstance -CimSession $session -Class CIM_LogicalDisk | 
            foreach {
                $properties = @{
                    "Drive" = $PSItem.DeviceId
                    "Size (GB)" = "{0:N2}" -f ($PSItem.Size / 1GB)
                    "Free Space (MB)" = "{0:N2}" -f ($PSItem.FreeSpace / 1MB)
                }

                New-Object –TypeName PSObject –Property $properties
            }

            $diskInfo |
            ConvertTo-Html -Title $title -PreContent $heading -PostContent $footer | 
            Set-Content $outFile
        }
    }
}


Function Create-ErrorRecord
{
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $ExceptionName,

        [Parameter(Mandatory=$True, Position=1)]
        [string] $Message,
        
        [Parameter(Mandatory=$True, Position=2)]
        [Management.Automation.ErrorCategory] $Category,

        [Parameter(Mandatory=$True, Position=3)]
        [object] $Target
    )

    $exception = New-Object DirectoryNotFoundException $Message
    $errorID = 'DirectoryNotFound'
    $errorCategory = [Management.Automation.ErrorCategory]::ObjectNotFound
    $target = $Path
    $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $errorCategory, $target
}