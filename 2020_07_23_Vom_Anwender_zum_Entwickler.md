# Vom Anwender zum Entwickler - mit dem PowerShell-Modul dbatools zur Verwaltung von Microsoft SQL Servern

Autor: Andreas Jordan (anj@ordix.de)

Veröffentlich unter: https://blog.ordix.de/vom-anwender-zum-entwickler


### Erster Einsatz in unseren Schulungen

Die Geschichte nahm ihren Anfang, als ich meinen Teilnehmern im [Administrationskurs für Microsoft SQL Server](https://seminare.ordix.de/seminare/microsoft-sql-server/verwalten-einer-sql-datenbankinfrastruktur-moc-21764.html) zeigen wollte, auf welche Arten sie Verwaltungstätigkeiten durchführen können: Mit der grafischen Oberfläche des SQL Server Management Studios, mit SQL-Skripten oder eben mit PowerShell, speziell mit dem Modul [dbatools](https://dbatools.io/).

Dieses Modul enthält sehr viele nützliche Funktionen (bei PowerShell heißen sie [Commandlets](https://docs.microsoft.com/de-de/powershell/scripting/developer/cmdlet/cmdlet-overview)) und wird von mehreren Personen gemeinsam weiterentwickelt und als freie und quellenoffene Software zur Verfügung gestellt. Gerade in Kapiteln wie Backup und Restore sorgen die schlanken, übersichtlichen Commandlets für aufgeräumte Demoskripte.

Da PowerShell sowohl eine Skriptsprache als auch eine vollwertige Programmiersprache auf Basis von .NET ist, sind kleine Abläufe schnell programmiert, Variablen erhöhen die Übersichtlichkeit und Flexibilität.


### Vorbereitung zum Einsatz beim Kunden

In der letzten Zeit rückt das Thema Hochverfügbarkeit mit [Always On Verfügbarkeitsgruppen](https://docs.microsoft.com/de-de/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server) bei einigen unserer Kunden in den Fokus und so wollte ich natürlich testen, wie denn die Einrichtung mit PowerShell funktioniert. Denn mit dem klassischen Wizard des SQL Server Management Studios bin ich nicht zufrieden. Bei Fehlern gibt es keine aussagekräftigen Meldungen und eine Dokumentation der verwendeten Einstellungen ist auch nicht gut möglich - wer möchte in der heutigen Zeit denn noch eine Sammlung von Screenshots haben? Natürlich gibt es wie immer die Möglichkeit, sich am Ende des Wizards das SQL-Skript generieren zu lassen, aber auch damit bin ich nur bedingt zufrieden.

Bei der Arbeit mit den entsprechenden [Commandlets](https://dbatools.io/commands/#AGs) bin ich dann aber auf Probleme gestoßen, manches funktionierte nicht wie erwartet. Die Fehlermeldungen haben zunächst auch nicht weitergeholfen, da konnte schließlich nur noch ein Blick in den Code weiterhelfen. Das ist ja die Stärke von quellenoffener Software: Jeder kann einen Blick auf den Code werfen und ihn auch bei sich lokal an seine Bedürfnisse anpassen.


### Bugfixing: Jeder Anfang ist schwer

Die ersten Fehler zu finden, war gar nicht so einfach. Ich musste zunächst in die Welt des Moduls eintauchen und herausfinden, wie die einzelnen Hilfsfunktionen funktionieren und welchem grundsätzlichen Schema die Commandlets folgen. Und ich wollte nicht nur melden, dass ein bestimmtes Commandlet nicht funktioniert, sondern auch die Ursache benennen. Im besten Fall gleich einen Vorschlag zur Beseitung des Fehlers oder zu weiteren Verbesserungen unterbreiten.


### Ein Account bei Github muss her

Also habe ich mich in die Welt von Github begeben, einen Account angelegt und gleich mal einen Fork des [offiziellen Repositories](https://github.com/sqlcollaborative/dbatools) angelegt um dort meine Vorschläge im Code zeigen zu können. Darüber hinaus habe ich meinen einige Zeit nicht genutzten Account bei Slack reaktiviert um in den dortigen [Kanälen zu dbatools](https://dbatools.io/slack) mit diskutieren zu können.

Damit stand dann meinen ersten Issues und Pull Requests nichts mehr im Wege. Und mit jedem neuen Pull Request geht die Arbeit mit Git flüssiger von der Hand, mit jedem Feedback lerne ich mehr über die Arbeit der anderen Entwickler und über das Modul.


### Meine erste veröffentlichte Änderung

Mit der vor einigen Tagen erschienenen Version 1.0.114 von dbatools sind jetzt tatsächlich einige meiner vorgeschlagenen Änderungen im offiziellen Release enthalten und können von jedem genutzt werden.

Damit kann ich auch die aktuell geplante Artikelserie zur Einrichtung von Always On Verfügbarkeitsgruppen mit PowerShell und dbatools weiter verfolgen.


### Diskussionen rund um den Globus

Natürlich kommt es auch vor, dass meine Vorschläge keinen Anklang finden. Oder ich etwas übersehen habe, weil ich noch nicht so lange dabei bin. Oder es einfach unterschiedliche Vorstellungen davon gibt, was genau das Commandlet denn leisten soll und was nicht. Darüber wird dann sowohl in den Kommentaren auf Github, als auch in den Kanälen auf Slack diskutiert. Da einige Entwickler in den USA sitzen geschieht das dann natürlich vielfach zeitversetzt, da vergeht dann immer mal ein halber Tag bis zur nächsten Reaktion. Auch arbeitet ja niemand Vollzeit an diesem Projekt und jeder nimmt sich nur ab und zu mal ein paar Minuten oder Stunden Zeit für die Weiterentwicklung. Das verlangsamt natürlich den Prozess, bietet aber auf der anderen Seite auch die Gelegenheit in Ruhe über die Vorschläge nachzudenken.


### Und was bringt es der ORDIX AG und ihren Kunden?

Durch die Einarbeitung in die Struktur des Moduls fällt es mir jetzt viel leichter, bei unerwartetem Verhalten die Ursachen zu analysieren. Nicht immer ist es ja ein Fehler im Modul, vielleicht hatte ich einfach andere Erwartungen an die Funktionsweise. Ich kann auch leichter Anpassungen einarbeiten, zunächst einmal nur für meine persönlichen Einsatzzwecke - aber natürlich auch für unsere Kunden. Und diese können sich bei Fragen im Umgang mit dbatools gerne an uns wenden. Wir können gemeinsam die richtigen Commandlets auswählen und in ein kundenspezifisches Skript integrieren. Bei auftretenden Fehlern können wir diese direkt auf dem Kundensystem analysieren, notwendige Anpassungen vornehmen und auch die Integration in das offizielle Release vorantreiben.
