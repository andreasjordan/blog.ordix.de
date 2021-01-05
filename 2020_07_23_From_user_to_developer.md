# From user to developer - using the PowerShell module dbatools to manage Microsoft SQL Servers

### First use in our training courses

The story started when I wanted to show my participants in the [Administration Course for Microsoft SQL Server](https://seminare.ordix.de/seminare/microsoft-sql-server/verwalten-einer-sql-datenbankinfrastruktur-moc-21764.html) in what ways they can perform administrative activities: With the graphical interface of SQL Server Management Studio, with SQL scripts or just with PowerShell, specifically with the [dbatools](https://dbatools.io/) module.

This module contains a lot of useful functions (in PowerShell they are called [Commandlets](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-overview)) and is developed by several people together and provided as free and open source software. Especially in chapters like Backup and Restore, the lean, concise commandlets make for tidy demo scripts.

Since PowerShell is both a scripting language and a full-fledged programming language based on .NET, small procedures are quickly programmed, variables increase clarity and flexibility.


### Preparation for deployment at the customer

Recently, the topic of high availability with [Always On Availability Groups](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server) has come into focus for some of our customers, so of course I wanted to test how the setup with PowerShell works. Because I am not satisfied with the classic wizard of the SQL Server Management Studio. In case of errors there are no meaningful messages and a documentation of the used settings is not possible very well - who wants to have a collection of screenshots in this day and age? Of course, as always, there is the option to have the SQL script generated at the end of the wizard, but even with that I am only partially satisfied.

When working with the corresponding [Commandlets](https://dbatools.io/commands/#AGs) I ran into problems, some things didn't work as expected. The error messages didn't help at first, only a look into the code could help. That is the strength of open source software: Everyone can have a look at the code and adapt it locally to his needs.


### Bugfixing: Every beginning is hard

Finding the first bugs was not that easy. I first had to dive into the world of the module and find out how the individual help functions work and what basic scheme the commandlets follow. And I didn't just want to report that a certain commandlet didn't work, but also to name the cause. In the best case, make a suggestion right away on how to fix the error or make further improvements.


### I need an account at Github

So I entered the world of Github, created an account and immediately created a fork of the [official repository](https://github.com/sqlcollaborative/dbatools) to show my suggestions in the code. Furthermore I reactivated my account at Slack, which I didn't use for some time, to be able to discuss in the [channels of dbatools](https://dbatools.io/slack).

So there was nothing standing in the way of my first issues and pull requests. And with every new pull request, the work with Git goes more smoothly, with every feedback I learn more about the work of the other developers and about the module.


### My first published change

With version 1.0.114 of dbatools released a few days ago, some of my proposed changes are now actually included in the official release and can be used by everyone.

This also allows me to continue with the currently planned series of articles on setting up Always On availability groups with PowerShell and dbatools.


### Discussions around the globe

Of course, it also happens that my suggestions are not well received. Or I have overlooked something because I haven't been around that long. Or there are simply different ideas about what exactly the commandlet should and should not do. This is then discussed in the comments on Github as well as in the channels on Slack. Since some developers are based in the U.S., this often happens with a time lag, so it can take half a day for the next reaction. Also, no one works full time on this project and everyone only takes a few minutes or hours now and then for further development. This slows down the process, of course, but on the other hand it also offers the opportunity to think about the suggestions in peace.


### And how does it benefit ORDIX AG and its customers?

By familiarizing myself with the structure of the module, it is now much easier for me to analyze the causes of unexpected behavior. It's not always a fault in the module, perhaps I simply had different expectations of how it would work. It's also easier for me to incorporate adjustments, initially just for my personal purposes - but of course also for our customers. And they are welcome to contact us if they have any questions about how to use dbatools. Together we can select the right commandlets and integrate them into a customer-specific script. If errors occur, we can analyze them directly on the customer's system, make necessary adjustments and also push the integration into the official release.

Andreas Jordan, info@ordix.de
