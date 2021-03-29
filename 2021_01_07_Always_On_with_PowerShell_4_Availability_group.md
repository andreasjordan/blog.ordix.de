# Microsoft SQL Server: Setting Up an Always On Availability Group with PowerShell

Author: Andreas Jordan (anj@ordix.de)

Published at: https://blog.ordix.de/microsoft-sql-server-setting-up-an-always-on-availability-group-with-powershell-part-4


## Part 4: The Always On Availability Group

In this series of articles I would like to show how an Always On availability group can be set up quickly and comfortably with PowerShell.  
In the [first part](2020_12_30_Always_On_with_PowerShell_1_Environment.md) we first dealt with setting up an appropriate environment, in the [second part](2020_12_31_Always_On_with_PowerShell_2_Failovercluster.md) we set up the Windows failover cluster, in the [third part](2021_01_05_Always_On_with_PowerShell_3_Instances.md) the SQL Server instances and the sample database, now we finally want to set up the availability group.

We work again in an administrative PowerShell on the client WIN10, as already mentioned in the last part I recommend the "Windows PowerShell ISE". 


### Setup of the PowerShell session

As in the previous parts, we will first fill a number of variables. We will now add the name of the availability group and the IP of the listener:

	$DomainName = 'COMPANY'
	$DomainController = 'DOM1'
	$ClusterNodes = 'SRV1', 'SRV2'
	$SqlInstances = 'SRV1', 'SRV2'
	$SQLServerServiceAccount = 'SQLServer'
	$Password = 'P@ssw0rd'
	$BackupPath = '\\WIN10\SQLServerBackups'
	$DatabaseName = 'AdventureWorks'
	$AvailabilityGroupName = 'AdventureSQL'
	$AvailabilityGroupIP = '192.168.3.71'
	

### Setup of the services

First, the two SQL Server instances or the services of the instances have to be configured for the use of Always On. This can be done either via the GUI of the SQL Server Configuration Manager or via PowerShell with the module dbatools, which we have already used to install and configure the instances: 

	Import-Module -Name dbatools
	Enable-DbaAgHadr -SqlInstance $SqlInstances -Force | Format-Table

The instances must be restarted to implement the change, the PowerShell commandlet does this automatically.


###  Setup of the Extended Event Sessions

For monitoring Always On, a corresponding Extended Event Session is already set up in the SQL Server. This only needs to be configured and started for automatic startup:

	Get-DbaXESession -SqlInstance $SqlInstances -Session AlwaysOn_health | ForEach-Object -Process { $_.AutoStart = $true ; $_.Alter() ; $_ | Start-DbaXESession } | Format-Table

The availability group creation wizard configures the session accordingly. Perhaps in the future this will also be done by the New-DbaAvailabilityGroup commandlet, which we will use later to create the availability group. I have already made a corresponding [feature request](https://github.com/sqlcollaborative/dbatools/issues/6603).


### Setup of the endpoints

For communication between the two instances, i.e. mainly for transferring all changes from the primary to the secondary database, an endpoint is set up on both instances and the service account is authorized on it:
   
	New-DbaEndpoint -SqlInstance $SqlInstances -Name hadr_endpoint -Port 5022 | Start-DbaEndpoint | Format-Table
	New-DbaLogin -SqlInstance $SqlInstances -Login "$DomainName\$SQLServerServiceAccount" | Format-Table
	Invoke-DbaQuery -SqlInstance $SqlInstances -Query "GRANT CONNECT ON ENDPOINT::hadr_endpoint TO [$DomainName\$SQLServerServiceAccount]"

These steps must be performed only if the New-DbaAvailabilityGroup commandlet is not used later. However, they must also be used if the endpoint is to be created on a port other than 5022. This may be necessary, for example, if there are several instances on the server where Always On is to be used.


### Transferring the database to the second node

I like to separate the transfer of the database from the primary to the secondary server from the creation of the availability group, because the first part can take longer or even be done in several steps, depending on the size of the database. For our example database, creating and restoring a full backup and a transaction log backup is enough:  
 
	$Database = Get-DbaDatabase -SqlInstance $SqlInstances[0] -Database $DatabaseName
	$Database | Backup-DbaDatabase -Path $BackupPath -Type Database | Restore-DbaDatabase -SqlInstance $SqlInstances[1] -NoRecovery | Out-Null
	$Database | Backup-DbaDatabase -Path $BackupPath -Type Log | Restore-DbaDatabase -SqlInstance $SqlInstances[1] -Continue -NoRecovery | Out-Null


### Create the availability group

The database on the secondary node is now in the "Restoring" state and is almost as up-to-date as the database on the primary node. In this state, the availability group can now be created and the database included in it. I am using [automatic seeding](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/automatic-seeding-secondary-replicas) here because I already transferred the database to the secondary node in the previous step. If I use this mode without having transferred the database before, the transfer will happen automatically when the availability group is created. If the SeedingMode parameter is not specified, the manual mode is used. It is then necessary to specify a common path through which the database will be transferred by backup and restore. In principle, the commandlet then performs exactly the steps I mentioned in the previous chapter.

By specifying the IP address, a listener for the availability group is also created at the same time.

You can then use Get-DbaAgReplica and Get-DbaAgDatabase to view the state of the availability group and database to make sure everything is in order.

	$AvailabilityGroup = New-DbaAvailabilityGroup `
		-Name $AvailabilityGroupName `
		-Database $DatabaseName `
    	-ClusterType Wsfc `
    	-Primary $SqlInstances[0] `
    	-Secondary $SqlInstances[1] `
    	-SeedingMode Automatic `
        -IPAddress $AvailabilityGroupIP `
    	-Confirm:$false
	$AvailabilityGroup | Format-List

	Get-DbaAgReplica -SqlInstance $SqlInstances[0] -AvailabilityGroup $AvailabilityGroupName | Format-Table
	Get-DbaAgDatabase -SqlInstance $SqlInstances -AvailabilityGroup $AvailabilityGroupName -Database $DatabaseName | Format-Table


About the commandlet New-DbaAvailabilityGroup some further options can be set, I leave it here however with the default settings. So as [availability mode](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/availability-modes-always-on-availability-groups) the synchronous mode is selected, so that an automatic [failover](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/failover-and-failover-modes-always-on-availability-groups) is possible.

This sets up the availability group and marks the (temporary) end of this article series.
