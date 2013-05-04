Function Get-MachineInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False, ValueFromPipeline=$True)]
        [string] $ComputerName = 'localhost',

        [Parameter(Mandatory=$False)]
        [string] $Path = 'Report.csv'
    )

    begin {
        $MB = 1024 * 1024
        $GB = $MB * 1024
        $rows = @()
    }

    process {

        $sessionOption = New-CimSessionOption –Protocol DCOM
        $session = New-CImSession -ComputerName $computerName -SessionOption $sessionOption

        $procInfo = Get-CimInstance -CimSession $session -Class CIM_Processor | 
        select "NumberOfProcessors", "NumberOfCores"

        $os = Get-CimInstance -CimSession $session -Class CIM_OperatingSystem | 
        select "CSDVersion", "Caption", "OSType", "Version"

        $mem = Get-CimInstance -CimSession $session -Class CIM_ComputerSystem | 
        select -ExpandProperty TotalPhysicalMemory

        if($mem / $GB -gt 0) {
            $mem = "{0:N0} GB" -f ($mem / $GB)
        }
        else {
            $mem = "{0:N0} MB" -f ($mem / $MB)
        }

        $properties = @{
            'Processors'= $procInfo;
            'OS'= $os;
            'Memory'= $mem;
        }

        $rows += New-Object –TypeName PSObject –Prop $properties
    }

    end {
    #output
    }
}