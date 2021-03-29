# Microsoft SQL Server: Einrichten einer Always On Verfügbarkeitsgruppe mit PowerShell

Autor: Andreas Jordan (anj@ordix.de)

Veröffentlich unter: https://blog.ordix.de/microsoft-sql-server-einrichten-einer-always-on-verfuegbarkeitsgruppe-mit-powershell-teil-2


## Teil 2: Das Windows Failovercluster

In dieser Artikelserie möchte ich zeigen, wie eine Always On Verfügbarkeitsgruppe mit PowerShell schnell und komfortabel aufgesetzt werden kann.  
Im [ersten Teil](2020_12_30_Always_On_mit_PowerShell_1_Umgebung.md) ging es zunächst um die Einrichtung einer entsprechenden Umgebung, jetzt wollen wir diese mit Leben füllen.

Für allgemeine Informationen zu Verfügbarkeitsgruppen verweise ich hier lediglich auf die Dokumentation von Microsoft: [Was ist eine Always On-Verfügbarkeitsgruppe](https://docs.microsoft.com/de-de/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server).  
Hier nur soviel: Wir benötigen als Basis ein Windows Failovercluster, das sich mit wenigen PowerShell-Befehlen einrichten lässt.

Wir arbeiten im folgenden in einer administrativen PowerShell auf dem Client WIN10. Ob Sie die "Windows PowerShell" oder die "Windows PowerShell ISE" nutzen, bleibt Ihnen überlassen. Ich empfehle jedoch für solche Einsätze die ISE (ISE = Integrated Scripting Environment), da hier alle Befehle gut im Blick bleiben, einzelne Zeilen oder Blöcke komfortabel ausgeführt werden können und das Skript zur Dokumentation auch gespeichert werden kann.  


### Einrichtung der PowerShell Session

Damit Sie die Befehle in diesem Beitrag möglichst auch ohne Anpassungen in anderen Umgebungen nutzen können, werden wir zunächst einige Variablen füllen, die die für die PSAutoLab-Umgebung passenden Werte enthalten. So wollen wir das Failovercluster aus den beiden Servern SRV1 und SRV2 bilden, denn diese sind bereits Mitglied der Domäne. Das Failovercluster soll den Namen SQLCluster und die IP-Adresse 192.168.3.70 bekommen: 

	$DomainName = 'COMPANY'
	$DomainController = 'DOM1'
	$ClusterNodes = 'SRV1', 'SRV2'
	$ClusterName = 'SQLCluster'
	$ClusterIP = '192.168.3.70'


### Einrichtung des Active Directory

Die beiden Server für das Failovercluster sind zwar Mitglied der Domäne, allerdings sind sie nicht in der gleichen Organisationseinheit (OU / Organizational Unit), was aber eine [Voraussetzung](https://docs.microsoft.com/de-de/windows-server/failover-clustering/create-failover-cluster) ist. Daher verschieben wir den Server SRV2 wieder zurück in den Standard-Container:

	Move-ADObject -Identity 'CN=SRV2,OU=Servers,DC=Company,DC=Pri' -TargetPath 'CN=Computers,DC=Company,DC=Pri'

Wir benötigen auf beiden Knoten das Failoverclusteringfeature, welches wir mit folgendem Befehl installieren:

	Invoke-Command -ComputerName $ClusterNodes -ScriptBlock { Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools } | Format-Table

An dieser Stelle ein Hinweis zu `| Format-Table`: Hiermit wird die Ausgabe als Tabelle formatiert. Ich nutze diese Möglichkeit immer dann, wenn mehrere Objekte ausgegeben werden, hier die beiden Ergebnisse der Installation. Alternativ nutze ich später auch `| Format-List`, wenn nur ein Objekt ausgegeben wird und alle Eigenschaften übersichtlich als Liste ausgegeben werden sollen. Sie können die Befehle gerne so anpassen, dass die für Sie passende Ausgabe erfolgt. In einigen Befehlen nutze ich auch `| Out-Null`, um die Ausgabe ganz zu unterdrücken, weil ich sie nicht für relevant halte. Auch das dürfen Sie gerne ändern.

Der folgende Schritt ist nicht zwingend erforderlich, aber dennoch empfohlen. Denn durch die Ausführung des Validierungstests erhalten Sie einen übersichtlichen Bericht über mögliche Konfigurationsprobleme oder noch nicht erfüllte Voraussetzungen. Gerade in Produktionsumgebungen ist er wichtig, denn ein positiver Test ist Voraussetzung für den Support des Clusters durch Microsoft. Wir starten den Test und lassen uns das Ergebnis im Browser anzeigen:

	$ClusterTest = Test-Cluster -Node $ClusterNodes
	&$ClusterTest.FullName

Der Test darf jedoch Warnungen enthalten. So gibt es in unserer Umgebung nur eine Netzwerkverbindung zwischen den Servern und daher diese Meldung: "Node srv2.company.pri is reachable from Node srv1.company.pri by only one pair of network interfaces. It is possible that this network path is a single point of failure for communication within the cluster. Please verify that this single path is highly available, or consider adding additional networks to the cluster."


### Erstellung des Failoverclusters

Wenn der Validierungstest positiv war, dann können wir das Failovercluster erstellen:

	$Cluster = New-Cluster -Name $ClusterName -Node $ClusterNodes -StaticAddress $ClusterIP
	$Cluster | Format-List

Da wir in der Umgebung keinen gemeinsamen Speicher für das Quorum haben, nutzen wir eine Netzwerkfreigabe als Quorum. Die Netzwerkfreigabe legen wir dazu auf dem Domänenkontroller an und berechtigen das Computer-Konto des gerade erstellten Failoverclusters:

	Invoke-Command -ComputerName $DomainController -ScriptBlock { 
    	New-Item -Path "C:\WindowsClusterQuorum_$using:ClusterName" -ItemType Directory | Out-Null
    	New-SmbShare -Path "C:\WindowsClusterQuorum_$using:ClusterName" -Name "WindowsClusterQuorum_$using:ClusterName" | Out-Null
    	Grant-SmbShareAccess -Name "WindowsClusterQuorum_$using:ClusterName" -AccountName "$using:DomainName\$using:ClusterName$" -AccessRight Full -Force | Out-Null
	}
	$Cluster | Set-ClusterQuorum -NodeAndFileShareMajority "\\$DomainController\WindowsClusterQuorum_$ClusterName" | Format-List

Damit ist unser Failovercluster auch schon einsatzbereit und es geht weiter mit dem [dritten Teil](2021_01_05_Always_On_mit_PowerShell_3_Instanzen.md) und der Installation der SQL Server Instanzen.
