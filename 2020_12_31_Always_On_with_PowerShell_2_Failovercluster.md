# Microsoft SQL Server: Setting Up an Always On Availability Group with PowerShell

Author: Andreas Jordan (anj@ordix.de)

Published at: https://blog.ordix.de/microsoft-sql-server-setting-up-an-always-on-availability-group-with-powershell-part-2


## Part 2: The Windows failover cluster

In this series of articles I would like to show how an Always On availability group can be set up quickly and comfortably with PowerShell.  
In the [first part](2020_12_30_Always_On_with_PowerShell_1_Environment.md) we first dealt with the setup of a corresponding environment, now we want to fill it with life.

For general information on availability groups, I simply refer here to Microsoft's documentation: [What is an Always On availability group](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server).  
Here is just this: We need a Windows failover cluster as a basis, which can be set up with a few PowerShell commands.

In the following, we will work in an administrative PowerShell on the WIN10 client. Whether you use the "Windows PowerShell" or the "Windows PowerShell ISE" is up to you. However, I recommend the ISE (ISE = Integrated Scripting Environment) for such applications, because here all commands remain well in view, individual lines or blocks can be executed comfortably and the script can also be saved for documentation.  


### Setup of the PowerShell session

So that you can use the commands in this article in other environments without adjustments if possible, we will first fill some variables that contain the values suitable for the PSAutoLab environment. For example, we want to form the failover cluster from the two servers SRV1 and SRV2, because they are already members of the domain. The failover cluster should be named SQLCluster and have the IP address 192.168.3.70: 

	$DomainName = 'COMPANY'
	$DomainController = 'DOM1'
	$ClusterNodes = 'SRV1', 'SRV2'
	$ClusterName = 'SQLCluster'
	$ClusterIP = '192.168.3.70'


### Setup of the Active Directory

The two servers for the failover cluster are members of the domain, but they are not in the same organizational unit (OU), which is a [requirement](https://docs.microsoft.com/en-us/windows-server/failover-clustering/create-failover-cluster). Therefore, we move the server SRV2 back to the default container:

	Move-ADObject -Identity 'CN=SRV2,OU=Servers,DC=Company,DC=Pri' -TargetPath 'CN=Computers,DC=Company,DC=Pri'

We need the failover clustering feature on both nodes, which we install with the following command:

	Invoke-Command -ComputerName $ClusterNodes -ScriptBlock { Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools } | Format-Table


At this point a note about `| Format-Table`: This formats the output as a table. I always use this option when several objects are output, here are the two results of the installation. Alternatively, I later use `| Format-List` when only one object is output and all properties are to be output clearly as a list. Feel free to customize the commands to get the output that suits you best. In some commands I also use `| Out-Null` to suppress the output altogether, because I don't think it is relevant. Feel free to change that as well.

The following step is not mandatory, but still recommended. This is because the execution of the validation test provides you with a clear report about possible configuration problems or prerequisites that have not yet been met. It is especially important in production environments, because a positive test is a prerequisite for Microsoft to support the cluster. We start the test and display the result in the browser:

	$ClusterTest = Test-Cluster -Node $ClusterNodes
	&$ClusterTest.FullName

However, the test may contain warnings. For example, in our environment there is only one network connection between the servers and hence this message: "Node srv2.company.pri is reachable from Node srv1.company.pri by only one pair of network interfaces. It is possible that this network path is a single point of failure for communication within the cluster. Please verify that this single path is highly available, or consider adding additional networks to the cluster."


### Creation of the failover cluster

If the validation test was positive, then we can create the failover cluster:

	$Cluster = New-Cluster -Name $ClusterName -Node $ClusterNodes -StaticAddress $ClusterIP
	$Cluster | Format-List

Since we do not have shared storage for the quorum in the environment, we use a network share as the quorum. To do this, we create the network share on the domain controller and authorize the computer account of the failover cluster we just created:

	Invoke-Command -ComputerName $DomainController -ScriptBlock { 
    	New-Item -Path "C:\WindowsClusterQuorum_$using:ClusterName" -ItemType Directory | Out-Null
    	New-SmbShare -Path "C:\WindowsClusterQuorum_$using:ClusterName" -Name "WindowsClusterQuorum_$using:ClusterName" | Out-Null
    	Grant-SmbShareAccess -Name "WindowsClusterQuorum_$using:ClusterName" -AccountName "$using:DomainName\$using:ClusterName$" -AccessRight Full -Force | Out-Null
	}
	$Cluster | Set-ClusterQuorum -NodeAndFileShareMajority "\\$DomainController\WindowsClusterQuorum_$ClusterName" | Format-List

With this, our failover cluster is ready to go and we continue with the [third part](2021_01_05_Always_On_with_PowerShell_3_Instances.md) and the installation of the SQL Server instances.
