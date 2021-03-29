# dbatools in detail - What happens when Invoke-DbaQuery is used?

Author: Andreas Jordan (anj@ordix.de)

Published at: https://blog.ordix.de/dbatools-a-simple-database-query-with-invoke-dbaquery



In this article I would like to take you behind the scenes of the PowerShell module dbatools, which I love to use for working with Microsoft SQL Server.

The starting point will be a simple query on a table consisting of only a single line of code:

```powershell
Invoke-DbaQuery -SqlInstance 'SRV1\SQL2016' -Query 'SELECT * FROM test01.dbo.testdata'
```

I pass the command `Invoke-DbaQuery` here only the name of the instance as well as the actual query. I thus assume that with the Windows account used for the PowerShell session I also have the necessary rights within the SQL Server instance.



### The world of data types

Before we dive into the code behind `Invoke-DbaQuery`, a digression into the world of data types follows first. First and foremost, this is about how PowerShell works with the different data types.

In the following I assign different values to the variable `$number` and then check the used data type with the method `GetType`.

```powershell
$number = 12
$number.GetType().Name  # Int32
# The appropriate data type was selected automatically.

$number = 12345678901
$number.GetType().Name  # Int64
# The appropriate data type was selected automatically.

$number = [Int64]12
$number.GetType().Name  # Int64
# The specification "12" was converted to the Int64 data type and then stored, so $number now also has this data type.

$number = 12
$number.GetType().Name  # Int32
# The variable $number has taken over the actual data type of "12" again.

[Int64]$number = 12
$number.GetType().Name  # Int64
# Here the data type of $number was also set for the future and the specification "12" was converted into this data type.

$number = 12
$number.GetType().Name  # Int64
# The variable $number keeps the data type, all entries are converted to this data type.

$number = 'Hallo'  # Cannot convert value "Hallo" to type "System.Int64". Error: "Input string was not in a correct format."
# Impossible conversions will result in an error.

$number = -0.65
$number.GetType().Name  # Int64
# The variable $number keeps the data type, all entries are converted to this data type.
$number  # -1
# Conversions can thus lead to rounding.

# So:
$number = [Int64]12  # (Temporary) conversion of a value into a data type.
[Int64]$number = 12  # Declaration of a variable with a fixed data type.

```



### The world of object orientation: data types are classes

Those who come from object-oriented programming already suspect it: data types are classes. Variables are thus objects that are derived (instantiated) from these classes. The data types have thus also attributes and methods. To illustrate this better, let's switch from numbers to time specifications:

```powershell
$now = Get-Date
$now.GetType().Name  # DateTime
$now  # Saturday, March 13, 2021 1:33:12 PM

# But the DateTime data type can do more:
$now.Hour  # 13
# Hour is an attribute
$now.AddDays(2)  # Monday, March 15, 2021 1:33:12 PM
# AddDays is a method

# What attributes and methods do the objects of this class have?
$now | Get-Member  
# The attributes are called "property" here. The output is very long and therefore not given here in the article.
```

If we don't want to create such an object with a time via a command like `Get-Date`, we still have to talk about constructors. These are methods of the class that create an object and at the same time configure it according to our wishes. The list of constructors for the DateTime data type can be found in the [documentation](https://docs.microsoft.com/en-us/dotnet/api/system.datetime.-ctor) at Microsoft. There are many constructors with different parameters, here is an example:

```powershell
$oneday = [DateTime]::new(2020, 12, 24)
$oneday.GetType().Name  # DateTime
$oneday  # Thursday, December 24, 2020 12:00:00 AM

$oneday = [DateTime]'2020-12-24'
# This also works because the string is "interpreted". The rules are stored in the data type, i.e. in the class.
[DateTime]$oneday = '2020-12-24'
# From now on $oneday is always a time specification that can only contain valid values.
$oneday = '2020-15-35'
# Cannot convert value "2020-15-35" to type "System.DateTime". Error: "String was not recognized as a valid DateTime."
```



### Into the world of dbatools: The central data type DbaInstance

I am generally a friend of loading the required modules right at the beginning of a script, i.e. importing them. This is mostly not necessary, because the module is loaded automatically the first time a command from this module is used. But I always see this also as a documentation of the dependencies. So it is quickly clear to the reader which modules are needed to execute the script. But in our concrete case it is mandatory to load the module first. This is because we want to use a data type - i.e. a class - of the module even before the first command is used.

