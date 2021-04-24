# dbatools: How do I get started?

Author: Andreas Jordan



Whenever I give a training on Microsoft SQL Server administration, I tell about the benefits of the PowerShell module dbatools. I can use it to perform many administrative tasks without having to connect to the server via RDP and without having to start SQL Server Management Studio. Especially the administration of a large number of instances is thus possible from a central location and with a uniform context. In addition, I can start with single, simple and readable commands for queries or smaller administrative tasks. Later, I can build on this to write complex programs, since PowerShell is not just a scripting language but a complete object-oriented programming language. 

Then, when I have shown enough examples, at some point the question comes: And how do I learn to use dbatools?

Of course, I will be happy to answer this question verbally and individually for my participants in the future. However, I would also like to be able to provide them with a link, the link to this very article. Therefore, I am putting together a few commands below that all have one thing in common: We will only be retrieving information from the SQL Server instances, we will not be changing any configuration or data.



### From where?

First, a few words about the place where we want to start PowerShell and the PowerShell version. Since we want to work with multiple SQL Server instances on (mostly) multiple servers, I see two equally valid options: On the administrator's workstation PC (so probably Windows 10) or on a central management server (so probably Windows Server 2016). In both cases, we're dealing with PowerShell 5.1, because very few companies will currently already be using PowerShell 7. This is also good, all commands of dbatools are tested with PowerShell 5.1, with PowerShell 7 some commands unfortunately do not work yet.



### With which program?

If PowerShell 5.1 is installed on your computer, you have two entries in the start menu: "PowerShell" and "PowerShell ISE". The first one is a classic shell like "cmd.exe" and from my point of view it is suitable for experienced users who want to issue a few commands quickly. For beginners I would always recommend the "PowerShell ISE" because you have an integrated editor here. You have a clear overview of the commands, you can execute them individually or in blocks, and you get extensive help in the form of drop-down lists when entering commands and parameters. At the end you can save your work and build up an individual script collection. However, I must give you one warning along the way: Some commands govern a bit differently in "ISE" than in classic PowerShell. And what is very annoying: If you close the "ISE", it unfortunately remains active in the background and the connections to the SQL server instances are not closed cleanly.

