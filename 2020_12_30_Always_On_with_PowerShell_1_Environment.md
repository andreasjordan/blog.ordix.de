# Microsoft SQL Server: Setting Up an Always On Availability Group with PowerShell

Author: Andreas Jordan (anj@ordix.de)

Published at: https://blog.ordix.de/microsoft-sql-server-setting-up-an-always-on-availability-group-with-powershell-part-1


## Part 1: The environment

In this series of articles I would like to show how an Always On availability group can be set up quickly and conveniently with PowerShell.  
In this first part, I will first show you how to set up a corresponding environment so that you can follow the commands. If you already have an environment, you will get hints on the necessary requirements here.


### A few preliminary remarks

If you already have some experience with PowerShell, you can probably follow the commands and adapt them to your environment if necessary. I usually try to write rather verbose PowerShell syntax, so specify all parameter names, for example. On the other hand, the code here in the article should be easy to read, so I refrain from any error handling. Execute the commands one by one or in small blocks to be able to detect errors early.  
If you haven't worked with PowerShell before, this will give you a first look at working with this scripting language. If you want to know more, please visit our seminar [Windows PowerShell for Administrators](https://seminare.ordix.de/seminare/entwicklung/script-sprachen/windows-powershell-f%C3%BCr-administratoren.html).

I want to build an environment with as little effort as possible to show you how to set up an Always On availability group. Therefore, I try to keep the environment as simple as possible, especially when it comes to security. So I will work with the domain administrator throughout and also use it to administer the SQL Server instances.  
I will gladly support you in adapting the scripts to your requirements and in building an individual environment together with you. You can reach me by [mail](mailto:anj@ordix.de).


### Automated virtual machine setup

I am using a computer with Windows 10 as a base, on which I have administrative rights. I have already set up Hyper-V there.
For the automated creation of virtual test systems with Hyper-V, I recommend the PowerShell module PSAutoLab, which in turn is based on the PowerShell module Lability and comes with ready-made configurations that are well suited for our purpose.  
The installation is described very well here, so I'll omit further details here: [PSAutoLab on GitHub](https://github.com/pluralsight/PS-AutoLab-Env).

