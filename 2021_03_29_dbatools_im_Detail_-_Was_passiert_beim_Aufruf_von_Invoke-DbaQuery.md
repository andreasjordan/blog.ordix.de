# dbatools im Detail - Was passiert beim Aufruf von Invoke-DbaQuery?

Autor: Andreas Jordan (anj@ordix.de)

Veröffentlicht unter: https://blog.ordix.de/dbatools-aufruf-von-invoke-dbaquery



In diesem Artikel möchte ich Sie mitnehmen und einen Blick hinter die Kulissen des PowerShell-Moduls dbatools werfen, das ich sehr gerne für die Arbeit mit dem Microsoft SQL Server einsetze.

Ausgangspunkt soll eine einfache Abfrage auf eine Tabelle sein, die nur aus einer einzige Zeile Code besteht:

```powershell
Invoke-DbaQuery -SqlInstance 'SRV1\SQL2016' -Query 'SELECT * FROM test01.dbo.testdata'
```

Ich übergebe dem Befehl `Invoke-DbaQuery` hier nur den Namen der Instanz sowie die eigentliche Abfrage. Ich gehe damit davon aus, dass ich mit dem für die PowerShell-Sitzung verwendeten Windows-Account auch die notwendigen Rechte innerhalb der SQL Server-Instanz habe.



### Die Welt der Datentypen

Bevor wir in den Code hinter `Invoke-DbaQuery` eintauchen, folgt zunächst ein Exkurs in die Welt der Datentypen. Vor allem soll es hier darum gehen, wie PowerShell mit den verschiedenen Datentypen arbeitet.

Ich weise im Folgenden der Variablen `$number` verschiedene Werte zu und prüfe mit der Methode `GetType` anschließend den verwendeten Datentyp.

```powershell
$number = 12
$number.GetType().Name  # Int32
# Es wurde automatisch der passende Datentyp gewählt.

$number = 12345678901
$number.GetType().Name  # Int64
# Es wurde automatisch der passende Datentyp gewählt.

$number = [Int64]12
$number.GetType().Name  # Int64
# Die Angebe "12" wurde in den Datentyp Int64 umgewandelt und dann gespeichert, daher hat $number jetzt auch diesen Datentyp.

$number = 12
$number.GetType().Name  # Int32
# Die Variable $number hat wieder den eigentlichen Datentyp von "12" übernommen.

[Int64]$number = 12
$number.GetType().Name  # Int64
# Hier wurde der Datentyp von $number auch für die Zukunft festgelegt und die Angabe "12" in diesen Datentyp umgewandelt.

$number = 12
$number.GetType().Name  # Int64
# Die Variable $number behält den Datentyp, alle Angaben werden in diesen Datentyp umgewandelt.

$number = 'Hallo'  # Cannot convert value "Hallo" to type "System.Int64". Error: "Input string was not in a correct format."
# Unmögliche Umwandlungen führen zu einem Fehler.

$number = -0.65
$number.GetType().Name  # Int64
# Die Variable $number behält den Datentyp, alle Angaben werden in diesen Datentyp umgewandelt.
$number  # -1
# Umwandlungen können somit zu Rundungen führen.

# Also:
$number = [Int64]12  # (Temporäre) Umwandlung eines Wertes in einen Datentyp.
[Int64]$number = 12  # Deklaration einer Variablen mit einem festen Datentyp.

```



### Die Welt der Objektorientierung: Datentypen sind Klassen

Wer aus der objektorientierten Programmierung kommt, der ahnt es bereits: Datentypen sind Klassen. Variablen sind damit Objekte, die von diesen Klassen abgeleitet (instanziiert) werden. Die Datentypen haben also auch Attribute und Methoden. Um das besser zu veranschaulichen, wechseln wir von Zahlen zu Zeitangaben:

```powershell
$now = Get-Date
$now.GetType().Name  # DateTime
$now  # Saturday, March 13, 2021 1:33:12 PM

# Aber der Datentyp DateTime kann mehr:
$now.Hour  # 13
# Hour ist ein Attribut
$now.AddDays(2)  # Monday, March 15, 2021 1:33:12 PM
# AddDays ist eine Methode

# Welche Attribute und Methoden haben die Objekte dieser Klasse?
$now | Get-Member  
# Die Attribute werden hier "Property" genannt. Die Ausgabe ist sehr lang und daher hier im Artikel nicht angegeben.
```

