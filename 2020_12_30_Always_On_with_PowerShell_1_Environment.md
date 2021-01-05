# Microsoft SQL Server: Setting Up an Always On Availability Group with PowerShell

## Part 1: The environment

In this series of articles I would like to show how an Always On availability group can be set up quickly and conveniently with PowerShell.  
In this first part, I will first show you how to set up a corresponding environment so that you can follow the commands. If you already have an environment, you will get hints on the necessary requirements here.


### A few preliminary remarks

If you already have some experience with PowerShell, you can probably follow the commands and adapt them to your environment if necessary. I usually try to write rather verbose PowerShell syntax, so specify all parameter names, for example. On the other hand, the code here in the article should be easy to read, so I refrain from any error handling. Execute the commands one by one or in small blocks to be able to detect errors early.  
If you haven't worked with PowerShell before, this will give you a first look at working with this scripting language. If you want to know more, please visit our seminar [Windows PowerShell for Administrators](https://seminare.ordix.de/seminare/entwicklung/script-sprachen/windows-powershell-f%C3%BCr-administratoren.html).

I want to build an environment with as little effort as possible to show you how to set up an Always On availability group. Therefore, I try to keep the environment as simple as possible, especially when it comes to security. So I will work with the domain administrator throughout and also use it to administer the SQL Server instances.  
I will gladly support you in adapting the scripts to your requirements and in building an individual environment together with you. You can reach me by [mail](mailto:info@ordix.de).


### Automated virtual machine setup

I am using a computer with Windows 10 as a base, on which I have administrative rights. I have already set up Hyper-V there.
For the automated creation of virtual test systems with Hyper-V, I recommend the PowerShell module PSAutoLab, which in turn is based on the PowerShell module Lability and comes with ready-made configurations that are well suited for our purpose.  
The installation is described very well here, so I'll omit further details here: [PSAutoLab on GitHub](https://github.com/pluralsight/PS-AutoLab-Env).

The configuration that suits us is [PowerShellLab](https://github.com/pluralsight/PS-AutoLab-Env/blob/master/Configurations/PowerShellLab/Instructions.md). While we do not need the WebServer on the SRV2 server or the SRV3 server, the rest fits. If you want to look into PSAutoLab in more detail, feel free to modify the configuration accordingly.  
In order to be able to set up later with PowerShell smooth connections with WinRM (thus PowerShell Remoting) from the client to the servers the installation of the current Windows updates is compellingly necessary. In addition, we want to work as close to reality as possible, i.e. not with outdated versions.  
The installation of the updates can also be done by PSAutoLab. Since several rounds with reboots in between are necessary here, the setup of the environment can already take a few hours - just watch a good movie on the side...  

If you have any questions or problems with PSAutoLab you can also contact me, maybe I already had the same problem and a solution.


### Setup of the client WIN10

We will never connect to the servers directly via RDP, as they are core systems without a graphical user interface. We exclusively use the Windows 10 client with the name WIN10. We will first set this up so that we can work well with it.

Connect to WIN10 via the Hyper-V Manager. In the first login screen only the English keyboard is available, but you can transfer the login data via the clipboard: `COMPANY\Administrator / P@ssw0rd`.  
The first login takes a long time and has to be repeated in a second login mask. Here, however, you can already switch to the German keyboard with `Alt + Shift`. This is then still available, but another restart may be necessary.  

For the installation of the SQL Server instances, the [sources](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) as well as the current [update](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/latest-updates-for-microsoft-sql-server) are still needed within the environment. In addition, I use the sample database [AdventureWorks](https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure). I show here the setup with the SQL Server 2017 version, but the 2016 or 2019 versions should work exactly the same. To access the sources, I set up appropriate shares on WIN10.

Here is my script, the first lines of which you need to adapt according to your environment:

	$SQLServerISOPath = "<...>\SQLServer2017\en_sql_server_2017_developer_x64_dvd_11296168.iso"
	$SQLServerPatchPath = "<...>\SQLServer2017CU20\SQLServer2017-KB4541283-x64.exe"
	$SQLServerDemoDBPath = "<...>\Beispieldatenbanken\AdventureWorks2017.bak"
	$AutolabConfigurationPath = 'C:\Autolab\Configurations\PowerShellLab'

	$VMConfigurationData = Import-PowerShellDataFile -Path "$AutolabConfigurationPath\VMConfigurationData.psd1" 
	$VMName = $VMConfigurationData.NonNodeData.Lability.EnvironmentPrefix + 'WIN10'
	$VMDomain = $VMConfigurationData.AllNodes.DomainName
	$VMCredential = New-Object -TypeName PSCredential -ArgumentList "$VMDomain\Administrator", (ConvertTo-SecureString -String $VMConfigurationData.AllNodes.LabPassword -AsPlainText -Force)

	Add-VMDvdDrive -VMName $VMName -Path $SQLServerISOPath
	$Session = New-PSSession -VMName $VMName -Credential $VMCredential

	Invoke-Command -Session $Session -ScriptBlock { 
	    New-Item -Path C:\SQLServerPatches -ItemType Directory | Out-Null
	    New-SmbShare -Path C:\SQLServerPatches -Name SQLServerPatches | Out-Null
	    Grant-SmbShareAccess -Name SQLServerPatches -AccountName "$using:VMDomain\Administrator" -AccessRight Full -Force | Out-Null 

	    New-SmbShare -Path D:\ -Name SQLServerSources | Out-Null
	    Grant-SmbShareAccess -Name SQLServerSources -AccountName "$using:VMDomain\Administrator" -AccessRight Full -Force | Out-Null 
	
	    New-Item -Path C:\SQLServerBackups -ItemType Directory | Out-Null
	    New-SmbShare -Path C:\SQLServerBackups -Name SQLServerBackups | Out-Null
	    Grant-SmbShareAccess -Name SQLServerBackups -AccountName "$using:VMDomain\Administrator" -AccessRight Full -Force | Out-Null 
	}

	Copy-Item -Path $SQLServerPatchPath -Destination C:\SQLServerPatches -ToSession $Session
	Copy-Item -Path $SQLServerDemoDBPath -Destination C:\SQLServerBackups -ToSession $Session

This is also a good time to take a snapshot of the environment and then restart the environment:

	Snapshot-Lab ; Run-Lab

We now have an environment with a Windows domain, two member servers, and a client with the sources needed for installation.  
In the [next part](LINK) we will then set up the Windows failover cluster.

Andreas Jordan, info@ordix.de
