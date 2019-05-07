param
(
    [Parameter (Mandatory=$true)]
    [string] $SubscriptionId,

    [Parameter (Mandatory=$false)]
    [string] $TenantId
)


if(Get-AzContext | Where-Object {$_.Subscription.Id -eq $SubscriptionId})
{
    $selectSubscriptionParams = @{
        SubscriptionId = $SubscriptionId
        ErrorAction = 'Stop'
    }
    if($TenantId)
    {
        $selectSubscriptionParams.Add('TenantId', $TenantId)
    }
    Select-AzSubscription @selectSubscriptionParams
}
else
{
    Connect-AzAccount -ErrorAction Stop

    $selectSubscriptionParams = @{
        SubscriptionId = $SubscriptionId
        ErrorAction = 'Stop'
    }
    if($TenantId)
    {
        $selectSubscriptionParams.Add('TenantId', $TenantId)
    }

    Select-AzSubscription @selectSubscriptionParams
}

$firstDeploymentParams = @{
    Name = 'azDeploy-' + ((Get-Date).ToUniversalTime() ).ToString('yyMMdd-HHmm')
    Location = 'West Europe'
    TemplateFile = '.\azuredeploy1.json'
    TemplateParameterFile = '.\azuredeploy.parameters.json'
    OutVariable = 'firstDeployment'
    Verbose = $true
    ErrorAction = 'Stop'
}
New-AzDeployment @firstDeploymentParams

$automationAccountResourceGroup = $firstDeployment.Parameters.resourceGroupName.Value
$automationAccountName = $firstDeployment.Parameters.automationAccountName.Value

try
{
    $getWebhookParams = @{
        Name = $automationAccountName + '/' + 'UpdateVMTag'
        ResourceType = "Microsoft.Automation/automationAccounts/webhooks"
        ResourceGroupName = $automationAccountResourceGroup
        ApiVersion = '2015-10-31'
        ErrorAction = 'Stop'
    }
    Get-AzResource @getWebhookParams | Out-Null
    $webhookUri = ""
}
catch
{
    $validWebhookUriParams = @{
        ResourceGroupName = $automationAccountResourceGroup
        ResourceType = "Microsoft.Automation/automationAccounts/webhooks"
        ResourceName = $automationAccountName
        ApiVersion = '2015-10-31'
        Force = $true
        Action = 'Action'
        ErrorAction = 'Stop'
    }
    $webhookUri = Invoke-AzResourceAction @validWebhookUriParams
}

$secondDeploymentParams = @{
    Name = 'azDeploy-' + ((Get-Date).ToUniversalTime() ).ToString('yyMMdd-HHmm')
    Location = 'West Europe'
    TemplateFile = '.\azuredeploy2.json'
    TemplateParameterFile = '.\azuredeploy.parameters.json'
    OutVariable = 'secondDeployment'
    Verbose = $true
    ErrorAction = 'Stop'
}
if($webhookUri -ne "")
{
    $secondDeploymentParams.Add('webhookUri', (ConvertTo-SecureString $webhookUri -AsPlainText -Force))
}
New-AzDeployment @secondDeploymentParams
