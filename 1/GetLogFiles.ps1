Function Archive-Logs
{
    [CmdletBinding()]    
    Param (
        [Parameter(Mandatory=$True,Position=1)]
        [string] $Destination,
        
        [Parameter(Mandatory=$False,Position=2)]
        [string] $Path = 'C:\PD\2013\Scripting Games\1\Application\Log',
        
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [string[]] $SubDirectories,
        
        [Parameter(Mandatory=$False)]
        [string] $Filter = '^[\da-fA-F]{8}-[\da-fA-F]{4}-[\da-fA-F]{4}-[\da-fA-F]{4}-[\da-fA-F]{12}\.log$'
    ) #end param

    if(-not (Test-Path $Path))
    {
        $message = "Source directory '$Path' could not be found"
        throw new-object System.IO.DirectoryNotFoundException($message)
    }

    $SubDirectories | % { "$Destination\$_" }  | where {-not  (Test-Path $_)} | 
    foreach  {
        Write-Verbose "Creating archive directory $_";
        New-Item -Path $_ -ItemType "directory";
    } #end foreach

   
    $files = $SubDirectories | foreach { "$Path\$_" } | Get-ChildItem | where { $_.Name -match $Filter } | 
    foreach {
        Write-Verbose "Copying $($_.FullName) to $Destination\$($_.Directory.Name)\$($_.Name)"
        Copy-Item $_.FullName -Destination "$Destination\$($_.Directory.Name)\$($_.Name)"

        Write-Verbose "Removing $($_.FullName)"
        Remove-Item $_.FullName
    
    } #end foreach
} # end function Archive-Logs