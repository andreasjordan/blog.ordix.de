# dbatools: Wie fange ich nur an?

Autor: Andreas Jordan (anj@ordix.de)

Veröffentlich unter: https://blog.ordix.de/dbatools-wie-fange-ich-nur-an


Wann immer ich eine Schulung zur Administration des Microsoft SQL Servers halte, erzähle ich von den Vorzügen des PowerShell-Moduls dbatools. Ich kann damit viele administrative Aufgaben erledigen, ohne mich per RDP auf dem Server einzuwählen und ohne das SQL Server Management Studio zu starten. Gerade die Administration einer Vielzahl von Instanzen wird so von einer zentralen Stelle und mit einem einheitlichen Kontext möglich. Zudem kann ich mit einzelnen, einfachen und lesbaren Befehlen für Abfragen oder kleinere administrative Aufgaben starten. Später kann ich dann darauf aufbauend komplexe Programme schreiben, da PowerShell nicht nur eine Skriptsprache sondern eine komplette objektorientierte Programmiersprache ist. 

Wenn ich dann genug Beispiele gezeigt habe, kommt irgendwann die Frage: Und wie erlerne ich den Umgang mit dbatools?

Natürlich werde ich diese Frage meinen Teilnehmern auch in Zukunft gerne mündlich und individuell beantworten. Ich möchte ihnen aber auch einen Link mit an die Hand geben können, den Link zu genau diesem Artikel. Daher stelle ich im Folgenden ein paar Befehle zusammen, die alle eines gemeinsam haben: Wir werden nur Informationen von den SQL-Server-Instanzen abrufen, wir werden keine Konfiguration und keine Daten verändern. 



### Von wo aus?

Zunächst ein paar Worte zum Ort, an dem wir PowerShell starten wollen und zur PowerShell-Version. Da wir mit mehreren SQL-Server-Instanzen auf (meist) mehreren Servern arbeiten wollen, sehe ich zwei gleichberechtigte Möglichkeiten: Auf dem Arbeitsplatz-PC des Administrators (also vermutlich Windows 10) oder auf einem zentralen Verwaltungsserver (also vermutlich Windows Server 2016). In beiden Fällen haben wir es mit PowerShell 5.1 zu tun, denn die wenigsten Unternehmen werden aktuell schon PowerShell 7 nutzen. Das ist auch gut so, alle Befehle der dbatools sind mit PowerShell 5.1 getestet, mit PowerShell 7 funktionieren einige Befehle leider bisher noch nicht.



### Mit welchem Programm?

Wenn PowerShell 5.1 auf Ihrem Computer installiert ist, haben Sie im Startmenü zwei Einträge: "PowerShell" und "PowerShell ISE". Das erste ist eine klassische Shell wie auch "cmd.exe" und eignet sich aus meiner Sicht für erfahrene Nutzer, die schnell mal ein paar Befehle absetzen wollen. Anfängern würde ich immer die "PowerShell ISE" empfehlen, weil Sie hier einen integrierten Editor haben. Sie haben die Befehle übersichtlich im Blick, können diese einzeln oder in Blöcken ausführen und bekommen eine umfangreiche Hilfe in Form von Dropdown-Listen bei der Eingabe von Befehlen und Parametern. Am Ende können Sie Ihre Arbeit speichern und sich so eine individuelle Skriptsammlung aufbauen. Eine Warnung muss ich Ihnen allerdings mit auf den Weg geben: Einige Befehle regieren in der "ISE" etwas anders als in der klassischen PowerShell. Und was doch sehr stört: Wenn sie die "ISE" schließen, so bleibt sie leider im Hintergrund weiter aktiv und auch die Verbindungen zu den SQL-Server-Instanzen werden somit nicht sauber geschlossen.

