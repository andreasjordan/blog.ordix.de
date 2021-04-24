# How do I install the PowerShell module dbatools?

Author: Andreas Jordan



Questions are regularly asked in the "[#dbatools](https://sqlcommunity.slack.com/#dbatools)" channel of the "[SQL Server Community](https://sqlcommunity.slack.com/)" workspace on the [Slack](https://slack.com/intl/de-de/) platform about the correct installation of the [dbatools](https://dbatools.io/) PowerShell module. There are several answers to this question, many of which are described in the [documentation](https://dbatools.io/download/). I would like to describe here how I perform the automated installation on our virtual training systems.

If you haven't heard of the Slack platform yet, or are disappointed that you always ended up on a login page when using the links from the first sentence, please just use the address [aka.ms/sqlslack](http://aka.ms/sqlslack) to automatically receive an invitation to the "[SQL Server Community](https://sqlcommunity.slack.com/)" workspace. If you don't like short URLs, here is the long URL: https://sqlcommunity.slack.com/join/shared_invite/zt-o91sc6c5-~4~EAqtx8DPe3q6nYAyRrg#/. There everyone can ask questions about the use of dbatools, there are always longtime users and also authors of the module present to give assistance. In addition, there are also channels there for general questions about SQL or PowerShell.



### My framework

For many training courses, we use virtual Windows servers from a cloud provider, currently in version 2016. These are provided automatically by the provider, so they are installed with default operating system settings.

We have a proxy server in the environment through which participants can access the internet without authentication.

Configuration of all machines for a training course is done from a central server via administrative PowerShell version 5.1.



### My installation steps

Basically I recommend the installation via the [PowerShell Gallery](https://www.powershellgallery.com/packages/dbatools/) with the PowerShell command `Install-Module -Name dbatools`. This way the module can be easily updated later via `Update-Module -Name dbatools`. However, there may be some hurdles, which I will discuss below.

As of April 2020, connecting to the PowerShell Gallery is only possible with [TLS](https://de.wikipedia.org/wiki/Transport_Layer_Security) 1.2 or later; here is the announcement from Microsoft: [PowerShell Gallery TLS Support](https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/). Please also pay attention to the comments there, because spread over the article and the comments you will find the different possibilities to solve the problem transitionally or permanently.

I use this command on our systems:

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value 1
```

The first time `Install-Module` is used on a system, the following question is asked: "NuGet provider is required to continue. [...] Do you want PowerShellGet to install and import the NuGet provider now?". Therefore, to perform the installation without interaction, I use the following command:

```powershell
$null = Install-PackageProvider -Name Nuget -Proxy 'http://192.168.128.2:3128' -Force
```

The value for the parameter `-Proxy` must of course be adjusted, if no proxy is needed it can be omitted. The parameter `-Force` ensures here that there is no interaction. The specification `$null =` suppresses the output of the command, because I don`t need it.

Even now, when using `Install-Module`, a query would come up: "You are installing the modules from an untrusted repository. [...] Are you sure you want to install the modules from 'PSGallery'?". Therefore, another requirement is to trust the PowerShell Gallery as an installation source. Since the used command offers a parameter to pass the proxy, but this does not work on my systems so far, I first specify the proxy with a separate command:

```powershell
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebProxy]::new('http://192.168.128.2:3128')
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```

Afterwards, the installation should run without prompting:

```powershell
Install-Module -Name dbatools
```

For easy copy-paste here again in one block:

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value 1
$null = Install-PackageProvider -Name Nuget -Proxy 'http://192.168.128.2:3128' -Force
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebProxy]::new('http://192.168.128.2:3128')
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name dbatools
```

These are the commands that have worked reliably for us so far and are adapted to our environment. If your environment has different requirements, you will need to adjust the commands accordingly. If you have any further questions, please come to the channel "[#dbatools](https://sqlcommunity.slack.com/#dbatools)" on Slack, we will surely find a solution for your problem there.

After the successful installation, I then recommend my article [dbatools: How do I get started?](2021_04_25_dbatools_-_How_do_I_get_started.md) with first examples on how to use dbatools.