Therefore, at some point you should switch to the program that I personally currently use and recommend for working with PowerShell: [Visual Studio Code](https://code.visualstudio.com/) (VSCode). But I don't recommend switching from the beginning, because setting up VSCode to your personal needs takes time again &ndash; and now you are supposed to learn dbatools first, one step at a time. 



### How to install dbatools?

For installation, you can find the most important information on the [official site](https://dbatools.io/download/) as well as in my article [How do I install the PowerShell module dbatools?](2021_04_24_How_do_I_install_the_PowerShell_module_dbatools.md). 

For further questions, I recommend the channel "[#dbatools](https://sqlcommunity.slack.com/#dbatools)" of the workspace "[SQL Server Community](https://sqlcommunity.slack.com/)" on the platform [Slack](https://slack.com/intl/de-de/). If you haven't heard of the Slack platform yet or are disappointed that you always ended up on a login page when using the links from the first sentence, please just use the address [aka.ms/sqlslack](http://aka.ms/sqlslack) to automatically receive an invitation to the workspace "[SQL Server Community](https://sqlcommunity.slack.com/)". If you don't like short URLs, here is the long URL: https://sqlcommunity.slack.com/join/shared_invite/zt-o91sc6c5-~4~EAqtx8DPe3q6nYAyRrg#/. There everyone can ask questions about the use of dbatools, there are always longtime users and also authors of the module present to give help. In addition, there are also channels there for general questions about SQL or PowerShell.



### With which account?

Before the first command, however, the question still needs to be clarified: Which account do we want to use to connect to the SQL Server instances? Basically, I see three possibilities. The easiest way is if the Windows account used to start PowerShell has administrative rights directly on the SQL Server instances. Then no preparations are necessary, we could start right away. But I know some companies where the administrators have two accounts: A normal account for daily work and an administrative account for access to the server systems. That would be option two: a separate Windows account that is not used to launch PowerShell, but has administrative rights on the SQL Server instances. Option three is a SQL Server login with administrative rights. For security reasons, I always recommend option two or three, so I would like to use those options here as well. As we will see in a moment, the two possibilities do not differ at all if we use dbatools. So you can still switch between these possibilities later without having to adjust the code.



### The first lines of code

But now a few lines of code, the explanation will follow:

```powershell
$ErrorActionPreference = 'Stop'
Import-Module -Name dbatools
[DbaInstance[]]$myInstances = 'SRV1', 'SRV1\SQL2016', 'SRV2.mydomain.com\SQL2019,14330'
$myAdminCredential = Get-Credential -Message 'SQL Server Administrator' -UserName 'MyAdminUsername'
```

The first line belongs to every PowerShell script for me. If I later execute the complete script or even more than one command, a failed command will cause the script or the just executed commands to abort. Although most commands from the dbatools module only generate warnings and do not abort, this can be customized per command via the optional `-EnableException` parameter. This way the script is already built from the beginning in a way that it can later be extended to a complex program.

The second line imports the dbatools module. You can also say that the module is loaded. This may well take a few seconds, among other things the official DLLs from Microsoft are loaded to connect to the SQL Server instances. I am generally a friend of importing the required modules right at the beginning of a script. This is usually not necessary, because the module is imported automatically the first time a command from this module is used, but I always see this also as a documentation of the dependencies. This way it is quickly clear to the reader which modules are needed to execute the script. In our specific case, however, it is mandatory to import the module first. Because we want to use a data type &ndash; i.e. a class &ndash; of the module before using the first command.

In the third line, you must now specify the instances with which you want to perform the first test. Maybe don't take them all at once, but two or three should be enough. I have also chosen different possibilities here, so that you can see what is possible. Basically, you specify the instances exactly as you would in SQL Server Management Studio. If you are not that experienced with PowerShell or programming: `[DbaInstance[]]` declares the variable `$myInstances` as an array of elements of the datatype `DbaInstance`, one of the central datatypes of the module dbatools. For more information, see my article [dbatools in detail - What happens when Invoke-DbaQuery is used?](2021_03_29_dbatools_in_detail_-_What_happens_when_Invoke-DbaQuery_is_used.md).

The fourth line opens a dialog that asks you for the password to access the SQL Server instances. Here, instead of "MyAdminUsername", you should of course enter the user name to be used at your site. This can be either a domain account or the name of an SQL Server login. Domain accounts must be specified in the form "DOMAIN\username". As I have already announced: The choice of login only affects the form of the `UserName` parameter, there are no more differences.



### But now a connection please

That was the preliminary work, there were still adjustments to be made. From here on you can take over all lines just like that &ndash; but of course you can also adapt them later according to your wishes.

```powershell
$servers = Connect-DbaInstance -SqlInstance $myInstances -SqlCredential $myAdminCredential
```

This now establishes a connection to each instance stored in the `$myInstances` variable, using the credentials contained in `$myAdminCredential`. This is an exciting point, here it is decided whether you have configured everything correctly. If error messages occur here, you must first analyze them and eliminate the reasons for them. As already mentioned above: If you have problems, please contact us &ndash; maybe it is just a small thing.

Since I always support the further development of dbatools and am thus often "on the road in the source code", I have partly adopted the naming conventions used there. So internally in the code an opened connection to a SQL Server instance is always stored in a variable with the name `$server`. Here I added the plural-s, because there are several connections. This way it is also easier later to run all connections one after the other with `foreach ($server in $servers) { ... }`. However, you can and should find your own naming scheme for the different variables, or adopt the scheme common in your company for working with dbatools as well.

The variable `$servers` can be used from now on wherever a parameter `-SqlInstance` queries the instance to be used. The additional specification of the `-SqlCredential` parameter can be omitted, since the connection has already been established. For background information, please refer to my article [dbatools in detail - What happens when Invoke-DbaQuery is used?](2021_03_29_dbatools_in_detail_-_What_happens_when_Invoke-DbaQuery_is_used.md).



### Display central information about the instances

It's time to display some information &ndash; that's what we're doing this for, after all. I would like to start with some information about the instances. Everyone is interested in different information, so let me start by showing you how to view the list of possible information.

One more note in advance. You will have to execute the five lines of code mentioned so far every time you want to work with the instances. From now on, all lines of code are always optional, you will only have to execute those that are necessary for your particular task.

```powershell
$servers | Get-Member
```

The command `Get-Member` lists among others all properties of the passed objects. So feel free to exchange the properties used below for others and learn more about your SQL Server instances.

```powershell
$servers | Select-Object -Property ComputerName, Name, Product, ProductLevel, ProductUpdateLevel, VersionString, Edition, LoginMode, Collation | Out-GridView
```

The command `Select-Object` takes over objects on the pipeline and passes them to the next command via the next pipeline. The `-Property` parameter ensures that these objects now only have the specified properties. So if we as database experts imagine a SELECT statement, this is the SELECT clause. So the command is not only called like that, it also works like that.

The command `Out-GridView` launches another window that may remind you remotely of the output in SQL Server Management Studio. But we have much more possibilities here. At the top you have the option of filtering, which works like a full-text search &ndash; just give it a try. Also, by clicking on a column header, you can easily sort by that column in ascending or descending order. Try this in the SQL Server Management Studio...

With this view you can very quickly see if one of the instances is "out of line", i.e. configured differently than the others. I'm not talking about automated testing here, that's not the focus of this article, we need some more PowerShell code for that. I'm concerned here with a quick visual grasp, with contrasting the different instances, with getting to know the instances. Maybe the instances have only recently come under your purview, so this is a good way to get an overview.



### Next: Databases and logins

In the dbatools there is a suitable command for every aspect in the SQL Server, I cannot and do not want to present all of them here. Have a look at the [documentation](https://docs.dbatools.io/) and search there for "Get-", that will give you a good overview.

For now, I will introduce you to just two areas, using some new PowerShell code every now and then. Let's start with the databases.

```powershell
$databases = Get-DbaDatabase -SqlInstance $servers -ExcludeSystem
$databases | Select-Object -Property SqlInstance, Name, Owner, Collation, CompatibilityLevel, RecoveryModel, PageVerify | Out-GridView
```

Even though the databases can be determined via `$servers.Databases`, here I use the dbatools command `Get-DbaDatabase`, because it has many useful parameters to limit the selection of databases. As an example I use here the possibility to hide the system databases. I repeat myself again: look at the properties of the database objects with `Get-Member` and expand the properties to be output to get to know your databases better.

```powershell
$logins = Get-DbaLogin -SqlInstance $servers -ExcludeLogin 'NT AUTHORITY\SYSTEM' -ExcludeFilter 'NT SERVICE\*', '##*##'
$logins | Select-Object -Property SqlInstance, Name, LoginType, @{ name = 'Roles' ; expression = { Get-DbaServerRoleMember -SqlInstance $_.Parent -Login $_.Name | Select-Object -ExpandProperty Role } } | Out-GridView
```

Yes, this is only two lines of code, but this time two quite long lines. In the first line, I again use the appropriate `Get-Dba` command to get the logins. Again I use parameters to limit the return. Because in most cases the predefined logins don't interest me and only block the view to the relevant logins. With `-ExcludeLogin` single logins can be excluded, but this parameter also takes a comma separated list. When using `-ExcludeFilter` the typical wildcards `*` and `?` can be used, because internally the check is done with `-NotLike`. So here I have the possibility to filter all service accounts, regardless of their names. Also, I filter out the [internal certificate-based logins](https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/principals-database-engine#certificate-based-sql-server-logins) whose names are enclosed by double number characters (##). Another hint for those whose system is not installed in English: The strings `NT AUTHORITY\SYSTEM` and `NT SERVICE` must then be adapted according to the language used.

Let's move on to the second line, where I again output some properties of the logins via `Out-GridView`. However, I also want to specify the server roles that the logins are members of. The membership in a role is not a property of the logins, even if it looks like that in the graphical interface of the SQL Server Management Studio. The respective members are stored in the role, so I have to determine the members of all roles and search there for the login that is currently being processed. Exactly for this task there is again a dbatools command: `Get-DbaServerRoleMember`. The specification of the `-SqlInstance` is always necessary, the correct instance must be queried. But then I have the choice via the optional parameters `-ServerRole` and `-Login` if the return should be restricted to certain roles or logins. So, by specifying the login here, I can have all roles returned in which the login is a member. Since I am not interested in the complete object containing all aspects of membership, I use `Select-Object` with the `-ExpandProperty` parameter to get only the names of the roles. Now that we know how to get the list of roles for a single login, we need to do that for all logins in `$logins`. This is exactly where the [calculated properties](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_calculated_properties) come into play, which are also described in [Example 10 of Select-Object](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/select-object#example-10--create-calculated-properties-for-each-inputobject). Hereby I create a new property whose name I specify via `name` (or alternatively also `label` as well as the short forms `n` or `l`) and whose calculation formula I specify via `expression` (or the short form `e`). I can access the individual object currently being processed via the variable `$_` and thus determine the name of the login currently being processed via `$_.Name`. When we looked at the properties of the SQL Server instance, we saw that subordinate objects such as databases or logins can also be reached via the instance object. Thus, the various aspects are arranged in an object tree, which roughly corresponds to the view in SQL Server Management Studio. In addition to accessing subordinate objects, there is always access to the parent object via the `.Parent` property. So here I can access via `$_.Parent` the SQL Server instance in which the currently processed login is located.



### Finally, a more complex task: identify failed jobs

Especially in case you do not collect information about failed SQL Server Agent jobs at a central location, this example should be interesting for you.

For each job whose last execution failed, I would like to determine the error message of the job as well as the last executed step. In addition, I would like to have the time of the last failed execution as well as the time of the last successful execution, i.e. I would like to know how long the job has not been working anymore.

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
$failedJobInfos | Out-GridView -Title 'Information about failed jobs'
```

I structured the code more like a program and less like a script. What do I mean by that? I use more variables, moreover with `foreach` a classical loop. I could add additional logging or error handling in a next step. Also I can go step by step here during programming or further development and always look at and analyze the intermediate results. So the commented out statement `$job = $failedJobs | Select-Object -First 1` (if there is more than one job in `$failedJobs` in any case, `$job = $failedJobs[0]` would also work) is a statement that I always write and comment out right away in every `foreach` loop. I can highlight this code and run it to simulate the first loop pass. Now all the lines within the loop also work individually and I can test the individual steps. Especially when processing large amounts of data, I think it is important to test the individual steps with a few (or single) data sets.

In the first line, I use `Where-Object` to filter the objects returned by `Get-DbaAgentJob` and store only those in `$failedJobs` where the `LastRunOutcome` property corresponds to the value "Failed". Since we all come from a database administration background: Yes, this works like the WHERE clause, I could add more conditions here with `-and` and `-or`. Then always think of the possibly necessary parentheses, just like with classic SQL. That's why I like to use the syntax with the parameter `-FilterScript`, where I can access the currently processed object with `$_` as in the previous examples. For the alternative syntax I refer to the [documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/where-object).

In the second line I use the loop `foreach` which you may know from other programming languages, but in PowerShell it can also be used in an assignment (here: `$failedJobs =`). In this case, all outputs that are performed within the loop are assigned to this variable. We will use this at the end of the loop to create PowerShell objects and thus store them in the variable.

First, however, we assign three variables in the loop. The first two contain objects from the return of `Get-DbaAgentJobHistory`. Note that in the hierarchy of objects between "[Job](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.agent.job)" and "[Server](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.server)" there is still the level "[JobServer](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.agent.jobserver)" (I have linked the documentation of the respective classes), so we have to take "two steps up" to get to the instance. If we only need information about the job, we can exclude the individual steps with `-ExcludeJobSteps`, for the information about the individual steps we need an additional filter step. The job itself has the `StepID` 0 and can be filtered out this way. We then sort in descending order using the `RunDate` property (in SQL this would be an `ORDER BY RunDate DESC`) and select only the first record found this way (in SQL this would be a `SELECT TOP 1`). This is then the last executed step of the currently processed job and should therefore contain information about the cause of the failure. For the third variable (`$lastGoodRunDate`), we filter directly on the successful executions with `-OutcomeType Succeeded` when calling `Get-DbaAgentJobHistory`, sort again by `RunDate` and select the first record. However, here we also use `-ExpandProperty RunDate` to get not the whole object but only the date.

With this, all the required information has been determined, we now only have to "put it into shape". In my opinion, objects are best suited for this, since we are already used to processing them, because all PowerShell commands return objects. And with `[PSCustomObject]` PowerShell offers a generic class, where we can shape the properties according to our wishes. The syntax is simply `[PSCustomObject]@{ property1 = value1 ; property2 = value2 }`. I also use line breaks above in the example to increase readability, in this case `;` can be omitted. For more information I can recommend this article by [Kevin Marquette](https://twitter.com/KevinMarquette), which has been integrated into the documentation at Microsoft: [What you always wanted to know about PSCustomObject](https://docs.microsoft.com/de-de/powershell/scripting/learn/deep-dives/everything-about-pscustomobject).

With this, the desired information for each job is compiled in an object and stored together in the variable `$failedJobInfos`. We can then display their contents as usual with `Out-GridView`.

Finally, I'd like to show you two other ways to style the code. In the first case, we will not allocate a single variable and execute everything in a single statement. Instead of the `foreach` loop, I will use the `ForEach-Object` command, which I can integrate into a pipelined processing:

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
} | Out-GridView -Title 'Information about failed jobs'
```

In the second case, I use the calculated properties of `Select-Object` already known from the example with the logins:

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
    Out-GridView -Title 'Information about failed jobs'
```

Hopefully, this has given you a first insight into working with dbatools. Now it's your turn. Install dbatools and get to know your SQL Server instances again. Let it show you more properties, use more commands. Don't be afraid: all commands starting with `Get-Dba` are just reading information, nothing is changed.
