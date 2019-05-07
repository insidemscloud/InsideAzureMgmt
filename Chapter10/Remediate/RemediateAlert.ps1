param
(
    [Parameter (Mandatory=$false)]
    [object] $WebhookData
)

$ErrorActionPreference = "Stop"

#region Load functions
Function ConvertFrom-LogAnalyticsSearchResult
{

    [CmdletBinding()]
    [OutputType([Object])]
    Param (
        [parameter(Mandatory=$true)]
        [psobject]$SearchResults
    )

    $data = $SearchResults
    $count = 0
    foreach ($table in $data.Tables)
    {
        $count += $table.Rows.Count
    }

    $objectView = New-Object object[] $count
    $i = 0;
    foreach ($table in $data.Tables)
    {
        foreach ($row in $table.Rows)
        {
            # Create a dictionary of properties
            $properties = @{}
            for ($columnNum=0; $columnNum -lt $table.Columns.Count; $columnNum++)
            {
                $properties[$table.Columns[$columnNum].name] = $row[$columnNum]
            }
            # Then create a PSObject from it. This seems to be *much* faster than using Add-Member
            $objectView[$i] = (New-Object PSObject -Property $properties)
            $null = $i++
        }
    }

    $objectView
}
#endregion

if ($WebhookData)
{
    # Convert webhook request body to PS object
    $webhookBody = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)

    # Get the type of alert and its schema
    $schemaId = $WebhookBody.schemaId
    Write-Output "schemaId: $schemaId"

    if ($schemaId -eq "AzureMonitorMetricAlert")
    {
        # This is the near-real-time Metric Alert schema
        Write-Error "The alert data schema - $schemaId - is not supported."
    }
    elseif ($schemaId -eq "Microsoft.Insights/activityLogs")
    {
        # This is the Activity Log Alert schema
        Write-Error "The alert data schema - $schemaId - is not supported."
    }
    elseif ($schemaId -eq $null)
    {
        # This is the original Metric Alert schema
        Write-Error "The alert data schema - $schemaId - is not supported."
    }
    elseif ($schemaId -eq "unknown")
    {
        # This is the Log Analytics Search Schema
        $alertName = $webhookBody.data.AlertRuleName
    }
    else {
        # The schema isn't supported.
        Write-Error "The alert data schema - $schemaId - is not supported."
    }

    if($alertName -eq "Windows Service Stopped")
    {
        $queryResult = ConvertFrom-LogAnalyticsSearchResult $webhookBody.data.SearchResult
        if($queryResult._ResourceId)
        {
            $svcDisplayName = $queryResult.SvcDisplayName
            $resourceInformation = $queryResult._ResourceId -split '/'
            $subscriptionId = $resourceInformation[2]
            $resourceGroup = $resourceInformation[4]
            $vmName = $resourceInformation[8]

            Write-Output "Service $svcDisplayName on VM $vmName in resource group $resourceGroup has stopped."

            # Authenticate to Azure
            Write-Output "Authenticating to Azure with service principal and certificate"
            $connectionAssetName = "AzureRunAsConnection"
            $conn = Get-AutomationConnection -Name $connectionAssetName

            if ($conn -eq $null)
            {
                throw "Could not retrieve connection asset: $connectionAssetName. Check that this asset exists in the Automation account."
            }

            Connect-AzAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationId $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint | Out-null

            Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop

            # Create Temporary Script File
            $todayDate = Get-Date -Format  yy-MM-dd-HH-mm-ss
            $tempFileName = "$vmName-$svcDisplayName-$todaydate.ps1"
            $tempFile = New-Item -ItemType File -Name $tempFileName
            "Start-Service -DisplayName '$svcDisplayName' -Verbose -ErrorAction Stop" | Out-File -FilePath $tempFile -Append

            # Start the service with Run Command for Azure VMs
            Write-Output "Invoking command to start the service"
            $commandOutput = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $vmName -CommandId 'RunPowerShellScript' -ScriptPath $tempFile -ErrorAction Stop
            $commandOutput.Status
            $commandOutput.Value[0]

        }
        else
        {
            $computerName = $queryResult.Computer
            Write-Error "Computer $computerName is not Azure VM. Only Azure VMs are supported."
        }


    }
    else
    {
        Write-Error "The alert rule with name - $alertName - is not supported."
    }

}
else
{
    # Error
    Write-Error "This runbook is meant to be started from an Azure alert webhook only."
}
