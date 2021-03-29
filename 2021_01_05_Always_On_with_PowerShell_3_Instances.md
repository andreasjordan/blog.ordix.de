# Microsoft SQL Server: Setting Up an Always On Availability Group with PowerShell

Author: Andreas Jordan (anj@ordix.de)

Published at: https://blog.ordix.de/microsoft-sql-server-setting-up-an-always-on-availability-group-with-powershell-part-3


## Part 3: The Microsoft SQL Server Instances

In this series of articles I would like to show how an Always On availability group can be set up quickly and comfortably with PowerShell.  
In the [first part](2020_12_30_Always_On_with_PowerShell_1_Environment.md) we first dealt with setting up an appropriate environment, in the [second part](2020_12_31_Always_On_with_PowerShell_2_Failovercluster.md) we set up the Windows failover cluster, now we want to install the SQL Server instances.

Besides the PowerShell module [SqlServer](https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module) provided by Microsoft, the PowerShell module [dbatools](https://dbatools.io/) developed by a large number of authors has become established - which I will use in the following.

We work again in an administrative PowerShell on the client WIN10, as already mentioned in the last part I recommend the "Windows PowerShell ISE".  


### Setup of the PowerShell session

As in the last part, we will first fill a number of variables. In addition to the configuration of the cluster from the previous part, we now also set the names and passwords of the required accounts as well as various paths:

	$DomainName = 'COMPANY'
	$DomainController = 'DOM1'
	$ClusterNodes = 'SRV1', 'SRV2'
	$SqlInstances = 'SRV1', 'SRV2'
	$ClusterName = 'SQLCluster'
	$ClusterIP = '192.168.3.70'
	$SQLServerServiceAccount = 'SQLServer'
	$Password = 'P@ssw0rd'
	$SQLServerSourcesPath = '\\WIN10\SQLServerSources'
	$SQLServerPatchesPath = '\\WIN10\SQLServerPatches'
	$BackupPath = '\\WIN10\SQLServerBackups'
	$DatabaseName = 'AdventureWorks'

A note about the two variables $ClusterNodes and $SqlInstances, which do not differ in our environment: The distinction here is mainly to make clear whether we are connecting to the cluster nodes or the SQL Server instances running on them. If you want to install named instances instead of the default ones, you need to adjust $SqlInstances and use the form "SERVERNAME\INSTANCENAME".

Furthermore, we need two credential objects with credentials, i.e. user-password combinations. In our demo environment, the password is predefined and not worth protecting, so these objects are constructed as follows:

	$AdministratorCredential = New-Object -TypeName PSCredential -ArgumentList "$DomainName\Administrator", (ConvertTo-SecureString -String $Password -AsPlainText -Force)
	$SQLServerCredential = New-Object -TypeName PSCredential -ArgumentList "$DomainName\$SQLServerServiceAccount", (ConvertTo-SecureString -String $Password -AsPlainText -Force)

In a productive deployment, this information can be queried by the user at runtime so that the password is not stored in a file or visible on the screen at any time:

	$AdministratorCredential = Get-Credential -UserName "$DomainName\Administrator" -Message 'Bitte Anmeldeinformationen des Domänenadministrators angeben' 
	$SQLServerCredential = Get-Credential -UserName "$DomainName\$SQLServerServiceAccount" -Message 'Bitte Anmeldeinformationen des SQL Server Dienstekontos angeben' 


### Setup of the Active Directory

The SQL Server instances need a domain account for the services, we use the same account for both services and already assign the necessary rights to the backup share at this point:

	New-ADUser -Name $SQLServerServiceAccount -AccountPassword $SQLServerCredential.Password -PasswordNeverExpires:$true -Enabled:$true
	Grant-SmbShareAccess -Name SQLServerBackups -AccountName "$DomainName\$SQLServerServiceAccount" -AccessRight Full -Force | Out-Null


### Installation of the PowerShell module dbatools

First, we set up PowerShell so that the installation of PowerShell modules can take place without any prompting:

	Install-PackageProvider -Name Nuget -Force | Out-Null
	Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

And then install the module:

	Install-Module -Name dbatools

The developers recommend explicitly loading the module before using it for the first time. Although this is no longer necessary in current PowerShell versions, problems with the module can be detected at a very early stage:

	Import-Module -Name dbatools


### Configuration of the servers for high performance

This step is not necessary, but should be performed on every system. Because Windows Server systems also initially run in the "Balanced" energy-saving plan and should of course be set to "High Performance". There is also a suitable commandlet for this in the dbatools module:

	Set-DbaPowerPlan -ComputerName $ClusterNodes | Format-Table


### Installation and configuration of SQL Server instances

For the installation, the dbatools module provides the Install-DbaInstance commandlet, which we can use to install an SQL Server instance on both nodes simultaneously and with identical configuration. Compared to other script variants, we also have the advantage here that the password is not in plain text in the script at this point, but is securely packaged in the credential object.

	$InstallResult = Install-DbaInstance -SqlInstance $ClusterNodes -Version 2017 -Feature Engine `
    	-EngineCredential $SQLServerCredential -AgentCredential $SQLServerCredential -AdminAccount "$DomainName\Administrator" `
    	-Path $SQLServerSourcesPath -UpdateSourcePath $SQLServerPatchesPath -Authentication Credssp -Credential $AdministratorCredential -Confirm:$false
	$InstallResult | Format-Table

The following rework is again not necessary, but I would like to show you how you can make typical settings of the instances with the help of dbatools. More information about the individual commandlets can be found in the [Documentation](https://dbatools.io/commands/) of dbatools.

	Set-DbaPrivilege -ComputerName $ClusterNodes -Type IFI 
	Set-DbaMaxMemory -SqlInstance $SqlInstances -Max 2048 | Format-Table
	Set-DbaMaxDop -SqlInstance $SqlInstances | Format-Table
	Set-DbaSpConfigure -SqlInstance $SqlInstances -Name CostThresholdForParallelism -Value 50 | Format-Table


### Setting up the sample database

In order to have a database for our availability group, we restore the AdventureWorks database from the backup on the first node. We also configure the recovery model, since only databases in the "Full" recovery model can be included in an availability group.

	Restore-DbaDatabase -SqlInstance $SqlInstances[0] -Path "$BackupPath\AdventureWorks2017.bak" -DatabaseName $DatabaseName | Out-Null
	$Database = Get-DbaDatabase -SqlInstance $SqlInstances[0] -Database $DatabaseName
	$Database.RecoveryModel = 'Full'
	$Database.Alter()

With that, our SQL Server instances are also ready to go and we move on to [part four](2021_01_07_Always_On_with_PowerShell_4_Availability_group.md) and setting up the availability group.
