# Using the SQL Server First Responder Kit with the PowerShell module dbatools

The SQL Server First Responder Kit by Brent Ozar should be familiar to most database administrators, all others please have a look [at Brent Ozar's website](https://www.brentozar.com/first-aid/) or [directly at the corresponding GitHub repository](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit).

The PowerShell module dbatools may not be known to everyone yet, especially if you haven't had any contact with PowerShell before or fully rely on SQL Server Management Studio. The [website](https://dbatools.io/) has recently moved to GitHub Pages, so there may still be issues in one place or another, but the [documentation](https://docs.dbatools.io/) should work in any case. If you have any questions about dbatools, please feel free to contact us, we are using the module successfully with some customers in the meantime.

Today I would like to show how the procedure sp_Blitz from the SQL Server First Responder Kit can be executed with dbatools and what advantages processing the results with PowerShell can have.

Let's start with the import of the module. Even though in the current PowerShell versions all required modules are loaded automatically the first time the corresponding commands are used, I still recommend explicitly loading all required modules right at the beginning of the script. This way it is clear at an early stage whether all modules could be loaded successfully and it is immediately visible later which modules are needed for the use of the script.

Then we connect to the SQL Server instance to be analyzed and can easily use the resulting connection for all subsequent calls. I use Windows authentication here and therefore only specify server and instance name, but of course logging in with a SQL Server login is also possible, for details please see the [documentation](https://docs.dbatools.io/#Connect-DbaInstance). 

    Import-Module -Name dbatools
	$server = Connect-DbaInstance -SqlInstance SRV1\SQL2016

If you have not yet installed the SQL Server First Responder Kit or want to update it, you can also do this with the PowerShell module dbatools. For further options of the command I refer again to the [documentation](https://docs.dbatools.io/#Install-DbaFirstResponderKit).

	Install-DbaFirstResponderKit -SqlInstance $server

Now the procedure sp_Blitz can be executed. For this purpose there is the command [Invoke-DbaQuery](https://docs.dbatools.io/#Invoke-DbaQuery) in dbatools. We only need the two parameters -SqlInstance and -Query, further parameters will be discussed in separate articles. I don't want to simply output the results, but store them in a variable. I recommend this in any case, because on the one hand the results are sometimes very extensive and would be displayed poorly on the screen, on the other hand we want to query the database only once and then continue working locally with the results.

	$spBlitz = Invoke-DbaQuery -SqlInstance $server -Query 'sp_Blitz'

The $spBlitz variable contains an array of data rows (more precisely: [System.Data.DataRow](https://docs.microsoft.com/en-us/dotnet/api/system.data.datarow)), the content of which we can view very comfortably with [Out-GridView](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-gridview). Because for this purpose a separate window is opened and we can sort and filter the data there. If you don't know Out-GridView yet, you should have a look at the [blog post by Frank Zöchling](https://www.frankysweb.de/powershell-out-gridview-fuer-die-darstellung-von-daten/) or the [YouTube video by TechSnips](https://www.youtube.com/watch?v=l7DDM4lPUQY&ab_channel=TechSnips).

	$spBlitz | Out-GridView -Title sp_Blitz

Of course, we can also save the data to a file to archive it for later or forward it to others for further analysis. As formats CSV or JSON offer themselves, whereby I recommend JSON and will use it here. Because with JSON, among other things, the information is stored whether it is a number or a string, which is crucial for sorting with Out-GridView, for example. However, it is important to note that the data is currently available as DataRow and contains metadata in addition to the actual data. Since these are not to be stored in the JSON document, they are removed before conversion to JSON. This allows the data to be displayed in a text editor without any problems.

	$spBlitz | Select-Object -Property * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json | Set-Content -Path C:\Temp\spBlitz.json

For all those who don't like long lines here again in a slightly different format:

	$spBlitz | 
		Select-Object -Property * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | 
		ConvertTo-Json | 
		Set-Content -Path C:\Temp\spBlitz.json

This file can now be forwarded, for example, to a service provider commissioned with the analysis, who can read it in again. The -Raw parameter is important here so that the entire file is first read in completely and only then converted from JSON to the PowerShell object structure.

	$spBlitzFromFile = Get-Content -Path C:\Temp\spBlitz.json -Raw | ConvertFrom-Json
	$spBlitzFromFile | Out-GridView -Title 'sp_Blitz (from a file)'

If you have now run the commands on your end and actually have questions about the results of sp_Blitz, please contact us.

Andreas Jordan, info@ordix.de