The configuration that suits us is [PowerShellLab](https://github.com/pluralsight/PS-AutoLab-Env/blob/master/Configurations/PowerShellLab/Instructions.md). While we do not need the WebServer on the SRV2 server or the SRV3 server, the rest fits. If you want to look into PSAutoLab in more detail, feel free to modify the configuration accordingly.  
In order to be able to set up later with PowerShell smooth connections with WinRM (thus PowerShell Remoting) from the client to the servers the installation of the current Windows updates is compellingly necessary. In addition, we want to work as close to reality as possible, i.e. not with outdated versions.  
The installation of the updates can also be done by PSAutoLab. Since several rounds with reboots in between are necessary here, the setup of the environment can already take a few hours - just watch a good movie on the side...  

If you have any questions or problems with PSAutoLab you can also contact me, maybe I already had the same problem and a solution.

[Update] Since there may be occasional problems with the automatic installation of virtual machines with `Unattend-Lab`, I recommend executing the following individual steps in an administrative ("Run as administrator") PowerShell:

```
Import-Module -Name PSAutoLab
Set-Location -Path "$((Get-PSAutoLabSetting).AutoLab)\Configurations\PowerShellLab"
Setup-Lab -UseLocalTimeZone -NoMessages
Run-Lab -NoMessages
Enable-Internet -NoMessages
```

The `-NoMessages` parameters suppress information messages in each case, just remove these parameters to see the messages after all. The `-UseLocalTimeZone` parameter at `Setup-Lab` ensures that the virtual machines use the local time zone.

The virtual machines now set themselves up independently, this process takes about 30 to 45 minutes for me. I would wait that long in any case, before the current state can then be checked with the help of Pester:

```
Invoke-Pester -Script .\VMValidate.test.ps1
```

Here, for each test it is displayed whether it was passed or not. This can be used to detect if a virtual machine has not integrated into the domain, which is one of the most common errors. Typically, this error message appears: "[-] [SRV2] Should allow a PSSession but got error: The credential is invalid." Powering off and on the affected virtual machine via Hyper-V Manager may resolve the issue. Alternatively, you can remove all machines with `Wipe-Lab` and then rebuild them.

If all tests are successful, the installation of the Windows updates can be started. Since not all updates can be installed at once, two reboots are currently required. To perform the updates simultaneously on all virtual machines, use the following command:

```
Update-Lab -AsJob
```

For me, the first round currently takes about 30 minutes, the second round about 50 minutes and the third round then another 10 minutes. This can be used to determine the current status of the jobs:

```
Get-Job
```

If you want to get the output of the jobs from the virtual machines, use the following command:

```
Get-Job | Receive-Job
```

Occasionally I could observe that WIN10 already shuts down automatically after installation, so that the status can no longer be retrieved and therefore an error message occurs. You can ignore this. Now check the status and the output of the jobs regularly with `Get-Job` and `Get-Job | Receive-Job` until all updates are done.

When all jobs have the status "Completed", they must be removed and the virtual machines restarted:

```
Get-Job | Remove-Job
Shutdown-Lab -NoMessages
Run-Lab -NoMessages
```

The shutdown and also the restart can take a very long time, because there are still other parts of the updates installed. Afterwards, the next round can be started with `Update-Lab -AsJob`. At least as of the beginning of 2021, the third round then no longer requires a subsequent restart and the updates are thus completely installed. From the fourth round onwards, further updates are only displayed for WIN10, but these do not seem to be installed. However, the installation can be done later directly in the virtual machine, so it is only important that all servers no longer have any open updates.


### Setup of the client WIN10

We will never connect to the servers directly via RDP, as they are core systems without a graphical user interface. We exclusively use the Windows 10 client with the name WIN10. We will first set this up so that we can work well with it.

[Update] Contrary to the first version of the article, I recommend transferring the necessary files to the virtual machine first, so that all work on the host system is completed and then we work only within the virtual machine.

For the installation of the SQL Server instances, the [sources](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) as well as the current [update](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/latest-updates-for-microsoft-sql-server) are still needed within the environment. In addition, I use the sample database [AdventureWorks](https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure). I show here the setup with the SQL Server 2017 version, but the 2016 or 2019 versions should work exactly the same. To access the sources, I set up appropriate shares on WIN10.

To access the sources, I set up appropriate shares on WIN10. On the host system I use the folder "Resources" below the Autolab directory to store these files. If you use another directory, you have to adapt the first lines of the following script accordingly. Also, I am using the current CU22 for SQL Server 2017, so you will need to adjust the filename in the second line later.

Because we are adding a virtual DVD drive to the virtual machine, the following commands also need to be executed in an administrative PowerShell again. You can simply continue to use the PowerShell used for installing the virtual machines.

	$SQLServerISOPath = "$((Get-PSAutoLabSetting).AutoLab)\Resources\en_sql_server_2017_developer_x64_dvd_11296168.iso"
	$SQLServerPatchPath = "$((Get-PSAutoLabSetting).AutoLab)\Resources\SQLServer2017-KB4577467-x64.exe"
	$SQLServerDemoDBPath = "$((Get-PSAutoLabSetting).AutoLab)\Resources\AdventureWorks2017.bak"
	$AutolabConfigurationPath = "$((Get-PSAutoLabSetting).AutoLab)\Configurations\PowerShellLab"
	
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

Now connect to the WIN10 virtual machine via the Hyper-V Manager. In the first login screen only the English keyboard is available, but you can transfer the login data via the clipboard: `COMPANY\Administrator / P@ssw0rd`.  
The first login takes a long time and has to be repeated in a second login mask. Here, however, you can already switch to the German keyboard with `Alt + Shift`. Restart the virtual machine once to be able to use the German keyboard inside the virtual machine as well. Then you can install the latest Windows updates.

Please note that in the following we always work as domain administrator. Since there is also a local account named `Administrator`, always use `COMPANY\Administrator` as the username when logging in.

When you have finished setting up WIN10, this is a good time to take a snapshot of the environment and then restart the environment. You can return to this snapshot later with `Refresh-Lab` if you want to repeat the steps of the next parts of this article series. For this purpose, we again use the administrative PowerShell on the host system.

	Snapshot-Lab ; Run-Lab

We now have an environment with a Windows domain, two member servers, and a client with the sources needed for installation.  
In the [next part](2020_12_31_Always_On_with_PowerShell_2_Failovercluster.md) we will then set up the Windows failover cluster.
