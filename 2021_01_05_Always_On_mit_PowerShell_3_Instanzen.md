# Microsoft SQL Server: Einrichten einer Always On Verfügbarkeitsgruppe mit PowerShell

## Teil 3: Die Microsoft SQL Server Instanzen

In dieser Artikelserie möchte ich zeigen, wie eine Always On Verfügbarkeitsgruppe mit PowerShell schnell und komfortabel aufgesetzt werden kann.  
Im [ersten Teil](LINK) ging es zunächst um die Einrichtung einer entsprechenden Umgebung, im [zweiten Teil](LINK) haben wir das Windows Failovercluster eingerichtet, jetzt wollen wir die SQL Server Instanzen installieren.

Neben dem von Microsoft zur Verfügung gestellten PowerShell-Modul [SqlServer](https://docs.microsoft.com/de-de/sql/powershell/download-sql-server-ps-module) hat sich das von einer Vielzahl von Autoren entwickelte PowerShell-Modul [dbatools](https://dbatools.io/) etabliert - welches ich im Folgenden nutzen werden.

Wir arbeiten wieder in einer administrativen PowerShell auf dem Client WIN10, wie schon im letzten Teil angesprochen empfehle ich dazu die "Windows PowerShell ISE".  


### Einrichtung der PowerShell Session

Wie schon im letzten Teil werden wir zunächst eine Reihe von Variablen füllen. Neben der Konfiguration des Clusters aus dem vorherigen Teil legen wir nun auch die Namen und Passwörter der benötigten Accounts sowie verschiedene Pfade fest:

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

Ein Hinweis zu den beiden Variablen $ClusterNodes und $SqlInstances, die sich in unserer Umgebung nicht unterscheiden: Die Unterscheidung soll hier vor allem deutlich machen, ob wir uns mit den Clusterknoten oder den darauf laufenden SQL Server Instanzen verbinden. Sollten Sie statt der Standardinstanzen benannte Instanzen installieren wollen, so müssen Sie $SqlInstances anpassen und die Form "SERVERNAME\INSTANZNAME" verwenden.

Desweiteren benötigen wir zwei Credential-Objekte mit Anmeldeinformationen, also Benutzer-Passwort-Kombinationen. In unserer Demoumgebung ist das Passwort vorgegeben und nicht schützenswert, daher werden diese Objekte wie folgt aufgebaut:

	$AdministratorCredential = New-Object -TypeName PSCredential -ArgumentList "$DomainName\Administrator", (ConvertTo-SecureString -String $Password -AsPlainText -Force)
	$SQLServerCredential = New-Object -TypeName PSCredential -ArgumentList "$DomainName\$SQLServerServiceAccount", (ConvertTo-SecureString -String $Password -AsPlainText -Force)

In einem produktiven Einsatz können diese Informationen zur Laufzeit vom Benutzer abgefragt werden, damit das Kennwort zu keiner Zeit in einer Datei gespeichert wird oder auf dem Bildschirm sichtbar ist:

	$AdministratorCredential = Get-Credential -UserName "$DomainName\Administrator" -Message 'Bitte Anmeldeinformationen des Domänenadministrators angeben' 
	$SQLServerCredential = Get-Credential -UserName "$DomainName\$SQLServerServiceAccount" -Message 'Bitte Anmeldeinformationen des SQL Server Dienstekontos angeben' 


### Einrichtung des Active Directory

Die SQL Server Instanzen benötigen ein Domänenkonto für die Dienste, wir verwenden für beide Dienste das gleiche Konto und vergeben an dieser Stelle bereits die notwendigen Rechte auf die Backup-Freigabe:

	New-ADUser -Name $SQLServerServiceAccount -AccountPassword $SQLServerCredential.Password -PasswordNeverExpires:$true -Enabled:$true
	Grant-SmbShareAccess -Name SQLServerBackups -AccountName "$DomainName\$SQLServerServiceAccount" -AccessRight Full -Force | Out-Null


### Installation des PowerShell-Moduls dbatools

Zunächst richten wir PowerShell so ein, dass die Installation von PowerShell-Modulen ohne Rückfrage erfolgen kann:

	Install-PackageProvider -Name Nuget -Force | Out-Null
	Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Und installieren anschließend das Modul:

	Install-Module -Name dbatools

Die Entwickler empfehlen, das Modul vor der ersten Verwendung explizit zu laden. Das ist zwar in aktuellen PowerShell-Versionen nicht mehr notwendig, aber so können Probleme mit dem Modul bereits sehr früh erkannt werden:

	Import-Module -Name dbatools


### Konfiguration der Server für hohe Performance

Dieser Schritt ist nicht notwendig, sollte aber auf jedem System ausgeführt werden. Denn auch Windows Server Systeme laufen zunächst im Energiesparplan "Balanced" und sollten selbstverständlich auf "High Performance" gestellt werden. Auch dafür gibt es im Modul dbatools ein passendes Commandlet (Für die PowerShell-Anfänger: So heißen die Befehle bei PowerShell):

	Set-DbaPowerPlan -ComputerName $ClusterNodes | Format-Table


### Installation und Konfiguration der SQL Server Instanzen

Für die Installation stellt das Modul dbatools das Commandlet Install-DbaInstance zur Verfügung, mit dem wir auf beiden Knoten gleichzeitig und mit identischer Konfiguration eine SQL Server Instanz installieren können. Gegenüber anderen Skriptvarianten haben wir hier zudem den Vorteil, dass das Kennwort an dieser Stelle nicht im Klartext im Skript steht, sondern sicher im Credential-Objekt verpackt ist.

	$InstallResult = Install-DbaInstance -SqlInstance $ClusterNodes -Version 2017 -Feature Engine `
    	-EngineCredential $SQLServerCredential -AgentCredential $SQLServerCredential -AdminAccount "$DomainName\Administrator" `
    	-Path $SQLServerSourcesPath -UpdateSourcePath $SQLServerPatchesPath -Authentication Credssp -Credential $AdministratorCredential -Confirm:$false
	$InstallResult | Format-Table

Die folgenden Nacharbeiten sind wieder nicht notwendig, aber ich möchte Ihnen doch gerne zeigen, wie Sie typische Einstellungen der Instanzen mit Hilfe von dbatools vornehmen können. Mehr Informationen zu den einzelnen Commandlets finden Sie in der [Dokumentation](https://dbatools.io/commands/) von dbatools.

	Set-DbaPrivilege -ComputerName $ClusterNodes -Type IFI 
	Set-DbaMaxMemory -SqlInstance $SqlInstances -Max 2048 | Format-Table
	Set-DbaMaxDop -SqlInstance $SqlInstances | Format-Table
	Set-DbaSpConfigure -SqlInstance $SqlInstances -Name CostThresholdForParallelism -Value 50 | Format-Table


### Einrichtung der Beispieldatenbank

Damit wir eine Datenbank für unsere Verfügbarkeitsgruppe haben, stellen wir auf dem ersten Knoten die Datenbank AdventureWorks aus dem Backup wieder her. Zudem konfigurieren wir das Wiederherstellungsmodell, da nur Datenbanken im Wiederherstellungsmodell "Vollständig" in eine Verfügbarkeitsgruppe aufgenommen werden können.

	Restore-DbaDatabase -SqlInstance $SqlInstances[0] -Path "$BackupPath\AdventureWorks2017.bak" -DatabaseName $DatabaseName | Out-Null
	$Database = Get-DbaDatabase -SqlInstance $SqlInstances[0] -Database $DatabaseName
	$Database.RecoveryModel = 'Full'
	$Database.Alter()

Damit sind unsere SQL Server Instanzen auch schon einsatzbereit und es geht weiter mit dem [vierten Teil](LINK) und der Einrichtung der Verfügbarkeitsgruppe.

Andreas Jordan, info@ordix.de
