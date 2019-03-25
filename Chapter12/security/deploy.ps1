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
    TemplateFile = '.\azuredeploy.json'
    TemplateParameterFile = '.\azuredeploy.parameters.json'
    OutVariable = 'firstDeployment'
    Verbose = $true
    ErrorAction = 'Stop'
}
New-AzureRmDeployment @firstDeploymentParams