```powershell
Import-Module -Name dbatools
```

The central data type for storing information about a SQL Server instance has the name DbaInstanceParameter as well as the somewhat shorter alias DbaInstance, which I will use in the following. If you want to have a look at the source code of this class written in C#, you will find it [here on GitHub](https://github.com/sqlcollaborative/dbatools/blob/development/bin/projects/dbatools/dbatools/Parameter/DbaInstanceParameter.cs).

There you will also find the various constructors, each of which accepts an object of the following types (the comments are taken from the source code):

- string (Creates a DBA Instance Parameter from string)
- IPAddress (Creates a DBA Instance Parameter from an IPAddress)
- PingReply (Creates a DBA Instance Parameter from the reply to a ping)
- IPHostEntry (Creates a DBA Instance Parameter from the result of a dns resolution)
- System.Data.SqlClient.SqlConnection (Creates a DBA Instance Parameter from an established SQL Connection)
- Discovery.DbaInstanceReport (Accept and understand discovery reports)
- object (Creates a DBA Instance parameter from any object)

The specification "any object" in the last point is not quite correct, concretely only objects of the following classes are accepted:

- microsoft.sqlserver.management.smo.server
- microsoft.sqlserver.management.smo.linkedserver
- microsoft.activedirectory.management.adcomputer
- microsoft.sqlserver.management.registeredservers.registeredserver

The most common use, however, is to pass a string consisting of the name of the server, possibly also the name of the instance and/or the port to be used. We start very simple and pass only the name of the server and look at the attributes of the created object:

```powershell
$instance = [DbaInstance]::new('MyServer')  # This is possible, but unusual.
[DbaInstance]$instance = 'MyServer'         # This is the typical usage. This also sets the data type of the variable for the future.
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

Why do I call DbaInstance the central data type? All parameters of dbatools commands in which an instance is passed (these parameters typically have the name SqlInstance) are declared with the data type DbaInstance, therefore automatically convert the passed value into this data type. So to know exactly what is passed to the command, this conversion can be done beforehand. Especially when analyzing connection problems, it can be useful to proceed in small steps here.

Here are a few examples of which strings are interpreted in which form. The variable `$instances` is declared here as an array of objects of the data type DbaInstance:

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



### Establishing a connection to an instance: Connect-DbaInstance

For the further course I now use the information of a SQL Server instance of my test environment. If you want to build a similar test environment, you can find more information [here](https://blog.ordix.de/microsoft-sql-server-setting-up-an-always-on-availability-group-with-powershell-part-1).

```powershell
[DbaInstance]$SqlInstance = 'SRV1\SQL2016'
```

Any dbatools command that provides the `SqlInstance` parameter will, as a first step, connect to this instance using the `Connect-DbaInstance` command. In many commands exactly this line appears for this purpose:

```powershell
$server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
```

In my test environment I can log on to the SQL Server instances with my Windows account, so I don't need `$SqlCredential`. However, I could use it to log in under a specific login, I will show that later in this article. If no warning is issued, the connection worked and I can display some central information about the connection:

```powershell
$server

<#

ComputerName Name         Product              Version   HostPlatform IsAzure IsClustered ConnectedAs
------------ ----         -------              -------   ------------ ------- ----------- -----------
SRV1         SRV1\SQL2016 Microsoft SQL Server 13.0.5850 Windows      False   False       COMPANY\Administrator

#>
```

The attribute `Name` contains the attribute `FullSmoName` from my object `$SqlInstance`. I did not specify the data type of `$server`, it is determined by the `Connect-DbaInstance` command. Let's see what data type `$server` got:

```powershell
$server.GetType().FullName  # Microsoft.SqlServer.Management.Smo.Server
```

The method `Name` would only output "Server" here, so I use the method `FullName` here.

So we are dealing with an official data type or class provided by Microsoft, the documentation can be found [here](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.server). Behind it hides "the complete instance", over the different attributes and methods an access is possible to almost all properties of the instance as well as the attached databases. Simple queries are already possible via the `Query` method:

```powershell
$server.Query('SELECT @@SPID AS ServerProcessID')

<#

ServerProcessID
---------------
             54

