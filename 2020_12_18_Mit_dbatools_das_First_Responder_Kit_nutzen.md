# Mit dem PowerShell Modul dbatools das SQL Server First Responder Kit nutzen

Autor: Andreas Jordan (anj@ordix.de)

Veröffentlich unter: https://blog.ordix.de/mit-dem-powershell-modul-dbatools-das-sql-server-first-responder-kit-nutzen


Das SQL Server First Responder Kit von Brent Ozar sollte den meisten Datenbank Administratoren bekannt sein, alle anderen schauen bitte [auf der Webseite von Brent Ozar](https://www.brentozar.com/first-aid/) oder [direkt im entsprechenden GitHub Repository](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit) vorbei.

Das PowerShell Modul dbatools ist vielleicht noch nicht jedem bekannt, insbesondere wenn man bisher keine Berührungspunkte mit PowerShell hatte oder voll und ganz auf das SQL Server Management Studio setzt. Die [Webseite](https://dbatools.io/) ist vor kurzem auf GitHub Pages umgezogen, daher kann es an der einen oder anderen Stelle noch zu Problemen kommen, die [Dokumentation](https://docs.dbatools.io/) sollte aber auf jeden Fall funktionieren. Bei allen Fragen rund um dbatools können Sie sich gerne an uns wenden, wir setzen das Modul inzwischen bei einigen Kunden erfolgreich ein.

Heute möchte ich zeigen, wie die Prozedur sp_Blitz aus dem SQL Server First Responder Kit mit dbatools ausgeführt werden kann und welche Vorteile die Verarbeitung der Ergebnisse mit PowerShell haben kann.

Starten wir mit dem Import des Moduls. Auch wenn in den aktuellen PowerShell Versionen alle benötigten Module bei der ersten Verwendung der entsprechenden Kommandos automatisch geladen werden, empfehle ich weiterhin das explizite Laden aller benötigten Module gleich zu Beginn des Skriptes. So steht schon früh fest, ob alle Module erfolgreich geladen werden konnten und es ist später sofort sichtbar, welche Module für den Einsatz des Skriptes benötigt werden.

Anschließend verbinden wir uns mit der zu analysierenden SQL Server Instanz und können die resultierende Verbindung ganz einfach für alle folgenden Aufrufe verwenden. Ich verwende hier die Windows Authentifizierung und geben daher nur Server- und Instanzname an, aber selbstverständlich ist auch eine Anmeldung mit einem SQL Server Login möglich, zu Details schauen Sie bitte in die [Dokumentation](https://docs.dbatools.io/#Connect-DbaInstance). 

    Import-Module -Name dbatools
	$server = Connect-DbaInstance -SqlInstance SRV1\SQL2016

Falls Sie das SQL Server First Responder Kit noch nicht installiert haben oder aktualisieren wollen, geht das auch mit dem PowerShell Modul dbatools. Zu weiteren Optionen des Befehls verweise ich wieder auf die [Dokumentation](https://docs.dbatools.io/#Install-DbaFirstResponderKit).

	Install-DbaFirstResponderKit -SqlInstance $server

Jetzt kann die Prozedur sp_Blitz ausgeführt werden. Dazu gibt es in dbatools den Befehl [Invoke-DbaQuery](https://docs.dbatools.io/#Invoke-DbaQuery). Wir benötigen hier nur die beiden Parameter -SqlInstance und -Query, auf weitere Parameter werde in in separaten Artikeln näher eingehen. Die Ergebnisse möchte ich nicht einfach ausgeben lassen, sondern in einer Variablen speichern. Das empfehle ich in jedem Fall, denn zum einen sind die Ergebnisse teilweise sehr umfangreich und würden auf dem Bildschirm so nur schlecht dargestellt werden, zum anderen wollen wir die Datenbank nur ein einziges Mal abfragen und dann lokal mit den Ergebnissen weiterarbeiten.
 
	$spBlitz = Invoke-DbaQuery -SqlInstance $server -Query 'sp_Blitz'

Die Variable $spBlitz enthält ein Array von Datenzeilen (genauer: [System.Data.DataRow](https://docs.microsoft.com/de-de/dotnet/api/system.data.datarow)), dessen Inhalt wir uns sehr komfortabel mit [Out-GridView](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-gridview) ansehen können. Denn dazu wird ein separates Fenster geöffnet und wir können die Daten dort sortieren und filtern. Wer Out-GridView bisher noch nicht kennt, sollte sich den [Blogbeitrag von Frank Zöchling](https://www.frankysweb.de/powershell-out-gridview-fuer-die-darstellung-von-daten/) oder das [YouTube Video von TechSnips](https://www.youtube.com/watch?v=l7DDM4lPUQY&ab_channel=TechSnips) ansehen.

	$spBlitz | Out-GridView -Title sp_Blitz

Natürlich können wir die Daten auch in eine Datei speichern, um sie für später zu archivieren oder an andere zur weiteren Analyse weiterzuleiten. Als Formate bieten sich CSV oder JSON an, wobei ich JSON empfehle und hier verwenden werde. Denn bei JSON wird unter anderem die Information gespeichert, ob es sich um eine Zahl oder eine Zeichenkette handelt, was zum Beispiel für die Sortierung mit Out-GridView entscheidend ist. Allerdings gilt es dabei zu beachten, dass die Daten aktuell als DataRow vorliegen und neben den eigentlichen Daten noch Metadaten enthalten. Da diese nicht mit im JSON Dokument gespeichert werden sollen, werden diese vor der Umwandling in JSON entfernt. Dadurch können die Daten auch problemlos in einem Texteditor dargestellt werden.

	$spBlitz | Select-Object -Property * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json | Set-Content -Path C:\Temp\spBlitz.json

Für all diejenigen, die keine langen Zeilen mögen hier noch einmal etwas anders formatiert:

	$spBlitz | 
		Select-Object -Property * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | 
		ConvertTo-Json | 
		Set-Content -Path C:\Temp\spBlitz.json

Diese Datei kann jetzt zum Beispiel an einen mit der Analyse beauftragten Dienstleister weitergeleitet werden, der diese Datei wieder einlesen kann. Der Parameter -Raw ist hier wichtig, damit die ganze Datei zunächst komplett eingelesen wird und erst dann von JSON in die PowerShell Objektstruktur konvertiert wird.

	$spBlitzAusDatei = Get-Content -Path C:\Temp\spBlitz.json -Raw | ConvertFrom-Json
	$spBlitzAusDatei | Out-GridView -Title 'sp_Blitz (aus der Datei)'

Wenn Sie die Befehle jetzt bei sich ausgeführt haben und tatsächlich Fragen zu den Ergebnissen von sp_Blitz haben, dann sprechen Sie uns an.