Daher sollten Sie irgendwann auf das Programm wechseln, dass ich persönlich aktuell für die Arbeit mit PowerShell verwende und empfehle: [Visual Studio Code](https://code.visualstudio.com/) (VSCode). Aber ich empfehle einen Umstieg nicht von Anfang an, denn die Einrichtung von VSCode an die persönlichen Bedürfnisse kostet auch wieder Zeit &ndash; und jetzt sollen Sie sich ja erstmal in dbatools einarbeiten, immer schön einen Schritt nach dem anderen.  



### Wie installiere ich dbatools?

Zur Installation finden Sie auf der [offiziellen Seite](https://dbatools.io/download/) sowie in meinem Artikel [Wie installiere ich das PowerShell-Modul dbatools?](2021_04_24_Wie_installiere_ich_das_PowerShell-Modul_dbatools.md) die wichtigsten Informationen. 

Bei weiteren Fragen empfehle ich den Kanal "[#dbatools](https://sqlcommunity.slack.com/#dbatools)" des Workspaces "[SQL Server Community](https://sqlcommunity.slack.com/)" auf der Plattform [Slack](https://slack.com/intl/de-de/). Wer bisher noch nichts von der Plattform Slack gehört hat oder enttäuscht ist, dass er bei der Verwendung der Links aus dem ersten Satz immer auf einer Anmeldeseite gelandet ist, der verwende bitte einfach die Adresse [aka.ms/sqlslack](http://aka.ms/sqlslack), um automatisch eine Einladung zum Workspace "[SQL Server Community](https://sqlcommunity.slack.com/)" zu erhalten. Wer keine Kurz-URLs mag, hier noch die lange URL: https://sqlcommunity.slack.com/join/shared_invite/zt-o91sc6c5-~4~EAqtx8DPe3q6nYAyRrg#/. Dort kann jeder Fragen zur Verwendung von dbatools stellen, es sind immer langjährige Nutzer und auch Autoren des Moduls anwesend, um Hilfestellung zu geben. Zudem gibt es dort auch Kanäle für allgemeine Fragen zu SQL oder PowerShell.



### Mit welchem Konto?

Vor dem ersten Befehl ist aber noch die Frage zu klären: Mit welchem Konto wollen wir denn die Verbindung zu den SQL-Server-Instanzen herstellen? Grundsätzlich sehe ich drei Möglichkeiten. Am einfachsten ist es, wenn das Windows-Konto, mit dem die PowerShell gestartet wird, direkt administrative Rechte auf den SQL-Server-Instanzen hat. Dann sind keine Vorbereitungen notwendig, wir könnten gleich starten. Aber ich kenne einige Unternehmen, in denen die Administratoren zwei Konten haben: Ein normales Konto für die tägliche Arbeit und ein administratives Konto für die Zugänge zu den Serversystemen. Das wäre dann Möglichkeit Zwei: Ein eigenes Windows-Konto, mit dem zwar nicht die PowerShell gestartet wird, das aber administrative Rechte auf den SQL-Server-Instanzen hat. Möglichkeit Drei ist eine SQL-Server-Anmeldung mit administrativen Rechten. Aus Sicherheitsgründen empfehle ich immer Möglichkeit Zwei oder Drei und möchte daher auch hier diese Möglichkeiten nutzen. Wie wir gleich sehen werden, unterscheiden sich die beiden Möglichkeiten gar nicht, wenn wir die dbatools verwenden. Sie können also auch später noch zwischen diesen Möglichkeiten wechseln, ohne den Code anpassen zu müssen.



### Die ersten Zeilen Code

Jetzt aber erst einmal ein paar Zeilen Code, die Erklärung folgt dann im Anschluss:

```powershell
$ErrorActionPreference = 'Stop'
Import-Module -Name dbatools
[DbaInstance[]]$myInstances = 'SRV1', 'SRV1\SQL2016', 'SRV2.mydomain.com\SQL2019,14330'
$myAdminCredential = Get-Credential -Message 'SQL Server Administrator' -UserName 'MyAdminUsername'
```

Die erste Zeile gehört für mich zu jedem PowerShell-Skript. Wenn ich später das komplette Skript oder auch nur mehr als einen Befehl ausführe, dann sorgt ein fehlgeschlagener Befehl für den Abbruch des Skriptes oder der gerade ausgeführten Befehle. Zwar erzeugen die meisten Befehle aus dem Modul dbatools nur Warnungen und brechen nicht ab, das kann aber über den optionalen Parameter `-EnableException` jeweils pro Befehl angepasst werden. So ist das Skript bereits von Anfang an so aufgebaut, dass es später zu einem komplexen Programm erweitert werden kann.

Die zweite Zeile importiert das Modul dbatools. Man kann auch sagen, dass das Modul geladen wird. Das kann durchaus ein paar Sekunden dauern, es werden unter anderem die offiziellen DLLs von Microsoft zur Verbindung mit den SQL-Server-Instanzen geladen. Ich bin generell ein Freund davon, die benötigten Module gleich zu Beginn eines Skriptes zu importieren. Das ist zwar meist nicht notwendig, da das Modul bei der ersten Verwendung eines Befehls aus diesem Modul automatisch importiert wird, aber ich sehe das immer auch als eine Dokumentation der Abhängigkeiten. Dem Leser ist so schnell klar, welche Module zur Ausführung des Skriptes benötigt werden. In unserem konkreten Fall ist es aber zwingend notwendig, das Modul zunächst zu importieren. Denn wir wollen noch vor der Verwendung des ersten Befehls einen Datentypen &ndash; also eine Klasse &ndash; des Moduls nutzen.

In der dritten Zeile müssen Sie nun diejenigen Instanzen angeben, mit denen Sie den ersten Test machen wollen. Nehmen Sie vielleicht nicht gleich alle auf einmal, aber zwei oder drei sollten es schon sein. Ich habe hier auch gleich verschiedene Möglichkeiten gewählt, damit Sie sehen, was möglich ist. Im Prinzip geben Sie die Instanzen genau so an, wie im SQL Server Management Studio. Falls Sie noch nicht so viel Erfahrung mit PowerShell oder der Programmierung haben: `[DbaInstance[]]` deklariert die Variable `$myInstances` als Array von Elementen des Datentyps `DbaInstance`, einer der zentralen Datentypen des Moduls dbatools. Mehr Informationen finden Sie in meinem Artikel [dbatools im Detail: Was passiert beim Aufruf von Invoke-DbaQuery?](2021_03_29_dbatools_im_Detail_-_Was_passiert_beim_Aufruf_von_Invoke-DbaQuery.md).

Die vierte Zeile öffnet einen Dialog, der Sie nach dem Passwort für den Zugang zu den SQL-Server-Instanzen fragt. Hier sollten Sie statt "MyAdminUsername" natürlich den bei Ihnen zu verwendenden Benutzernamen eintragen. Das kann entweder ein Domain-Konto oder der Name einer SQL-Server-Anmeldung (Login) sein. Domain-Konten müssen dabei in der Form "DOMAIN\Nutzername" angegeben werden. Wie ich bereits angekündigt habe: Die Wahl des Zugangs wirkt sich nur auf die Form des Parameters `-UserName` aus, mehr Unterschiede gibt es nicht.



### Jetzt aber mal eine Verbindung bitte

Das war die Vorarbeit, da mussten noch Anpassungen vorgenommen werden. Ab hier können Sie alle Zeilen einfach so übernehmen &ndash; aber natürlich auch später nach Ihren Wünschen anpassen.

```powershell
$servers = Connect-DbaInstance -SqlInstance $myInstances -SqlCredential $myAdminCredential
```

Hiermit wird jetzt zu jeder in der Variablen `$myInstances` hinterlegten Instanz eine Verbindung aufgebaut und dabei die in `$myAdminCredential` enthaltenen Zugangsdaten verwendet. Das ist eine spannende Stelle, hier entscheidet sich, ob Sie alles richtig konfiguriert haben. Kommt es hier zu Fehlermeldungen, so müssen Sie diese zunächst analysieren und die Gründe dafür beseitigen. Wie schon oben erwähnt: Bei Problemen sprechen Sie uns an &ndash; vielleicht ist es ja nur eine Kleinigkeit.

Da ich immer wieder bei der Weiterentwicklung der dbatools unterstütze und so vielfach "im Quellcode unterwegs bin", habe ich die dort verwendeten Namenskonventionen zum Teil übernommen. So wird intern im Code eine geöffnete Verbindung zu einer SQL-Server-Instanz immer in einer Variablen mit dem Namen `$server` gespeichert. Hier habe ich das Mehrzahl-s angefügt, da es ja mehrere Verbindungen sind. So ist es später auch einfacher, alle Verbindungen nacheinander mit `foreach ($server in $servers) { ... }` zu durchlaufen. Sie können und sollten jedoch Ihr eigenes Namensschema für die verschiedenen Variablen finden, bzw. das in Ihrem Unternehmen übliche Schema auch für die Arbeit mit dbatools übernehmen.

Die Variable `$servers` kann ab jetzt überall dort verwendet werden, wo ein Parameter `-SqlInstance` die zu verwendende Instanz abfragt. Auf die zusätzliche Angabe des Parameters `-SqlCredential` kann dabei verzichtet werden, da die Verbindung bereits hergestellt wurde. Zu den Hintergründen darf ich hier noch einmal auf meinen Artikel [dbatools im Detail: Was passiert beim Aufruf von Invoke-DbaQuery?](2021_03_29_dbatools_im_Detail_-_Was_passiert_beim_Aufruf_von_Invoke-DbaQuery.md) verweisen.



### Zentrale Informationen zu den Instanzen anzeigen

Es wird Zeit, mal ein paar Informationen anzuzeigen &ndash; dafür machen wir das Ganze hier ja schließlich. Starten möchte ich mit ein paar Informationen über die Instanzen. Jeder ist an anderen Informationen interessiert, daher möchte ich zunächst einmal zeigen, wie Sie sich die Liste der möglichen Informationen anzeigen können.

Vorab noch ein Hinweis. Die bisher genannten fünf Zeilen Code werden Sie jedes Mal ausführen müssen, damit Sie mit den Instanzen arbeiten können. Ab jetzt sind alle Zeilen Code immer optional, Sie werden nur diejenigen ausführen müssen, die für Ihre jeweilige Aufgabe notwendig sind.

```powershell
$servers | Get-Member
```

Der Befehl `Get-Member` listet unter anderem alle Eigenschaften der übergebenen Objekte auf, sie sind in der Liste als "Property" gekennzeichnet. Tauschen Sie die im Folgenden verwendeten Eigenschaften also gerne gegen andere aus und lernen Sie so mehr über Ihre SQL-Server-Instanzen.

```powershell
$servers | Select-Object -Property ComputerName, Name, Product, ProductLevel, ProductUpdateLevel, VersionString, Edition, LoginMode, Collation | Out-GridView
```

Der Befehl `Select-Object` übernimmt auf der Pipeline Objekte und übergibt diese über die nächste Pipeline an den nächsten Befehl. Der Parameter `-Property` sorgt dafür, dass diese Objekte nun nur noch die angegebenen Eigenschaften haben. Wenn wir uns als Datenbankexperten also ein SELECT-Statement vorstellen, so ist das die SELECT-Klausel. Der Befehl heißt also nicht nur so ähnlich, er funktioniert auch so ähnlich.

Der Befehl `Out-GridView` startet ein weiteres Fenster, das Sie vielleicht entfernt an die Ausgabe im SQL Server Management Studio erinnert. Aber wir haben hier viel mehr Möglichkeiten. Am oberen Rand haben Sie die Möglichkeit der Filterung, die wie eine Volltextsuche funktioniert &ndash; probieren Sie es einfach mal aus. Zudem können Sie durch Klick auf eine Spaltenüberschrift ganz einfach nach dieser Spalte aufsteigend oder absteigend sortieren. Versuchen Sie das mal im SQL Server Management Studio...

Mit dieser Ansicht können Sie sehr schnell sehen, ob eine der Instanzen "aus der Reihe tanzt", also anders konfiguriert ist als die anderen. Mir geht es hier gar nicht um einen automatisierten Test, das ist nicht der Fokus dieses Artikels, da brauchen wir etwas mehr PowerShell-Code. Es geht mir hier um das schnelle visuelle Erfassen, um das Gegenüberstellen der verschiedenen Instanzen, um das Kennenlernen der Instanzen. Vielleicht fallen die Instanzen ja erst seit Kurzem in Ihren Zuständigkeitsbereich, da ist dies eine gute Möglichkeit, sich einen Überblick zu verschaffen.



### Weiter geht es: Datenbanken und Logins

In den dbatools gibt es für jeden Aspekt im SQL Server einen passenden Befehl, ich kann und will hier gar nicht alle vorstellen. Schaue Sie doch mal in die [Dokumentation](https://docs.dbatools.io/) und suchen dort nach "Get-", das gibt Ihnen einen guten Überblick.

Ich will Ihnen hier zunächst nur zwei Bereiche vorstellen und dabei immer auch wieder etwas neuen PowerShell-Code verwenden. Starten wir mit den Datenbanken.

```powershell
$databases = Get-DbaDatabase -SqlInstance $servers -ExcludeSystem
$databases | Select-Object -Property SqlInstance, Name, Owner, Collation, CompatibilityLevel, RecoveryModel, PageVerify | Out-GridView
```

Auch wenn die Datenbanken über `$servers.Databases` ermittelt werden können, so verwende ich hier den dbatools-Befehl  `Get-DbaDatabase`, da dieser viele nützliche Parameter hat, um die Auswahl der Datenbanken einzuschränken. Als Beispiel verwende ich hier die Möglichkeit, die Systemdatenbanken auszublenden. Ich wiederhole mich noch einmal: Schauen Sie sich mit `Get-Member` die Eigenschaften der Datenbank-Objekte an und erweitern Sie die auszugebenden Eigenschaften, um Ihre Datenbanken besser kennenzulernen.

```powershell
$logins = Get-DbaLogin -SqlInstance $servers -ExcludeLogin 'NT AUTHORITY\SYSTEM' -ExcludeFilter 'NT SERVICE\*', '##*##'
$logins | Select-Object -Property SqlInstance, Name, LoginType, @{ name = 'Roles' ; expression = { Get-DbaServerRoleMember -SqlInstance $_.Parent -Login $_.Name | Select-Object -ExpandProperty Role } } | Out-GridView
```

Ja, das sind nur zwei Zeilen Code, allerdings diesmal zwei recht lange Zeilen. In der ersten Zeile nutze ich wieder den passenden `Get-Dba`-Befehl, um die Logins zu ermitteln. Auch hier verwende ich Parameter, um die Rückgabe einzuschränken. Denn in den meisten Fällen interessieren mich die vordefinierten Logins nicht und versperren nur den Blick auf die relevanten Logins. Mit `-ExcludeLogin` können einzelne Logins ausgeschlossen werden, dieser Parameter nimmt aber auch eine kommaseparierte Liste entgegen. Bei der Nutzung von `-ExcludeFilter` können die typischen Wildcards `*` und `?` verwendet werden, da intern die Prüfung mit `-NotLike` durchgeführt wird. Damit habe ich hier die Möglichkeit, alle Dienstkonten zu filtern, unabhängig von deren Namen. Zudem filtere ich die [internen zertifikatsbasierten Logins](https://docs.microsoft.com/de-de/sql/relational-databases/security/authentication-access/principals-database-engine#certificate-based-sql-server-logins) heraus, deren Namen von doppelten Nummernzeichen (##) eingeschlossen sind. Noch ein Hinweis für alle, deren System nicht in englischer Sprache installiert ist: Die Zeichenketten `NT AUTHORITY\SYSTEM` und `NT SERVICE` müssen dann entsprechend der verwendeten Sprache angepasst werden.

Kommen wir zur zweiten Zeile, in der ich wieder einige Eigenschaften der Logins über `Out-GridView` ausgebe. Allerdings möchte ich zusätzlich auch noch die Serverrollen angeben, in denen die Logins Mitglied sind. Die Mitgliedschaft in einer Rolle ist keine Eigenschaft der Logins, auch wenn das in der grafischen Oberfläche des SQL Server Management Studios so aussieht. In der Rolle sind die jeweiligen Mitglieder hinterlegt, ich muss also die Mitglieder aller Rollen ermitteln und dort das gerade verarbeitete Login suchen. Genau für diese Aufgabe gibt es wieder einen dbatools-Befehl: `Get-DbaServerRoleMember`. Die Angabe der `-SqlInstance` ist immer erforderlich, es muss ja die richtige Instanz befragt werden. Dann allerdings habe ich über die optionalen Parameter `-ServerRole` und `-Login` die Wahl, ob die Rückgabe auf bestimmte Rollen oder Logins eingeschränkt werden soll. Ich kann hier also mit der Angabe des Logins alle Rollen zurückgeben lassen, in denen das Login Mitglied ist. Da ich mich nicht für das komplette Objekt interessiere, das alle Aspekte der Mitgliedschaft enthält, nutze ich `Select-Object` mit dem Parameter `-ExpandProperty`, um nur die Namen der Rollen zu erhalten. Nachdem wir nun wissen, wie für ein einzelnes Login die Liste der Rollen ermittelt wird, müssen wir das jetzt für alle Logins in `$logins` durchführen. Genau hier kommen nun die [berechneten Eigenschaften](https://docs.microsoft.com/de-de/powershell/module/microsoft.powershell.core/about/about_calculated_properties) ins Spiel, die auch im [Beispiel 10 von Select-Object](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/select-object#example-10--create-calculated-properties-for-each-inputobject) beschrieben werden. Hiermit erzeuge ich eine neue Eigenschaft, deren Namen ich über `name` (oder alternative auch `label` sowie den Kurzformen `n` oder `l`) angebe und deren Berechnungsformel ich über `expression` (oder die Kurzform `e`) angebe. Das einzelne gerade verarbeitete Objekt kann ich dabei über die Variable `$_` erreichen und so den Namen des gerade verarbeiteten Logins über `$_.Name` ermitteln. Bei der Betrachtung der Eigenschaften der SQL-Server-Instanz haben wir gesehen, dass über das Instanz-Objekt auch untergeordnete Objekte wie Datenbanken oder Logins erreicht werden können. Die verschiedenen Aspekte sind also in einem Objektbaum angeordnet, der in etwa der Ansicht im SQL Server Management Studio entspricht. Neben dem Zugriff auf untergeordnete Objekte besteht über die Eigenschaft `.Parent` immer auch der Zugriff auf das übergeordnete Objekt. Hier kann ich also über `$_.Parent` auf die SQL-Server-Instanz zugreifen, in der sich das gerade verarbeitete Login befindet. 



### Zum Abschluss eine komplexere Aufgabe: Fehlgeschlagene Jobs ermitteln

Gerade für den Fall, dass Sie Informationen über fehlgeschlagene Jobs des SQL-Server-Agenten nicht an einer zentralen Stelle sammeln, dürfte dieses Beispiel für Sie interessant sein.

Ich möchte zu jedem Job, dessen letzte Ausführung fehlgeschlagen ist, die Fehlermeldung des Jobs sowie des letzten ausgeführten Schrittes ermitteln. Zudem hätte ich gerne neben dem Zeitpunkt der letzten fehlgeschlagenen Ausführung auch den Zeitpunkt der letzten erfolgreichen Ausführung, ich möchte also wissen, wie lange der Job schon nicht mehr funktioniert.

```powershell
$failedJobs = Get-DbaAgentJob -SqlInstance $servers | Where-Object -FilterScript { $_.LastRunOutcome -eq 'Failed' }
$failedJobInfos = foreach ($job in $failedJobs) {
    # $job = $failedJobs | Select-Object -First 1
    $lastFailedJobHistory = Get-DbaAgentJobHistory -SqlInstance $job.Parent.Parent -Job $job.Name -ExcludeJobSteps |
        Sort-Object -Property RunDate -Descending | 
        Select-Object -First 1
    $lastFailedJobStepHistory = Get-DbaAgentJobHistory -SqlInstance $job.Parent.Parent -Job $job.Name |
        Where-Object -FilterScript { $_.StepID -ne 0 } |
        Sort-Object -Property RunDate -Descending | 
        Select-Object -First 1
    $lastGoodRunDate = Get-DbaAgentJobHistory -SqlInstance $job.Parent.Parent -Job $job.Name -OutcomeType Succeeded -ExcludeJobSteps |
        Sort-Object -Property RunDate -Descending | 
        Select-Object -ExpandProperty RunDate -First 1
    [PSCustomObject]@{
        SqlInstance       = $job.SqlInstance
        Name              = $job.Name
        LastGoodRunDate   = $lastGoodRunDate
        LastFailedRunDate = $lastFailedJobHistory.RunDate
        JobMessage        = $lastFailedJobHistory.Message
        JobStepMessage    = $lastFailedJobStepHistory.Message
    }
}
$failedJobInfos | Out-GridView -Title 'Informationen zu fehlgeschlagenen Jobs'
```

Den Code habe ich dabei eher wie ein Programm und weniger wie ein Skript strukturiert. Was ich damit meine? Ich verwende mehr Variablen, zudem mit `foreach` eine klassische Schleife. Ich könnte in einem nächsten Schritt noch zusätzliches Logging oder eine Fehlerbehandlung einbauen. Auch kann ich hier während der Programmierung oder der Weiterentwicklung Schritt für Schritt vorgehen und mir immer die Zwischenergebnisse ansehen und analysieren. So ist die auskommentierte Anweisung `$job = $failedJobs | Select-Object -First 1` (wenn in `$failedJobs` auf jeden Fall mehr als ein Job enthalten ist, würde auch `$job = $failedJobs[0]` funktionieren) eine Anweisung, die ich bei jeder `foreach`-Schleife immer gleich mitschreibe und auskommentiere. Ich kann diesen Code markieren und ausführen, um damit den ersten Schleifendurchlauf zu simulieren. Jetzt funktionieren alle Zeilen innerhalb der Schleife auch einzeln und ich kann die einzelnen Schritte testen. Gerade bei der Verarbeitung von großen Datenmengen halte ich es für wichtig, die einzelnen Schritte mit wenigen (oder einzelnen) Datensätzen zu testen.

In der ersten Zeile verwende ich `Where-Object`, um die von `Get-DbaAgentJob` gelieferten Objekte zu filtern und nur diejenigen in `$failedJobs` zu speichern, bei denen die Eigenschaft `LastRunOutcome` dem Wert "Failed" entspricht. Da wir alle aus der Datenbankadministration kommen: Ja, das funktioniert wie die WHERE-Klausel, ich könnte hier weitere Bedingungen mit `-and` und `-or` anfügen. Dabei dann immer an die evtl. notwendigen Klammern denken, ganz wie beim klassischen SQL. Deshalb verwende ich auch gerne die Syntax mit dem Parameter `-FilterScript`, bei dem ich wie schon in den vorherigen Beispielen mit `$_` auf das gerade verarbeitete Objekt zugreifen kann. Zur alternativen Syntax verweise ich an dieser Stelle mal auf die [Dokumentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/where-object).

In der zweiten Zeile verwende ich die Ihnen vielleicht auch aus anderen Programmiersprachen bekannte Schleife `foreach`, die in PowerShell allerdings auch in einer Zuweisung (hier: `$failedJobs =`) verwendet werden kann. Dabei werden alle Ausgaben, die innerhalb der Schleife durchgeführt werden, dieser Variablen zugewiesen. Wir werden das am Ende der Schleife nutzen, um PowerShell-Objekte zu erzeugen und damit in der Variable zu speichern.

Zunächst belegen wir in der Schleife jedoch drei Variablen. Die ersten beiden enthalten dabei jeweils Objekte aus der Rückgabe von `Get-DbaAgentJobHistory`. Zu beachten ist hier, dass in der Hierarchie der Objekte zwischen "[Job](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.agent.job)" und "[Server](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.server)" noch die Ebene "[JobServer](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.agent.jobserver)" liegt (ich habe Ihnen mal die Dokumentation der jeweiligen Klassen verlinked), wir also "zwei Schritte nach oben" müssen, um an die Instanz zu kommen. Wenn wir nur Informationen über den Job benötigen, können wir die einzelnen Schritte mit `-ExcludeJobSteps` ausschließen, für die Informationen über die einzelnen Schritte benötigen wir einen zusätzlichen Filterschritt. Der Job selbst hat dabei die `StepID` 0 und kann so herausgefiltert werden. Anschließend sortieren wir anhand der Eigenschaft `RunDate` absteigend (das wäre in SQL ein `ORDER BY RunDate DESC`) und selektieren nur den ersten so gefundenen Datensatz (das wäre in SQL ein `SELECT TOP 1`). Das ist dann der letzte ausgeführte Schritt des aktuell verarbeiteten Jobs und sollte somit Informationen über die Ursache des Fehlschlags enthalten. Bei der dritten Variable (`$lastGoodRunDate`) filtern wir direkt beim Aufruf von `Get-DbaAgentJobHistory` mit `-OutcomeType Succeeded` auf die erfolgreichen Ausführungen, sortieren wieder nach `RunDate` und selektieren den ersten Datensatz. Allerdings verwenden wir hier zudem `-ExpandProperty RunDate`, um nicht das ganze Objekt sondern nur das Datum zu bekommen.

Damit sind alle benötigten Informationen ermittelt, wir müssen diese jetzt nur noch "in Form bringen". Dabei eignen sich aus meiner Sicht Objekte am Besten, da wir deren Verarbeitung schon gewohnt sind, denn alle PowerShell-Befehle liefern Objekte zurück. Und mit `[PSCustomObject]` bietet PowerShell eine generische Klasse, bei der wir die Eigenschaften nach unseren Wünschen gestalten können. Die Syntax lautet dabei einfach `[PSCustomObject]@{ Eigenschaft1 = Wert1 ; Eigenschaft2 = Wert2 }`. Ich verwende oben im Beispiel zudem Zeilenumbrüche, um die Lesbarkeit zu erhöhen, dabei kann dann auf `;` verzichtet werden. Für mehr Informationen kann ich Ihnen diesen Artikel von [Kevin Marquette](https://twitter.com/KevinMarquette) empfehlen, der in die Dokumentation bei Microsoft integriert wurde: [Was Sie schon immer über PSCustomObject wissen wollten](https://docs.microsoft.com/de-de/powershell/scripting/learn/deep-dives/everything-about-pscustomobject).

Damit werden für jeden Job die gewünschten Informationen in einem Objekt zusammengestellt und gemeinsam in der Variablen `$failedJobInfos` gespeichert. Deren Inhalt können wir uns dann wie gewohnt mit `Out-GridView` anzeigen lassen.

Zum Abschluss möchte ich Ihnen zwei weitere Möglichkeiten zeigen, den Code zu gestalten. Im ersten Fall werden wir keine einzige Variable belegen und alles in einer einzigen Anweisung ausführen. Statt der `foreach`-Schleife verwende ich dabei den `ForEach-Object`-Befehl, den ich in eine Pipeline-Verarbeitung integrieren kann:

```powershell
Get-DbaAgentJob -SqlInstance $servers |
    Where-Object -FilterScript { $_.LastRunOutcome -eq 'Failed' } |
    ForEach-Object -Process {
        [PSCustomObject]@{
            SqlInstance       = $_.SqlInstance
            Name              = $_.Name
            LastGoodRunDate   = Get-DbaAgentJobHistory -SqlInstance $_.Parent.Parent -Job $_.Name -OutcomeType Succeeded -ExcludeJobSteps |
                Sort-Object -Property RunDate -Descending | 
                Select-Object -ExpandProperty RunDate -First 1
            LastFailedRunDate = Get-DbaAgentJobHistory -SqlInstance $_.Parent.Parent -Job $_.Name -ExcludeJobSteps |
                Sort-Object -Property RunDate -Descending | 
                Select-Object -ExpandProperty RunDate -First 1
            JobMessage        = Get-DbaAgentJobHistory -SqlInstance $_.Parent.Parent -Job $_.Name -ExcludeJobSteps |
                Sort-Object -Property RunDate -Descending | 
                Select-Object -ExpandProperty Message -First 1
            JobStepMessage    = Get-DbaAgentJobHistory -SqlInstance $_.Parent.Parent -Job $_Name |
                Where-Object -FilterScript { $_.StepID -ne 0 } |
                Sort-Object -Property RunDate -Descending | 
                Select-Object -ExpandProperty Message -First 1
        }
} | Out-GridView -Title 'Informationen zu fehlgeschlagenen Jobs'
```

Im zweiten Fall verwende ich die bereits aus dem Beispiel mit den Logins bekannten berechneten Eigenschaften von `Select-Object`:

```powershell
Get-DbaAgentJob -SqlInstance $servers |
    Where-Object -FilterScript { $_.LastRunOutcome -eq 'Failed' } |
    Select-Object -Property SqlInstance, Name, 
        @{ name = 'LastGoodRunDate' ; expression = { 
            Get-DbaAgentJobHistory -SqlInstance $_.Parent.Parent -Job $_.Name -OutcomeType Succeeded -ExcludeJobSteps |
                Sort-Object -Property RunDate -Descending | 
                Select-Object -ExpandProperty RunDate -First 1
            }
        },
        @{ name = 'LastFailedRunDate' ; expression = {
            Get-DbaAgentJobHistory -SqlInstance $_.Parent.Parent -Job $_.Name -ExcludeJobSteps |
                Sort-Object -Property RunDate -Descending | 
                Select-Object -ExpandProperty RunDate -First 1
            }
        },
        @{ name = 'JobMessage' ; expression = {
            Get-DbaAgentJobHistory -SqlInstance $_.Parent.Parent -Job $_.Name -ExcludeJobSteps |
                Sort-Object -Property RunDate -Descending | 
                Select-Object -ExpandProperty Message -First 1
            }
        },
        @{ name = 'JobStepMessage' ; expression = {
            Get-DbaAgentJobHistory -SqlInstance $_.Parent.Parent -Job $_Name |
                Where-Object -FilterScript { $_.StepID -ne 0 } |
                Sort-Object -Property RunDate -Descending | 
                Select-Object -ExpandProperty Message -First 1
            }
        } |
    Out-GridView -Title 'Informationen zu fehlgeschlagenen Jobs'
```

Damit habe ich Ihnen hoffentlich einen ersten Einblick in die Arbeit mit dbatools geben können. Jetzt sind Sie am Zug. Installieren Sie dbatools und lernen Sie Ihre SQL-Server-Instanzen neu kennen. Lassen Sie sich weitere Eigenschaften anzeigen, verwenden Sie weitere Befehle. Keine Angst: Alle Befehle, die mit `Get-Dba` beginnen, lesen lediglich Informationen aus, es wird nichts verändert.