Wenn wir so ein Objekt mit einem Zeitpunkt nicht über einen Befehl wie `Get-Date` erstellen wollen, müssen wir noch über Konstruktoren sprechen. Das sind Methoden der Klasse, die ein Objekt erstellen und es dabei auch gleich nach unseren Wünschen konfigurieren. Die Liste der Konstruktoren für den Datentypen DateTime findet sich in der [Dokumentation](https://docs.microsoft.com/de-de/dotnet/api/system.datetime.-ctor) bei Microsoft. Es gibt sehr viele Konstruktoren mit unterschiedlichen Parametern, hier ein Beispiel:

```powershell
$oneday = [DateTime]::new(2020, 12, 24)
$oneday.GetType().Name  # DateTime
$oneday  # Thursday, December 24, 2020 12:00:00 AM

$oneday = [DateTime]'2020-12-24'
# Auch das funktioniert, da die Zeichenkette "interpretiert" wird. Die Regeln sind im Datentyp, also in der Klasse, hinterlegt.
[DateTime]$oneday = '2020-12-24'
# Ab jetzt ist $oneday immer eine Zeitangabe, die nur gültige Werte enthalten kann.
$oneday = '2020-15-35'
# Cannot convert value "2020-15-35" to type "System.DateTime". Error: "String was not recognized as a valid DateTime."
```



### Auf in die Welt von dbatools: Der zentrale Datentyp DbaInstance

Ich bin generell ein Freund davon, die benötigten Module gleich zu Beginn eines Skriptes zu laden, also zu importieren. Das ist zwar meist nicht notwendig, da das Modul bei der ersten Verwendung eines Befehls aus diesem Modul automatisch geladen wird. Aber ich sehe das immer auch als eine Dokumentation der Abhängigkeiten. Dem Leser ist so schnell klar, welche Module zur Ausführung des Skriptes benötigt werden. In unserem konkreten Fall ist es aber zwingend notwendig, das Modul zunächst zu laden. Denn wir wollen noch vor der Verwendung des ersten Befehls einen Datentypen – also eine Klasse – des Moduls nutzen.

```powershell
Import-Module -Name dbatools
```

Der zentrale Datentyp zur Speicherung von Informationen über eine SQL Server-Instanz hat den Namen DbaInstanceParameter sowie den etwas kürzeren Alias DbaInstance, den ich im Folgenden verwenden werde. Wer ein Blick auf den Quellcode dieser in C# geschriebenen Klasse werfen möchte, wird [hier auf GitHub](https://github.com/sqlcollaborative/dbatools/blob/development/bin/projects/dbatools/dbatools/Parameter/DbaInstanceParameter.cs) fündig.

Dort finden sich dann auch die verschiedenen Konstruktoren, die jeweils ein Objekt der folgenden Typen entgegen nehmen (die Kommentare sind aus dem Quellcode übernommen):

- string (Creates a DBA Instance Parameter from string)
- IPAddress (Creates a DBA Instance Parameter from an IPAddress)
- PingReply (Creates a DBA Instance Parameter from the reply to a ping)
- IPHostEntry (Creates a DBA Instance Parameter from the result of a dns resolution)
- System.Data.SqlClient.SqlConnection (Creates a DBA Instance Parameter from an established SQL Connection)
- Discovery.DbaInstanceReport (Accept and understand discovery reports)
- object (Creates a DBA Instance parameter from any object)

Die Angabe "any object" im letzten Punkt ist dabei nicht ganz korrekt, konkret werden nur Objekte der folgenden Klassen akzeptiert:

- microsoft.sqlserver.management.smo.server
- microsoft.sqlserver.management.smo.linkedserver
- microsoft.activedirectory.management.adcomputer
- microsoft.sqlserver.management.registeredservers.registeredserver

Die häufigste Verwendung ist jedoch die Übergabe einer Zeichenkette, die aus dem Namen des Servers, evtl. noch dem Namen der Instanz und/oder dem zu verwendenden Port besteht. Wir starten zunächst ganz einfach und übergeben nur den Namen des Servers und schauen uns die Attribute des erstellten Objektes an:

```powershell
$instance = [DbaInstance]::new('MyServer')  # Das ist möglich, aber untypisch.
[DbaInstance]$instance = 'MyServer'         # Das ist die typische Verwendung. Damit wird der Datentyp der Variable auch für die Zukunft festgelegt.
$instance

<#

ComputerName       : MyServer
InstanceName       : MSSQLSERVER
Port               : 1433
NetworkProtocol    : Any
IsLocalHost        : False
FullName           : MyServer
FullSmoName        : MyServer
SqlComputerName    : [MyServer]
SqlInstanceName    : [MSSQLSERVER]
SqlFullName        : [MyServer]
IsConnectionString : False
Type               : Default
LinkedLive         : False
LinkedServer       :
InputObject        : MyServer

#>
```

Warum bezeichne ich DbaInstance als zentralen Datentyp? Alle Parameter der dbatools Befehle, in denen eine Instanz übergeben wird (diese Parameter haben typischerweise den Namen SqlInstance), sind mit dem Datentyp DbaInstance deklariert, wandeln daher den übergebenen Wert automatisch in diesen Datentyp um. Um also genau zu wissen, was an den Befehl übergeben wird, kann diese Umwandlung bereits vorher erfolgen. Gerade bei der Analyse von Verbindungsproblemen kann es sinnvoll sein, hier in kleinen Schritten vorzugehen.

Hier noch ein paar Beispiele, welche Zeichenketten in welcher Form interpretiert werden. Die Variable `$instances` wird hierbei als Array von Objekten des Datentyps DbaInstance deklariert:

```powershell
[DbaInstance[]]$instances = 'MyServer', 'MyServer.domain.local', 'MyServer\Inst123', 'MyServer\Inst123,50123', 'MyServer\Inst456:50456', $env:COMPUTERNAME, "$env:COMPUTERNAME,50678"
$instances | Format-Table -Property InputObject, ComputerName, InstanceName, Port, FullName, SqlFullName, IsLocalHost

<#

InputObject            ComputerName          InstanceName  Port FullName               SqlFullName             IsLocalHost
-----------            ------------          ------------  ---- --------               -----------             -----------
MyServer               MyServer              MSSQLSERVER   1433 MyServer               [MyServer]                    False
MyServer.domain.local  MyServer.domain.local MSSQLSERVER   1433 MyServer.domain.local  [MyServer.domain.local]       False
MyServer\Inst123       MyServer              Inst123          0 MyServer\Inst123       [MyServer\Inst123]            False
MyServer\Inst123,50123 MyServer              Inst123      50123 MyServer:50123\Inst123 [MyServer\Inst123]            False
MyServer\Inst456:50456 MyServer              Inst456      50456 MyServer:50456\Inst456 [MyServer\Inst456]            False
WIN10                  WIN10                 MSSQLSERVER   1433 WIN10                  [WIN10]                        True
WIN10,50678            WIN10                 MSSQLSERVER  50678 WIN10:50678            [WIN10]                        True

#>
```



### Herstellung einer Verbindung zu einer Instanz: Connect-DbaInstance

Für den weiteren Verlauf verwende ich nun die Informationen einer SQL Server-Instanz meiner Testumgebung. Wer eine ähnliche Testumgebung aufbauen möchte, findet [hier](https://blog.ordix.de/microsoft-sql-server-einrichten-einer-always-on-verfuegbarkeitsgruppe-mit-powershell-teil-1) weitere Informationen dazu.

```powershell
[DbaInstance]$SqlInstance = 'SRV1\SQL2016'
```

Jeder dbatools-Befehl, der den Parameter `SqlInstance` bereitstellt, wird in einem ersten Schritt eine Verbindung zu dieser Instanz aufbauen und dazu den Befehl `Connect-DbaInstance` verwenden. In vielen Befehlen taucht dazu genau diese Zeile auf:

```powershell
$server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
```

In meiner Testumgebung kann ich mich an den SQL Server-Instanzen mit meinem Windows-Account anmelden, benötige also kein `$SqlCredential`. Ich könnte damit aber auch eine Anmeldung unter einem bestimmten Login durchführen, das zeige ich später in diesem Artikel. Wenn keine Warnung ausgegeben wird, hat die Verbindung funktioniert und ich kann einige zentrale Informationen zur Verbindung anzeigen:

```powershell
$server

<#

ComputerName Name         Product              Version   HostPlatform IsAzure IsClustered ConnectedAs
------------ ----         -------              -------   ------------ ------- ----------- -----------
SRV1         SRV1\SQL2016 Microsoft SQL Server 13.0.5850 Windows      False   False       COMPANY\Administrator

#>
```

Das Attribut `Name` enthält dabei das Attribut `FullSmoName` aus meinem Objekt `$SqlInstance`. Den Datentyp von `$server` habe ich nicht festgelegt, er wird vom Befehl `Connect-DbaInstance` bestimmt. Schauen wir mal nach, welchen Datentyp `$server` bekommen hat:

```powershell
$server.GetType().FullName  # Microsoft.SqlServer.Management.Smo.Server
```

Die Methode `Name` würde hier nur "Server" ausgeben, daher verwende ich hier die Methode `FullName`.

Wir haben es hier also mit einem offiziellen, von Microsoft bereitgestellten Datentypen bzw. einer offiziellen Klasse zu tun, die Dokumentation findet sich [hier](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.server). Dahinter verbirgt sich "die komplette Instanz", über die verschiedenen Attribute und Methoden ist ein Zugriff auf fast alle Eigenschaften der Instanz sowie der angeschlossenen Datenbanken möglich. Einfache Abfragen sind bereits über die Methode `Query` möglich:

```powershell
$server.Query('SELECT @@SPID AS ServerProcessID')

<#

ServerProcessID
---------------
             54

#>
```

Und welchen Datentyp hat das Objekt, das von dieser Methode zurückgegeben wird?

```powershell
$server.Query('SELECT @@SPID AS ServerProcessID').GetType().FullName  # System.Data.DataRow
```

Wenn ich nur die Zahl haben möchte, kann ich auch direkt auf den Wert der Spalte zugreifen:

```powershell
$server.Query('SELECT @@SPID AS ServerProcessID').ServerProcessID  # 54
```

Warum habe ich gerade die SPID (Server Prozess ID) ausgeben lassen? Erzeugen wir eine weitere Verbindung:

```powershell
$server2 = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
$server2.Query('SELECT @@SPID AS ServerProcessID').ServerProcessID  # 54
```

Die Abfrage liefert die gleiche SPID, es wird also die gleiche Verbindung verwendet. Sind also `$server` und `$server2` identisch?

```powershell
$server2.Equals($server)  # False
```

Nein, wir haben zwei getrennte Objekte der Klasse `Microsoft.SqlServer.Management.Smo.Server`, die sich aber eine Verbindung "teilen". Das Stichwort lautet hier Connection Pooling, falls Sie mehr dazu recherchieren möchten.

Für uns hier ist im Moment nur wichtig, dass sich die Klasse `Microsoft.SqlServer.Management.Smo.Server` um das Verbindungsmanagement kümmert und nach Möglichkeit vorhandene Verbindungen wiederverwendet. Damit ist es auch kein Problem, wenn verschiedene Befehle von dbatools immer wieder `Connect-DbaInstance` aufrufen, um ein Objekt der Klasse `Microsoft.SqlServer.Management.Smo.Server` zu bekommen. Es werden dabei immer wieder neue Objekte erzeugt, die aber die gleiche Datenbankverbindung nutzen. Am Ende des Befehls wird das Objekt dann automatisch wieder gelöscht.

Es gibt jedoch eine weitere Möglichkeit, Connect-DbaInstance zu nutzen und ich werde dabei jetzt auch ein SQL Login zur Anmeldung nutzen:

```powershell
$myCredential = Get-Credential -Message 'SQL Login' -UserName 'myLogin'
[DbaInstance]$myInstance = 'SRV1\SQL2016'

# Falls es das Login noch nicht gibt, kann es an dieser Stelle angelegt werden:
New-DbaLogin -SqlInstance $myInstance -Login $myCredential.UserName -SecurePassword $myCredential.Password

# Falls die Warnung "SRV1\SQL2016 does not have Mixed Mode enabled" kommt, kann der Modus umgestellt werden:
$server = Connect-DbaInstance -SqlInstance $myInstance 
$server.LoginMode = 'Mixed'
$server.Alter()
Restart-DbaService -ComputerName $server.ComputerName -InstanceName $server.InstanceName -Force

# Jetzt sollten alle Voraussetzungen geschaffen sein und die Anmeldung funktionieren:
$myServer = Connect-DbaInstance -SqlInstance $myInstance -SqlCredential $myCredential
$myServer

<#

ComputerName Name         Product              Version   HostPlatform IsAzure IsClustered ConnectedAs
------------ ----         -------              -------   ------------ ------- ----------- -----------
SRV1         SRV1\SQL2016 Microsoft SQL Server 13.0.5850 Windows      False   False       myLogin

#>

# Schauen wir uns den folgenden Code an:
$server1 = Connect-DbaInstance -SqlInstance $myServer
$server2 = Connect-DbaInstance -SqlInstance $myServer

$server1, $server2

<#

ComputerName Name         Product              Version   HostPlatform IsAzure IsClustered ConnectedAs
------------ ----         -------              -------   ------------ ------- ----------- -----------
SRV1         SRV1\SQL2016 Microsoft SQL Server 13.0.5850 Windows      False   False       myLogin
SRV1         SRV1\SQL2016 Microsoft SQL Server 13.0.5850 Windows      False   False       myLogin

#>

$server1.Equals($myServer)  # True
$server2.Equals($myServer)  # True
$server1.Equals($server2)   # True
```

Wir haben dem Befehl `Connect-DbaInstance` als Wert für den Parameter `SqlInstance` nicht eine Zeichenkette oder ein Objekt der Klasse `DbaInstance` gegeben, sondern ein Objekt der Klasse `Microsoft.SqlServer.Management.Smo.Server`. Dieses Objekt repräsentiert bereits eine verbundene SQL Server-Instanz, die Angabe `SqlCredential` ist daher nicht notwendig. Denn in diesem Fall werden die (meisten) weiteren Parameter gar nicht beachtet und einfach nur das übergebene Objekt wieder zurückgegeben. Das haben wir mit `.Equals` überprüft, die verschiedenen Variablen verweisen alle auf ein und dasselbe Objekt.

Daher ist es möglich, die Verbindung zu der in einem Skript benötigen SQL Server-Instanz einmal zu Beginn des Skriptes herzustellen und dann immer wieder zu verwenden. Der Parameter `SqlCredential` ist dann auch nur beim Aufruf von `Connect-DbaInstance` notwendig und nicht bei den weiteren Befehlen, was die Lesbarkeit des Skriptes erhöhen kann.

Damit kann diese Zeile

```powershell
Invoke-DbaQuery -SqlInstance 'SRV1\SQL2016' -Query 'SELECT * FROM dbo.testdata'
```

auch so geschrieben werden:

```powershell
[DbaInstance]$myInstance = 'SRV1\SQL2016'
$myServer = Connect-DbaInstance -SqlInstance $myInstance
Invoke-DbaQuery -SqlInstance $myServer -Query 'SELECT * FROM dbo.testdata'
```

Die erste Zeile wandelt die Zeichenkette in ein Objekt der Klasse `DbaInstance` um.
Die zweite Zeile verwendet dieses Objekt um eine Verbindung mit der SQL Server-Instanz herzustellen und gibt ein Objekt der Klasse `Microsoft.SqlServer.Management.Smo.Server` zurück.
Die dritte Zeile verwendet dieses Objekt, um die Abfrage auf der SQL Server-Instanz auszuführen und liefert die entsprechenden Datenzeilen zurück.

Die Erstellung eines eigenen Objektes der Klasse `DbaInstance` hat vor allem dort Vorteile, wo im Laufe des Skriptes auf die einzelnen Elemente des Objektes, also beispielsweise den Computernamen oder den Port, zugegriffen wird. Auch das Attribut `IsLocalHost` kann sehr nützlich sein, es ist nur in der Klasse `DbaInstance` aber nicht in der Klasse `Microsoft.SqlServer.Management.Smo.Server` enthalten.



### Und wie schreibe ich meine Skripte?

Ich verwende beides, jeder Weg hat seine Berechtigung. Bei einfachen, kurzen Skripten verwende ich direkt den passenden Befehl und übergebe als `SqlInstance` eine Zeichenkette. Bei komplexeren Skripten, bei denen ich mehrere Befehle gegen die gleichen Instanzen absetze und möglicherweise mehr Logging oder mehr Möglichkeiten der Fehleranalyse benötige, trenne ich die Verbindung zur Instanz gerne von der Ausführung der Befehle.
