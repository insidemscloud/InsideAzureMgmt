param
(
    [Parameter (Mandatory=$true)]
    [string] $SubscriptionId,

    [Parameter (Mandatory=$false)]
    [string] $TenantId
)


if(Get-AzureRmContext)
{
    $selectSubscriptionParams = @{
        SubscriptionId = $SubscriptionId
        ErrorAction = 'Stop'
    }
    if($TenantId)
    {
        $selectSubscriptionParams.Add('TenantId', $TenantId)
    }
    Select-AzureRmSubscription @selectSubscriptionParams
}
else
{
    Connect-AzureRmAccount -ErrorAction Stop

    $selectSubscriptionParams = @{
        SubscriptionId = $SubscriptionId
        ErrorAction = 'Stop'
    }
    if($TenantId)
    {
        $selectSubscriptionParams.Add('TenantId', $TenantId)
    }

    Select-AzureRmSubscription @selectSubscriptionParams
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
New-AzureRmDeployment @firstDeploymentParams

$automationAccountResourceGroup = $firstDeployment.Parameters.resourceGroupName.Value
$automationAccountName = $firstDeployment.Parameters.automationAccountName.Value

try
{
    $getWebhookParams = @{
        Name = $automationAccountName + '/' + 'UpdateVMTag'
        ResourceType = "Microsoft.Automation/automationAccounts/webhooks"
        ResourceGroupName = $automationAccountResourceGroup
        ApiVersion = '2015-10-31'
        ErrorAction = 'SilentlyContinue'
    }
    Get-AzureRmResource @getWebhookParams | Out-Null
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
    $webhookUri = Invoke-AzureRmResourceAction @validWebhookUriParams
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
New-AzureRmDeployment @secondDeploymentParams
