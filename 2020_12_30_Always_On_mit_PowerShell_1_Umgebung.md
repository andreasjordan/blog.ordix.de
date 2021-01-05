# Microsoft SQL Server: Einrichten einer Always On Verfügbarkeitsgruppe mit PowerShell

## Teil 1: Die Umgebung

In dieser Artikelserie möchte ich zeigen, wie eine Always On Verfügbarkeitsgruppe mit PowerShell schnell und komfortabel aufgesetzt werden kann.  
In diesem ersten Teil wird es zunächst um die Einrichtung einer entsprechenden Umgebung gehen, damit Sie die Befehle auch bei sich nachvollziehen können. Wenn Sie bereits eine Umgebung haben, erhalten Sie hier Hinweise auf die notwendigen Voraussetzungen.


### Ein paar Vorbemerkungen

Wenn Sie bereits erste Erfahrungen mit PowerShell haben, können Sie die Befehle vermutlich nachvollziehen und ggf. auf Ihre Umgebung anpassen. Ich versuche in der Regel, eher ausführlichen PowerShell-Syntax zu schreiben, also beispielweise alle Parameternamen anzugeben. Andererseits soll der Code hier im Artikel gut lesbar sein, daher verzichte ich auf jegliche Fehlerbehandlung. Führen Sie die Befehle einzeln oder in kleinen Blöcken aus, um Fehler frühzeitig erkennen zu können.  
Sollten Sie bisher noch nicht mit PowerShell arbeiten, so bekommen Sie hier einen ersten Einblick in die Arbeit mit dieser Skriptsprache. Wenn Sie mehr wissen möchten, besuchen Sie doch unser Seminar [Windows PowerShell für Administratoren](https://seminare.ordix.de/seminare/entwicklung/script-sprachen/windows-powershell-f%C3%BCr-administratoren.html).

Ich möchte mit möglichst wenig Aufwand eine Umgebung aufbauen, um Ihnen die Einrichtung einer Always On Verfügbarkeitsgruppe zu zeigen. Daher versuche ich die Umgebung möglichst einfach zu halten, vor allem auch was das Thema Sicherheit angeht. So werde ich durchgängig mit dem Domänenadministrator arbeiten und diesen auch zur Administration der SQL Server Instanzen verwenden.  
Gerne unterstütze ich Sie dabei, die Skripte an Ihre Anforderungen anzupassen und eine individuelle Umgebung mit Ihnen zusammen aufzubauen. Sie erreichen mich per [Mail](mailto:info@ordix.de).


### Automatisierte Einrichtung von virtuellen Maschinen

Ich nutze als Basis einen Computer mit Windows 10, auf dem ich administrative Rechte habe. Ich habe dort bereits Hyper-V eingerichtet.
Zur automatisierten Erstellung von virtuellen Testsystemem mit Hyper-V empfehle ich das PowerShell-Modul PSAutoLab, das wiederum auf dem PowerShell-Modul Lability basiert und bereits vorgefertige Konfigurationen mitbringt, die für unseren Zweck gut geeignet sind.  
Die Installation ist hier sehr gut beschrieben, daher verzichte ich an dieser Stelle auf weitere Details: [PSAutoLab auf GitHub](https://github.com/pluralsight/PS-AutoLab-Env).

Die für uns geeignete Konfiguration ist [PowerShellLab](https://github.com/pluralsight/PS-AutoLab-Env/blob/master/Configurations/PowerShellLab/Instructions.md). Zwar benötigen wir weder den WebServer auf dem Server SRV2 noch den Server SRV3, aber der Rest passt. Wenn Sie sich näher mit PSAutoLab beschäftigen möchten, dürfen Sie gerne die Konfiguration entsprechend anpassen.  
Um später mit PowerShell reibungslos Verbindungen mit WinRM (also PowerShell Remoting) vom Client auf die Server einrichten zu können ist die Installation der aktuellen Windows-Updates zwingend notwendig. Zudem wollen wir ja so realitätsnah arbeiten wie möglich, also nicht mit veralteten Versionen.  
Auch die Installation der Updates kann durch PSAutoLab erledigt werden. Da hier mehrere Runden mit zwischenzeitlichen Neustarts notwendig sind, kann der Aufbau der Umgebung schon ein paar Stunden dauern - schauen Sie nebenbei einfach einen guten Film...  

Bei Fragen oder Problemen mit PSAutoLab können Sie sich auch am mich wenden, vielleicht hatte ich bereits das gleiche Problem und eine Lösung.


### Einrichtung des Clients WIN10

Auf die Server werden wir uns nie direkt per RDP verbinden, da es Core-Systeme ohne grafische Oberfläche sind. Wir nutzen ausschließlich den Windows 10 Client mit dem Namen WIN10. Diesen werden wir jetzt zunächst so einrichten, dass wir gut damit arbeiten können.

Verbinden Sie sich über den Hyper-V Manager mit WIN10. In der ersten Anmeldemaske steht nur die englische Tastatur zur Verfügung, aber Sie können die Anmeldedaten jedoch über die Zwischenablage übertragen: `COMPANY\Administrator / P@ssw0rd`  
Die erste Anmeldung benötigt sehr lange und muss dann noch einmal in einer zweiten Anmeldemaske wiederholt werden. Hier kann allerdings bereits mit `Alt + Shift` auf die deutsche Tastatur umgeschaltet werden. Diese steht dann auch weiterhin zur Verfügung, evtl. ist jedoch ein weiterer Neustart notwendig.  

Für die Installation der SQL Server Instanzen werden noch die [Quellen](https://www.microsoft.com/de-de/sql-server/sql-server-downloads) sowie das aktuelle [Update](https://docs.microsoft.com/de-de/sql/database-engine/install-windows/latest-updates-for-microsoft-sql-server) innerhalb der Umgebung benötigt. Zudem verwende ich die Beispieldatenbank [AdventureWorks](https://docs.microsoft.com/de-de/sql/samples/adventureworks-install-configure). Ich zeige hier die Einrichtung mit der Version SQL Server 2017, die Versionen 2016 oder 2019 sollten aber auch genau so funktionieren. Für den Zugriff auf die Quellen richte ich auf WIN10 entsprechende Freigaben ein.

Hier mein Skript, deren erste Zeilen Sie entsprechend Ihrer Umgebung anpassen müssen:

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

Das ist dann auch der geeignete Zeitpunkt, um einen Snapshot der Umgebung zu erstellen und die Umgebung im Anschluss wieder zu starten:

	Snapshot-Lab ; Run-Lab

Wir haben jetzt eine Umgebung mit einer Windows-Domäne, zwei Mitglieds-Servern sowie einem Client mit den zur Installation benötigten Quellen.  
Im [nächsten Teil](LINK) richten wir dann das Windows Failovercluster ein.

Andreas Jordan, info@ordix.de
