using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host 'PowerShell HTTP trigger function processed a request.'

if ($Request.Body -ne $null)
{
    if ($Request.Body.schemaId -eq 'azureMonitorCommonAlertSchema')
    {
        Write-Output -InputObject "Schema ID: '$($Request.Body.schemaId)'."
        if ($Request.Body.data.essentials.monitoringService -eq 'Log Analytics')
        {
            # Log Analytics alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."

            if ($Request.Body.data.essentials.alertRule -eq 'Windows Service Stopped')
            {
                Write-Output -InputObject "Alert Name: '$($Request.Body.data.essentials.alertRule)'."
                try
                {
                    # Reformatting results
                    $results = ConvertFrom-Json ($Request.Body.data.alertContext.SearchResults | ConvertTo-json -Depth 10)
                    $queryResult = ConvertFrom-LogAnalyticsSearchResult -SearchResults $results
                    Write-Output -InputObject "Formatted query results: $($queryResult)."
                    if ($queryResult._ResourceId)
                    {
                        Write-Output -InputObject "Resource ID: '$($queryResult._ResourceId)'."
                        $svcDisplayName = $queryResult.SvcDisplayName
                        $resourceInformation = $queryResult._ResourceId -split '/'
                        $subscriptionId = $resourceInformation[2]
                        $resourceGroup = $resourceInformation[4]
                        $vmName = $resourceInformation[8]

                        Write-Output "Service '$($svcDisplayName)' on VM '$($vmName)' in resource group '$($resourceGroup)' has stopped."
                        Set-AzContext -SubscriptionId $subscriptionId
                        # Create Temporary Script File
                        $todayDate = Get-Date -Format yy-MM-dd-HH-mm-ss
                        $parent = [System.IO.Path]::GetTempPath()
                        $tempFileName = "$vmName-$svcDisplayName-$todayDate.ps1"
                        $tempFile = New-Item -ItemType File -Path (Join-Path $parent $tempFileName)
                        "Start-Service -DisplayName '$svcDisplayName' -Verbose -ErrorAction Stop" | Out-File -FilePath $tempFile -Append
                        # Start the service with Run Command for Azure VMs
                        Write-Output -InputObject 'Invoking command to start the service...'
                        $commandOutput = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $vmName -CommandId 'RunPowerShellScript' -ScriptPath $tempFile
                        $body += "Status: '$($commandOutput.Status)'. "
                        $body += "Output Message: '$($commandOutput.Value[0].Message)'."
                        Write-Output -InputObject $body
                        $status = [HttpStatusCode]::OK
                    }
                    else
                    {
                        Write-Output -InputObject "Computer Name: '$($queryResult.Computer)'."
                        Write-Error -Message "Computer '$($queryResult.Computer)' is not Azure VM. Only Azure VMs are supported." -ErrorAction Continue
                        $body = "Computer '$($queryResult.Computer)' is not Azure VM. Only Azure VMs are supported."
                        $status = [HttpStatusCode]::InternalServerError
                    }
                }
                catch
                {
                    Write-Error -Message $_.Exception.Message -ErrorAction Continue
                    $body = $_.Exception.Message
                    $status = [HttpStatusCode]::InternalServerError
                }
            }
            else
            {
                Write-Output -InputObject "Alert Name: '$($Request.Body.data.essentials.alertRule)'."
                Write-Error -Message "Unknown alert name: '$($Request.Body.data.essentials.alertRule)'." -ErrorAction Continue
                $body = "Unknown alert name: '$($Request.Body.data.essentials.alertRule)'."
                $status = [HttpStatusCode]::InternalServerError
            }
        }
        elseif ($Request.Body.data.essentials.monitoringService -eq 'Platform')
        {
            # Metric Alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::OK
            $body = $Request.Body.data.essentials.monitoringService
        }
        elseif ($Request.Body.data.essentials.monitoringService -eq 'Application Insights')
        {
            # Application Insights Alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::OK
            $body = $Request.Body.data.essentials.monitoringService
        }
        elseif ($Request.Body.data.essentials.monitoringService -eq 'Activity Log - Administrative')
        {
            # Activity Log - Administrative Alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::OK
            $body = $Request.Body.data.essentials.monitoringService
        }
        elseif ($Request.Body.data.essentials.monitoringService -eq 'Activity Log - Policy')
        {
            # Activity Log - Policy Alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::OK
            $body = $Request.Body.data.essentials.monitoringService
        }
        elseif ($Request.Body.data.essentials.monitoringService -eq 'Activity Log - Autoscale')
        {
            # Activity Log - Autoscale Alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::OK
            $body = $Request.Body.data.essentials.monitoringService
        }
        elseif ($Request.Body.data.essentials.monitoringService -eq 'Activity Log - Security')
        {
            # Activity Log - Security Alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::OK
            $body = $Request.Body.data.essentials.monitoringService
        }
        elseif ($Request.Body.data.essentials.monitoringService -eq 'ServiceHealth')
        {
            # Service Health Alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::OK
            $body = $Request.Body.data.essentials.monitoringService
        }
        elseif ($Request.Body.data.essentials.monitoringService -eq 'Resource Health')
        {
            # Resource Health Alert
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::OK
            $body = $Request.Body.data.essentials.monitoringService
        }
        else
        {
            Write-Output -InputObject "Alert Type: '$($Request.Body.data.essentials.monitoringService)'."
            Write-Error -Message "Unknown Monitoring alert type: '$($Request.Body.data.essentials.monitoringService)'." -ErrorAction Continue
            $body = "Unknown Monitoring alert type: '$($Request.Body.data.essentials.monitoringService)'."
            $status = [HttpStatusCode]::InternalServerError
        }
    }
    else
    {
        Write-Output -InputObject "Schema ID: '$($Request.Body.schemaId)'."
        Write-Error -Message 'Common alert schema is not used.' -ErrorAction Continue
        $body = 'Common alert schema is not used.'
        $status = [HttpStatusCode]::InternalServerError
    }
}
else
{
    Write-Output -InputObject "Body: $($Request.Body)"
    Write-Error -Message 'No body was passed when executing the function.' -ErrorAction Continue
    $body = 'No body was passed when executing the function.'
    $status = [HttpStatusCode]::InternalServerError
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
