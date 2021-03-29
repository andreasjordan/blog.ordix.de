# Microsoft SQL Server: Einrichten einer Always On Verfügbarkeitsgruppe mit PowerShell

Autor: Andreas Jordan (anj@ordix.de)

Veröffentlich unter: https://blog.ordix.de/microsoft-sql-server-einrichten-einer-always-on-verfuegbarkeitsgruppe-mit-powershell-teil-1


## Teil 1: Die Umgebung

In dieser Artikelserie möchte ich zeigen, wie eine Always On Verfügbarkeitsgruppe mit PowerShell schnell und komfortabel aufgesetzt werden kann.  
In diesem ersten Teil wird es zunächst um die Einrichtung einer entsprechenden Umgebung gehen, damit Sie die Befehle auch bei sich nachvollziehen können. Wenn Sie bereits eine Umgebung haben, erhalten Sie hier Hinweise auf die notwendigen Voraussetzungen.


### Ein paar Vorbemerkungen

Wenn Sie bereits erste Erfahrungen mit PowerShell haben, können Sie die Befehle vermutlich nachvollziehen und ggf. auf Ihre Umgebung anpassen. Ich versuche in der Regel, eher ausführlichen PowerShell-Syntax zu schreiben, also beispielweise alle Parameternamen anzugeben. Andererseits soll der Code hier im Artikel gut lesbar sein, daher verzichte ich auf jegliche Fehlerbehandlung. Führen Sie die Befehle einzeln oder in kleinen Blöcken aus, um Fehler frühzeitig erkennen zu können.  
Sollten Sie bisher noch nicht mit PowerShell arbeiten, so bekommen Sie hier einen ersten Einblick in die Arbeit mit dieser Skriptsprache. Wenn Sie mehr wissen möchten, besuchen Sie doch unser Seminar [Windows PowerShell für Administratoren](https://seminare.ordix.de/seminare/entwicklung/script-sprachen/windows-powershell-f%C3%BCr-administratoren.html).

Ich möchte mit möglichst wenig Aufwand eine Umgebung aufbauen, um Ihnen die Einrichtung einer Always On Verfügbarkeitsgruppe zu zeigen. Daher versuche ich die Umgebung möglichst einfach zu halten, vor allem auch was das Thema Sicherheit angeht. So werde ich durchgängig mit dem Domänenadministrator arbeiten und diesen auch zur Administration der SQL Server Instanzen verwenden.  
Gerne unterstütze ich Sie dabei, die Skripte an Ihre Anforderungen anzupassen und eine individuelle Umgebung mit Ihnen zusammen aufzubauen. Sie erreichen mich per [Mail](mailto:anj@ordix.de).


### Automatisierte Einrichtung von virtuellen Maschinen

Ich nutze als Basis einen Computer mit Windows 10, auf dem ich administrative Rechte habe. Dieses System nenne ich im Folgenden auch Hostsystem, um es von den virtuellen Systemen zu unterschieden. Ich habe dort bereits Hyper-V eingerichtet.
Zur automatisierten Erstellung von virtuellen Testsystemem mit Hyper-V empfehle ich das PowerShell-Modul PSAutoLab, das wiederum auf dem PowerShell-Modul Lability basiert und bereits vorgefertigte Konfigurationen mitbringt, die für unseren Zweck gut geeignet sind.  
Die Installation ist hier sehr gut beschrieben, daher verzichte ich an dieser Stelle auf weitere Details: [PSAutoLab auf GitHub](https://github.com/pluralsight/PS-AutoLab-Env).

Die für uns geeignete Konfiguration ist [PowerShellLab](https://github.com/pluralsight/PS-AutoLab-Env/blob/master/Configurations/PowerShellLab/Instructions.md). Zwar benötigen wir weder den WebServer auf dem Server SRV2 noch den Server SRV3, aber der Rest passt. Wenn Sie sich näher mit PSAutoLab beschäftigen möchten, dürfen Sie gerne die Konfiguration entsprechend anpassen.  
Um später mit PowerShell reibungslos Verbindungen mit WinRM (also PowerShell Remoting) vom Client auf die Server einrichten zu können ist die Installation der aktuellen Windows-Updates zwingend notwendig. Zudem wollen wir ja so realitätsnah arbeiten wie möglich, also nicht mit veralteten Versionen.  
Auch die Installation der Updates kann durch PSAutoLab erledigt werden. Da hier mehrere Runden mit zwischenzeitlichen Neustarts notwendig sind, kann der Aufbau der Umgebung schon ein paar Stunden dauern - schauen Sie nebenbei einfach einen guten Film...  

Bei Fragen oder Problemen mit PSAutoLab können Sie sich auch am mich wenden, vielleicht hatte ich bereits das gleiche Problem und eine Lösung.

[Update] Da es vereinzelt zu Problemen bei der automatischen Installation der virtuellen Maschinen mit `Unattend-Lab` kommen kann, empfehle ich die Ausführung der folgenden Einzelschritte in einer administrativen ("Als Administrator ausführen") PowerShell:

```
Import-Module -Name PSAutoLab
Set-Location -Path "$((Get-PSAutoLabSetting).AutoLab)\Configurations\PowerShellLab"
Setup-Lab -UseLocalTimeZone -NoMessages
Run-Lab -NoMessages
Enable-Internet -NoMessages
```

Die Parameter `-NoMessages` unterdrücken jeweils Informationsmeldungen, entfernen Sie diese Parameter einfach, um die Meldungen doch zu sehen. Der Parameter  `-UseLocalTimeZone` bei `Setup-Lab` sorgt dafür, dass die virtuellen Maschinen die lokale Zeitzone nutzen.

Die virtuellen Maschinen richten sich nun selbständig ein, dieser Vorgang dauert bei mir ca. 30 bis 45 Minuten. So lange würde ich auf jeden Fall warten, bevor dann der aktuelle Zustand mit Hilfe von Pester überprüft werden kann:

```
Invoke-Pester -Script .\VMValidate.test.ps1
```

Hierbei wird zu jedem Test angezeigt, ob er bestanden wurde oder nicht. Damit kann erkannt werden, ob sich eine virtuelle Maschine nicht in die Domäne integriert hat, was einer der häufigsten Fehler ist. Dabei erschient typischerweise diese Fehlermeldung: "[-] [SRV2] Should allow a PSSession but got error: Die Anmeldeinformationen sind ungültig." Ein Aus- und Einschalten der betroffenen virtuellen Maschine über den Hyper-V-Manager kann das Problem lösen. Alternativ können Sie alle Maschinen mit `Wipe-Lab` entfernen und dann neu aufbauen.

Sind alle Tests erfolgreich, kann mit der Installation der Windows-Updates begonnen werden. Da nicht alle Updates auf einmal installiert werden können, werden aktuell zwei Neustarts benötigt. Um die Updates gleichzeitig auf allen virtuellen Maschinen durchzuführen, verwenden Sie den folgenden Befehl:

```
Update-Lab -AsJob
```

Bei mir dauert aktuell die erste Runde ca. 30 Minuten, die zweite Runde ca. 50 Minuten und die dritte Runde dann noch einmal ca. 10 Minuten. Hiermit kann der aktuelle Status der Jobs ermittelt werden:

```
Get-Job
```

 Wenn Sie die Ausgabe der Jobs von den virtuellen Maschinen abrufen möchten, verwenden Sie den folgenden Befehl:

```
Get-Job | Receive-Job
```

Vereinzelt konnte ich beobachten, dass WIN10 nach der Installation bereits automatisch herunterfährt, so dass der Status nicht mehr abgerufen werden kann und es daher zu einer Fehlermeldung kommt. Diese können Sie ignorieren. Überprüfen Sie nun den Status und die Ausgabe der Jobs regelmäßig mit `Get-Job` und `Get-Job | Receive-Job`  bis alle Updates durchgeführt wurden.

Wenn alle Jobs den Status "Completed" haben, müssen diese entfernt werden und die virtuellen Maschinen neu gestartet werden:

```
Get-Job | Remove-Job
Shutdown-Lab -NoMessages
Run-Lab -NoMessages
```

Das Herunterfahren und auch der Neustart können sehr lange dauern, weil dort noch weitere Teile der Updates installiert werden. Anschließend kann die nächste Runde mit `Update-Lab -AsJob` gestartet werden. Zumindest mit Stand Anfang 2021 erfordert die dritte Runde dann keinen anschließenden Neustart mehr und die Updates sind damit komplett installiert. Ab der vierten Runde werden nur noch für den WIN10 weitere Updates angezeigt, diese werden jedoch scheinbar nicht installieren. Die Installation kann aber später direkt in der virtuellen Maschine erfolgen, daher ist nur wichtig, dass alle Server keine offenen Updates mehr haben.


### Einrichtung des Clients WIN10

Auf die Server werden wir uns nie direkt per RDP verbinden, da es Core-Systeme ohne grafische Oberfläche sind. Wir nutzen ausschließlich den Windows 10 Client mit dem Namen WIN10. Diesen werden wir jetzt zunächst so einrichten, dass wir gut damit arbeiten können.

[Update] Entgegen der ersten Version des Artikels empfehle ich zunächst die Übertragung der notwendigen Dateien in die virtuelle Maschine, damit alle Arbeiten auf dem Hostsystem abgeschlossen sind und wir anschließend nur noch innerhalb der virtuellen Maschine arbeiten.

Für die Installation der SQL Server Instanzen werden noch die [Quellen](https://www.microsoft.com/de-de/sql-server/sql-server-downloads) sowie das aktuelle [Update](https://docs.microsoft.com/de-de/sql/database-engine/install-windows/latest-updates-for-microsoft-sql-server) innerhalb der Umgebung benötigt. Zudem verwende ich die Beispieldatenbank [AdventureWorks](https://docs.microsoft.com/de-de/sql/samples/adventureworks-install-configure). Ich zeige hier die Einrichtung mit der Version SQL Server 2017, die Versionen 2016 oder 2019 sollten aber auch genau so funktionieren. Für den Zugriff auf die Quellen richte ich auf WIN10 entsprechende Freigaben ein. Auf dem Hostsystem nutze ich den Ordner "Resources" unterhalb des Autolab-Verzeichnisses um diese Dateien abzulegen. Falls Sie ein anderes Verzeichnis nutzen, müssen Sie die ersten Zeilen des folgenden Skriptes entsprechend anpassen. Zudem verwende ich das zum jetzigen Zeitpunkt aktuelle CU22 für den SQL Server 2017, Sie müssen also später den Dateinamen in der zweiten Zeile entsprechend anpassen.

Weil wir der virtuellen Maschine ein virtuelles DVD-Laufwerk hinzufügen, müssen auch die folgenden Befehle wieder in einer administrativen PowerShell ausgeführt werden. Sie können einfach die für die Installation der virtuellen Maschinen genutzte PowerShell weiter verwenden.

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

Verbinden Sie sich nun über den Hyper-V-Manager mit der virtuellen Maschine WIN10. In der ersten Anmeldemaske steht nur die englische Tastatur zur Verfügung, aber Sie können die Anmeldedaten jedoch über die Zwischenablage übertragen: `COMPANY\Administrator / P@ssw0rd`  
Die erste Anmeldung benötigt sehr lange und muss dann noch einmal in einer zweiten Anmeldemaske wiederholt werden. Hier kann allerdings bereits mit `Alt + Shift` auf die deutsche Tastatur umgeschaltet werden. Starten Sie die virtuelle Maschine einmal neu, um die deutsche Tastatur auch innerhalb der virtuellen Maschine verwenden zu können. Anschließend können Sie die letzten Windows-Updates installieren.

Bitte beachten Sie, dass wir im Folgenden immer als Domänen-Administrator arbeiten. Da es auch ein lokales Konto mit dem Namen `Administrator` gibt, verwenden Sie bei der Anmeldung als Benutzername immer `COMPANY\Administrator`.

Wenn Sie die Einrichtung von WIN10 abgeschlossen haben ist das der geeignete Zeitpunkt, um einen Snapshot der Umgebung zu erstellen und die Umgebung im Anschluss wieder zu starten. Zu diesem Snapshot können Sie später mit `Refresh-Lab` wieder zurückkehren, falls Sie die Schritte der nächsten Teile dieser Artikelserie noch einmal wiederholen möchten. Hierzu verwenden wir wieder die administrative PowerShell auf dem Hostsystem. 

	Snapshot-Lab ; Run-Lab

Wir haben jetzt eine Umgebung mit einer Windows-Domäne, zwei Mitglieds-Servern sowie einem Client mit den zur Installation benötigten Quellen.  
Im [nächsten Teil](2020_12_31_Always_On_mit_PowerShell_2_Failovercluster.md) richten wir dann das Windows Failovercluster ein.
