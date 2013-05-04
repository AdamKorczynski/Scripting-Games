<#
.SYNOPSIS
    Archives log files.
.DESCRIPTION
    Archive-Log movs log files from application-specific subdirectories to a specified destination.
.PARAMETER Destination
    The base directory which is used in conjunction with SubDirectory to determine the 
    destination for the log files.
.PARAMETER Path
    The path to the base directory under which all application directories can be found. This defaults 
    to 'C:\Application\Log'
.PARAMETER SubDirectory
    This corresponds to the name of the application being archived. 
    The directory being archived is a concatenation of the Path and SubDirectory
    The archive destinaton is a concatenation of the Destination and SubDirectory.
.PARAMETER Filter
    This is the pattern used to identify log files by name. By default this looks for a file 
    named as a GUID with a 'log' extension
.EXAMPLE
    C:\PS> ('App1', 'OtherApp') | Archive-Logs 'C:\Scripting Games\1\Output'
    This gets all log files in C:\Application\Log\App1 and C:\Application\Log\OtherApp and 
    moves them to C:\Scripting Games\1\Output\App1 and C:\Scripting Games\1\Output\OtherApp
.NOTES
    Author: AdamK
    Date:   29/04/2013
#>

Function Archive-Logs
{
    [CmdletBinding()]    
    Param (
        [Parameter(Mandatory=$True,Position=1)]
        [string] $Destination,
        
        [Parameter(Mandatory=$False,Position=2)]
        [string] $Path = 'C:\PD\2013\Scripting Games\1\Application\Log',
        
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [string] $SubDirectory,
        
        [Parameter(Mandatory=$False)]
        [string] $Filter = '^[\da-fA-F]{8}-[\da-fA-F]{4}-[\da-fA-F]{4}-[\da-fA-F]{4}-[\da-fA-F]{12}\.log$'
    ) #end param

    begin {
        if(-not (Test-Path $Path))
        {
            throw "Source directory '$Path' could not be found"
        }
    } # end begin

    process {

        $DestDir = Join-Path $Destination $SubDirectory
        $SrcDir = Join-Path $Path $SubDirectory

        Write-Verbose "Archiving $SrcDir"

        if(-not (Test-Path $DestDir)) {
            Write-Verbose "Creating archive directory $DestDir"
            New-Item -Path $DestDir -ItemType "directory" | Out-Null
        }

        Get-ChildItem $SrcDir | where { $_.Name -match $Filter } | 
        foreach {
            Write-Verbose "Copying $($_.FullName) to $DestDir\$($_.Name)"
            Move-Item $_.FullName -Destination "$DestDir\$($_.Name)"
    
        } # end foreach
    } # end process
} # end function Archive-Logs