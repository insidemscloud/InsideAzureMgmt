#Specify primary key and workspace Id here. change them to suit your workspace.
$PrimaryKey = "You-Workspace-Primary-Key"
$WorkspaceId = '5663c362-509d-4283-b0e8-c5f755e70db8'

#Inserting individual record
$ObjProperties = @{
  Computer = $env:COMPUTERNAME
  Username = $env:USERNAME
  Message  = 'This is a test message #1 injected for the Inside Azure Management book demo.'
  LogTime  = [Datetime]::UtcNow
}
$DataObject = New-Object -TypeName PSObject -Property $ObjProperties
$IndividualInject = New-OMSDataInjection -OMSWorkSpaceId $WorkspaceId -PrimaryKey $PrimaryKey -LogType 'InsideAzureMgmtBookDemo' -UTCTimeStampField 'LogTime' -OMSDataObject $DataObject

#Batch insert
$arrDataObjects = @()
$ObjProperties1 = @{
  Computer = $env:COMPUTERNAME
  Username = $env:USERNAME
  Message  = 'This is test message #2 injected for the Inside Azure Management book demo.'
  LogTime  = [Datetime]::UtcNow
}
$DataObject1 = New-Object -TypeName PSObject -Property $ObjProperties1
$arrDataObjects += $DataObject1
    
$ObjProperties2 = @{
  Computer = $env:COMPUTERNAME
  Username = $env:USERNAME
  Message  = 'This is test message #3 injected for the Inside Azure Management book demo.'
  LogTime  = [Datetime]::UtcNow
}
$DataObject2 = New-Object -TypeName PSObject -Property $ObjProperties2
$arrDataObjects += $DataObject2
$InjectData = New-OMSDataInjection -OMSWorkSpaceId $WorkspaceId -PrimaryKey $PrimaryKey -LogType 'InsideAzureMgmtBookDemo' -UTCTimeStampField 'LogTime' -OMSDataObject $arrDataObjects