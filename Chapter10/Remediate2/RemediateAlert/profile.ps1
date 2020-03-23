# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.
if ($env:MSI_SECRET -and (Get-Module -ListAvailable Az.Accounts)) {
    Connect-AzAccount -Identity
}

$ErrorActionPreference = "Stop"

#region Load functions
Function ConvertFrom-LogAnalyticsSearchResult
{

    [CmdletBinding()]
    [OutputType([Object])]
    Param (
        [parameter(Mandatory=$true)]
        [object]$SearchResults
    )

    try
    {
        $data = $SearchResults
        $count = 0
        foreach ($table in $data.tables)
        {
            $count += $table.rows.Count
        }

        $objectView = New-Object object[] $count
        $i = 0;
        foreach ($table in $data.tables)
        {
            foreach ($row in $table.rows)
            {
                # Create a dictionary of properties
                $properties = @{}
                for ($columnNum=0; $columnNum -lt $table.Columns.Count; $columnNum++)
                {
                    $properties[$table.columns[$columnNum].name] = $row[$columnNum]
                }
                # Then create a PSObject from it. This seems to be *much* faster than using Add-Member
                $objectView[$i] = (New-Object PSObject -Property $properties)
                $null = $i++
            }
        }
    }
    catch
    {
        throw $error[0]
    }


    return $objectView
}
#endregion

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.
