param
(
    [Parameter (Mandatory=$true)]
    [string] $SubscriptionId,

    [Parameter (Mandatory=$false)]
    [string] $TenantId
)


if(Get-AzContext)
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
    TemplateFile = '.\azuredeploy.json'
    TemplateParameterFile = '.\azuredeploy.parameters.json'
    OutVariable = 'firstDeployment'
    Verbose = $true
    ErrorAction = 'Stop'
}
New-AzDeployment @firstDeploymentParams