#>
```

And what is the data type of the object returned by this method?

```powershell
$server.Query('SELECT @@SPID AS ServerProcessID').GetType().FullName  # System.Data.DataRow
```

If I just want the number, I can also access the value of the column directly:

```powershell
$server.Query('SELECT @@SPID AS ServerProcessID').ServerProcessID  # 54
```

Why did I just output the SPID (server process ID)? Let's create another connection:

```powershell
$server2 = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
$server2.Query('SELECT @@SPID AS ServerProcessID').ServerProcessID  # 54
```

The query returns the same SPID, so the same connection is used. So are `$server` and `$server2` identical?

```powershell
$server2.Equals($server)  # False
```

No, we have two separate objects of class `Microsoft.SqlServer.Management.Smo.Server`, but they "share" a connection. The keyword here is connection pooling, if you want to research more on that.

For us here, the only important thing at the moment is that the class `Microsoft.SqlServer.Management.Smo.Server` takes care of connection management and reuses existing connections if possible. So it is no problem if different commands of dbatools call `Connect-DbaInstance` again and again to get an object of the class `Microsoft.SqlServer.Management.Smo.Server`. New objects will be created again and again, but they will use the same database connection. At the end of the command, the object is automatically deleted again.

However, there is another way to use Connect-DbaInstance and I will now also use a SQL login to log in:

```powershell
$myCredential = Get-Credential -Message 'SQL Login' -UserName 'myLogin'
[DbaInstance]$myInstance = 'SRV1\SQL2016'

# If the login does not exist yet, it can be created at this point:
New-DbaLogin -SqlInstance $myInstance -Login $myCredential.UserName -SecurePassword $myCredential.Password

# If the warning "SRV1\SQL2016 does not have Mixed Mode enabled" appears, the mode can be changed:
$server = Connect-DbaInstance -SqlInstance $myInstance 
$server.LoginMode = 'Mixed'
$server.Alter()
Restart-DbaService -ComputerName $server.ComputerName -InstanceName $server.InstanceName -Force

# Now all requirements should be created and the registration should work:
$myServer = Connect-DbaInstance -SqlInstance $myInstance -SqlCredential $myCredential
$myServer

<#

ComputerName Name         Product              Version   HostPlatform IsAzure IsClustered ConnectedAs
------------ ----         -------              -------   ------------ ------- ----------- -----------
SRV1         SRV1\SQL2016 Microsoft SQL Server 13.0.5850 Windows      False   False       myLogin

#>

# Let's take a look at the following code:
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

We have given the `Connect-DbaInstance` command as a value for the `SqlInstance` parameter not a string or an object of the `DbaInstance` class, but an object of the `Microsoft.SqlServer.Management.Smo.Server` class. This object already represents a connected SQL Server instance, so the `SqlCredential` specification is not necessary. Because in this case the (most) other parameters are not considered at all and just the passed object is returned. We checked this with `.Equals`, the different variables all refer to one and the same object.

Therefore it is possible to connect to the SQL Server instance needed in a script once at the beginning of the script and then use it again and again. The parameter `SqlCredential` is then also only necessary when calling `Connect-DbaInstance` and not for the further commands, which can increase the readability of the script.

So this line

```powershell
Invoke-DbaQuery -SqlInstance 'SRV1\SQL2016' -Query 'SELECT * FROM dbo.testdata'
```

can also be written like this:

```powershell
[DbaInstance]$myInstance = 'SRV1\SQL2016'
$myServer = Connect-DbaInstance -SqlInstance $myInstance
Invoke-DbaQuery -SqlInstance $myServer -Query 'SELECT * FROM dbo.testdata'
```

The first line converts the string into an object of class `DbaInstance`.
The second line uses this object to connect to the SQL Server instance and returns an object of class `Microsoft.SqlServer.Management.Smo.Server`.
The third line uses this object to execute the query on the SQL Server instance and returns the corresponding data rows.

Creating a separate object of the `DbaInstance` class has advantages especially where the individual elements of the object, for example the computer name or the port, are accessed during the script. Also the attribute `IsLocalHost` can be very useful, it is included only in the class `DbaInstance` but not in the class `Microsoft.SqlServer.Management.Smo.Server`.



### And how do I write my scripts?

I use both, each way has its justification. For simple, short scripts, I use the appropriate command directly and pass in a string as `SqlInstance`. For more complex scripts, where I am issuing multiple commands against the same instances and may need more logging or more error analysis capabilities, I like to separate the connection to the instance from the execution of the commands.
