configuration DomainControllerConfig
{

Import-DscResource -ModuleName @{ModuleName = 'xActiveDirectory'; ModuleVersion = '2.17.0.0'}
Import-DscResource -ModuleName @{ModuleName = 'xStorage'; ModuleVersion = '3.4.0.0'}
Import-DscResource -ModuleName @{ModuleName = 'xPendingReboot'; ModuleVersion = '0.3.0.0'}
Import-DscResource -ModuleName @{ModuleName = 'xPSDesiredStateConfiguration'; ModuleVersion = '8.2.0.0'}
Import-DscResource -ModuleName @{ModuleName = 'xTimeZone'; ModuleVersion = '1.8.0.0'}
Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

# When using with Azure Automation, modify these values to match your stored credential names
$domainCredential = Get-AutomationPSCredential 'DomainAdministratorCredentials'
$safeModeCredential = Get-AutomationPSCredential 'SafeModeAdministratorCredentials'

  node localhost
  {
    WindowsFeature ADDSInstall
    {
        Ensure = 'Present'
        Name = 'AD-Domain-Services'
    }

    xWaitforDisk Disk2
    {
        DiskId = 2
        RetryIntervalSec = 10
        RetryCount = 30
    }

    xDisk DiskF
    {
        DiskId = 2
        DriveLetter = 'F'
        DependsOn = '[xWaitforDisk]Disk2'
    }

    xPendingReboot BeforeDC
    {
        Name = 'BeforeDC'
        SkipCcmClientSDK = $true
        DependsOn = '[WindowsFeature]ADDSInstall','[xDisk]DiskF'
    }

    # Configure domain values here
    xADDomain Domain
    {
        DomainName = 'contoso.local'
        DomainAdministratorCredential = $domainCredential
        SafemodeAdministratorPassword = $safeModeCredential
        DatabasePath = 'F:\NTDS'
        LogPath = 'F:\NTDS'
        SysvolPath = 'F:\SYSVOL'
        DependsOn = '[WindowsFeature]ADDSInstall','[xDisk]DiskF','[xPendingReboot]BeforeDC'
    }

    Registry DisableRDPNLA
    {
        Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
        ValueName = 'UserAuthentication'
        ValueData = 0
        ValueType = 'Dword'
        Ensure = 'Present'
        DependsOn = '[xADDomain]Domain'
    }

    xTimeZone SetTimeZone
    {
        IsSingleInstance = 'Yes'
        TimeZone         = 'E. Europe Standard Time'
    }

    xServiceSet DFSReplication
    {
        Name   = @('DFSR')
        Ensure = 'Present'
        State  = 'Running'
    }

    xServiceSet DFSNamespace
    {
        Name   = @('Dfs')
        Ensure = 'Present'
        State  = 'Running'
    }

    xServiceSet IntersiteMessaging
    {
        Name   = @('IsmServ')
        Ensure = 'Present'
        State  = 'Running'
    }

    xServiceSet KerberosKeyDistributionCenter
    {
        Name   = @('Kdc')
        Ensure = 'Present'
        State  = 'Running'
    }

    xServiceSet Netlogon
    {
        Name   = @('Netlogon')
        Ensure = 'Present'
        State  = 'Running'
    }

    xServiceSet ActiveDirectoryDomainServices
    {
        Name   = @('NTDS')
        Ensure = 'Present'
        State  = 'Running'
    }

    xServiceSet WindowsTime
    {
        Name   = @('W32Time')
        Ensure = 'Present'
        State  = 'Running'
    }

    xServiceSet ActiveDirectoryWebServices
    {
        Name   = @('ADWS')
        Ensure = 'Present'
        State  = 'Running'
    }

    xServiceSet HealthService
    {
        Name   = @('HealthService')
        Ensure = 'Present'
        State  = 'Running'
    }
  }
}
