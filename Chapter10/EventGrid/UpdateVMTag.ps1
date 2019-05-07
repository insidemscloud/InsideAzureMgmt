Param(
    [parameter (Mandatory=$false)]
    [object] $WebhookData
)

$ErrorActionPreference = "Stop"

$requestBody = $WebhookData.RequestBody | ConvertFrom-Json
$data = $requestBody.data

if($requestBody.eventType -eq 'Microsoft.EventGrid.SubscriptionValidationEvent')
{
    # Validate webhook
    Invoke-WebRequest -UseBasicParsing -Uri $data.validationUrl -Method Get
}
else
{
    $servicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"

    if($data.claims.appid -ne $servicePrincipalConnection.ApplicationId)
    {
        Write-Output "Logging to Azure."
        Add-AzAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null

        # Set subscription to work against
        Set-AzContext -SubscriptionID $servicePrincipalConnection.SubscriptionId

        # Set tags names
        $tagName = "LastModifiedDate"
        $tagValue   = $requestBody.eventTime

        # Check if tag name exists in subscription and create if needed.
        $TagExists = Get-AzTag -Name $TagName -ErrorAction SilentlyContinue
        if ([string]::IsNullOrEmpty($TagExists))
        {
            New-AzTag -Name $TagName | Out-Null
        }

        # Get resource group and vm name
        $resources = $data.resourceUri.Split('/')
        $vmResourceGroup = $resources[4]
        $vmName = $resources[8]

        # Check if this VM already has the tag set.
        $vm = Get-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName
        $vm.Tags.Remove($tagName) | Out-Null
        $tag = @{"$tagName"=$tagValue }
        $allTags = $vm.Tags + $tag
        # Add tag to VM
        Write-Output "Adding LastModifiedDate tag to VM $($vm.Name) in resource group $vmResourceGroup."
        Update-AzVM -ResourceGroupName $vmResourceGroup -VM $vm -Tag $allTags | Out-Null
    }
    else
    {
        Write-Output "Change is made by Automation Account Service Principal so no changes will be made to the VM."
    }


}
