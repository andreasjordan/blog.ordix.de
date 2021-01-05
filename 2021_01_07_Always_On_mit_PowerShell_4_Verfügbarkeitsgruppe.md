# Microsoft SQL Server: Einrichten einer Always On Verfügbarkeitsgruppe mit PowerShell

## Teil 4: Die Always On Verfügbarkeitsgruppe

In dieser Artikelserie möchte ich zeigen, wie eine Always On Verfügbarkeitsgruppe mit PowerShell schnell und komfortabel aufgesetzt werden kann.  
Im [ersten Teil](LINK) ging es zunächst um die Einrichtung einer entsprechenden Umgebung, im [zweiten Teil](LINK) haben wir das Windows Failovercluster eingerichtet, im [dritten Teil](LINK) die SQL Server Instanzen und die Beispieldatenbank, jetzt wollen wir endlich die Verfügbarkeitsgruppe einrichten.

Wir arbeiten wieder in einer administrativen PowerShell auf dem Client WIN10, wie schon im letzten Teil angesprochen empfehle ich dazu die "Windows PowerShell ISE". 


### Einrichtung der PowerShell Session

Wie schon in den vorherigen Teilen werden wir zunächst eine Reihe von Variablen füllen. Es kommen jetzt noch der Name der Verfügbarkeitsgruppe sowie die IP des Listeners hinzu:

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
	

### Einrichtung der Dienste

Zunächst müssen die beiden SQL Server Instanzen bzw. die Dienste der Instanzen für die Nutzung von Always On konfiguriert werden. Das kann entweder über die GUI des SQL Server Configuration Managers erfolgen, oder per PowerShell mit dem Modul dbatools, dass wir bereits zur Installation und Konfiguration der Instanzen genutzt haben: 

	Import-Module -Name dbatools
	Enable-DbaAgHadr -SqlInstance $SqlInstances -Force | Format-Table

Die Instanzen müssen zur Umsetzung der Änderung neu gestartet werden, das PowerShell-Commandlet übernimmt dies automatisch.


### Einrichtung der Extended Event Sessions

Zur Überwachung von Always On ist im SQL Server bereits eine entsprechende Extended Event Session eingerichtet. Diese muss nur noch für den automatischen Start konfiguriert und gestartet werden:

	Get-DbaXESession -SqlInstance $SqlInstances -Session AlwaysOn_health | ForEach-Object -Process { $_.AutoStart = $true ; $_.Alter() ; $_ | Start-DbaXESession } | Format-Table

Der Assistent zum Erstellen von Verfügbarkeitsgruppen konfiguriert die Session entsprechend. Vielleicht wird dies in Zukunft auch vom Commandlet New-DbaAvailabilityGroup erledigt, welches wir später zur Erstellung der Verfügbarkeitsgruppe nutzen. Einen entsprechenden [Feature Request](https://github.com/sqlcollaborative/dbatools/issues/6603) habe ich bereits gestellt.


### Einrichtung der Endpunkte

Zur Kommunikation zwischen den beiden Instanzen, also vor allem zur Übertragung aller Änderungen von der primären auf die sekundäre Datenbank, wird auf beiden Instanzen ein Endpunkt eingerichtet und das Dienstekonto darauf berechtigt:
   
	New-DbaEndpoint -SqlInstance $SqlInstances -Name hadr_endpoint -Port 5022 | Start-DbaEndpoint | Format-Table
	New-DbaLogin -SqlInstance $SqlInstances -Login "$DomainName\$SQLServerServiceAccount" | Format-Table
	Invoke-DbaQuery -SqlInstance $SqlInstances -Query "GRANT CONNECT ON ENDPOINT::hadr_endpoint TO [$DomainName\$SQLServerServiceAccount]"

Diese Schritte müssen nur ausgeführt werden, wenn später nicht mit dem Commandlet New-DbaAvailabilityGroup gearbeitet wird. Sie müssen allerdings auch verwendet werden, wenn der Endpunkt auf einem anderen Port als 5022 angelegt werden soll. Dies kann zum Beispiel notwendig sein, wenn es auch dem Server mehrere Instanzen gibt, in denen Always On verwendet werden soll.


### Übertragung der Datenbank auf den zweiten Knoten

Ich trenne gerne die Übertragung der Datenbank vom primären auf den sekundären Server von der Erstellung der Verfügbarkeitsgruppe, da der erste Teil je nach Größe der Datenbank länger dauern kann oder sogar in mehreren Schritten erfolgt. Bei unserer Beispieldatenbank reicht die Erstellung und Wiederherstellung einer vollständigen Sicherung sowie einer Transaktionsprotokollsicherung:  
 
	$Database = Get-DbaDatabase -SqlInstance $SqlInstances[0] -Database $DatabaseName
	$Database | Backup-DbaDatabase -Path $BackupPath -Type Database | Restore-DbaDatabase -SqlInstance $SqlInstances[1] -NoRecovery | Out-Null
	$Database | Backup-DbaDatabase -Path $BackupPath -Type Log | Restore-DbaDatabase -SqlInstance $SqlInstances[1] -Continue -NoRecovery | Out-Null


### Verfügbarkeitsgruppe erstellen

Die Datenbank auf dem sekundären Knoten befindet sich jetzt im Status "Restoring" und ist fast so aktuell wie die Datenbank auf dem primären Knoten. In diesem Zustand kann jetzt die Verfügbarkeitsgruppe erstellt und die Datenbank darin aufgenommen werden. Ich verwende hier das [automatische Seeding](https://docs.microsoft.com/de-de/sql/database-engine/availability-groups/windows/automatic-seeding-secondary-replicas), da ich die Datenbank bereits im vorherigen Schritt auf den zweiten Knoten übertragen habe. Verwende ich diesen Modus ohne die Datenbank zuvor übertragen zu haben, erfolgt die Übertragung automatisch bei der Erstellung der Verfügbarkeitsgruppe. Wird der Parameter SeedingMode nicht angegeben, wird der manuelle Modus genutzt. Es ist dann die Angabe eines gemeinsamen Pfades erforderlich, über den die Datenbank per Backup und Restore übertragen wird. Im Prinzip führt das Commandlet dann genau die Schritte aus, die ich im vorherigen Kapitel genannt habe.

Durch die Angabe der IP-Adresse wird auch gleich ein Listener für die Verfügbarkeitsgruppe angelegt.

Mit Get-DbaAgReplica und Get-DbaAgDatabase können Sie sich anschließend den Zustand der Verfügbarkeitsgruppe und der Datenbank ansehen um sicher zu gehen, dass alles in Ordnung ist.

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


Über das Commandlet New-DbaAvailabilityGroup können einige weitere Optionen eingestellt werden, ich belasse es hier aber bei den Voreinstellungen. So wird als [Verfügbarkeitsmodus](https://docs.microsoft.com/de-de/sql/database-engine/availability-groups/windows/availability-modes-always-on-availability-groups) der synchronen Modus gewählt, damit ein automatisches [Failover](https://docs.microsoft.com/de-de/sql/database-engine/availability-groups/windows/failover-and-failover-modes-always-on-availability-groups) möglich ist.

Damit ist die Verfügbarkeitsgruppe eingerichtet und das (vorläufige) Ende dieser Artikelserie erreicht.

Andreas Jordan, info@ordix.de
