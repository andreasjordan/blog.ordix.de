# Wie installiere ich das PowerShell-Modul dbatools?

Autor: Andreas Jordan (anj@ordix.de)

Veröffentlicht unter: https://blog.ordix.de/installiere-powershell-modul-dbatools


Regelmäßig werden im Kanal "[#dbatools](https://sqlcommunity.slack.com/#dbatools)" des Workspace "[SQL Server Community](https://sqlcommunity.slack.com/)" auf der Plattform [Slack](https://slack.com/intl/de-de/) Fragen nach der richtigen Installation des PowerShell-Moduls [dbatools](https://dbatools.io/) gestellt. Auf diese Frage gibt es verschiedene Antworten, viele davon sind in der [Dokumentation](https://dbatools.io/download/) beschrieben. Ich möchte hier beschreiben, wie ich die automatisierte Installation auf unseren virtuellen Schulungssystemen durchführe.

Wer bisher noch nichts von der Plattform Slack gehört hat oder enttäuscht ist, dass er bei der Verwendung der Links aus dem ersten Satz immer auf einer Anmeldeseite gelandet ist, der verwende bitte einfach die Adresse [aka.ms/sqlslack](http://aka.ms/sqlslack), um automatisch eine Einladung zum Workspace "[SQL Server Community](https://sqlcommunity.slack.com/)" zu erhalten. Wer keine Kurz-URLs mag, hier noch die lange URL: https://sqlcommunity.slack.com/join/shared_invite/zt-o91sc6c5-~4~EAqtx8DPe3q6nYAyRrg#/. Dort kann jeder Fragen zur Verwendung von dbatools stellen, es sind immer langjährige Nutzer und auch Autoren des Moduls anwesend, um Hilfestellung zu geben. Zudem gibt es dort auch Kanäle für allgemeine Fragen zu SQL oder PowerShell.



### Meine Rahmenbedingungen

Wir verwenden für viele Schulungen virtuelle Windows-Server bei einem Cloud-Anbieter, aktuell in der Version 2016. Diese werden automatisiert durch den Anbieter zur Verfügung gestellt, sind also mit Standardeinstellungen des Betriebssystems installiert.

Wir haben in der Umgebung einen Proxyserver, über den die Teilnehmer ohne Authentifizierung auf das Internet zugreifen können.

Die Konfiguration aller Maschinen für eine Schulung erfolgt von einem zentralen Server aus per administrativer PowerShell in der Version 5.1.



### Meine Installationsschritte

Ganz grundsätzlich empfehle ich die Installation über die [PowerShell Gallery](https://www.powershellgallery.com/packages/dbatools/) mit dem PowerShell-Befehl `Install-Module -Name dbatools`. So kann das Modul später einfach über `Update-Module -Name dbatools` aktualisiert werden. Allerdings gibt es unter Umständen einige Hürden, auf die ich im Folgenden eingehen werde.

Seit April 2020 ist eine Verbindung zur PowerShell Gallery nur noch mit [TLS](https://de.wikipedia.org/wiki/Transport_Layer_Security) 1.2 oder aktueller möglich; hier die Ankündigung von Microsoft: [PowerShell Gallery TLS Support](https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/). Bitte dort auch die Kommentare beachten, denn über den Artikel und die Kommentare verteilt finden sich dort die verschiedenen Möglichkeiten, das Problem übergangsweise oder dauerhaft zu lösen.

Ich verwende auf unseren Systemen diesen Befehl:

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value 1
```

Bei der ersten Verwendung von `Install-Module` auf einem System wird folgende Frage gestellt: "NuGet provider is required to continue. [...] Do you want PowerShellGet to install and import the NuGet provider now?". Um die Installation ohne Interaktion durchzuführen, verwende ich daher den folgenden Befehl:

```powershell
$null = Install-PackageProvider -Name Nuget -Proxy 'http://192.168.128.2:3128' -Force
```

Der Wert für den Parameter `-Proxy` muss natürlich angepasst werden, falls kein Proxy benötigt wird kann er entfallen. Der Parameter `-Force` sorgt hier dafür, dass es keine Rückfrage gibt. Die Angabe `$null =` unterdrückt die Ausgabe des Befehls, da ich diese nicht benötige.

Auch jetzt noch käme bei der Verwendung von `Install-Module` eine Rückfrage: "You are installing the modules from an untrusted repository. [...] Are you sure you want to install the modules from 'PSGallery'?". Eine weitere Voraussetzung ist es daher, der PowerShell Gallery als Installationsquelle zu vertrauen. Da der verwendete Befehl zwar einen Parameter zur Übergabe des Proxys anbietet, dieser aber auf meinen Systemen bisher nicht funktioniert, lege ich den Proxy zunächst mit einem eigenen Befehl fest:

```powershell
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebProxy]::new('http://192.168.128.2:3128')
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```

Anschließend sollte die Installation ohne Rückfrage ablaufen:

```powershell
Install-Module -Name dbatools
```

Für einfaches Copy-Paste hier noch mal in einem Block:

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value 1
$null = Install-PackageProvider -Name Nuget -Proxy 'http://192.168.128.2:3128' -Force
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebProxy]::new('http://192.168.128.2:3128')
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name dbatools
```

Das sind die Befehle, die bei uns bisher zuverlässig funktionieren und an unsere Umgebung angepasst sind. Wenn Ihre Umgebung andere Voraussetzungen hat, müssen Sie die Befehle entsprechend anpassen. Bei weiteren Fragen kommen Sie doch in den Kanal "[#dbatools](https://sqlcommunity.slack.com/#dbatools)" auf Slack, dort finden wir bestimmt auch für Ihr Problem eine Lösung.

Nach der erfolgreichen Installation empfehle ich Ihnen dann meinen Artikel [dbatools: Wie fange ich nur an?](2021_04_25_dbatools_-_Wie_fange_ich_nur_an.md) mit ersten Beispielen zur Verwendung von dbatools.









