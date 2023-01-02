# Mit diesem Skript werden die Beispiele aus den folgenden beiden Artikeln mit PowerShell "nachgebaut":

# JSON als elegante Formatierung von Abfrage-Ergebnissen zum schnellen Datenaustausch:
# https://blog.ordix.de/json-als-elegante-formatierung-von-abfrage-ergebnissen-zum-schnellen-datenaustausch

# Import von JSON-formatierten Informationen in den Microsoft SQL Server:
# https://blog.ordix.de/import-von-json-formatierten-informationen-in-den-microsoft-sql-server-1

# Wir nutzen das PowerShell-Modul dbatools und verbinden uns zu der Instanz, auf der bereits die Datenbank StackOverflow2010 angefügt wurde:

Import-Module -Name dbatools

$connection = Connect-DbaInstance -SqlInstance SQL01 -Database StackOverflow2010



# Die erste Abfrage:

$query01 = @'
SELECT   Id, DisplayName, Reputation
FROM     dbo.Users
WHERE    Reputation > 500000
ORDER BY Reputation DESC
FOR JSON PATH;
'@

$jsonString01 = Invoke-DbaQuery -SqlInstance $connection -Query $query01 -As SingleValue

# Wir können nun den JSON-String ausgeben:
$jsonString01

# Oder alternativ PowerShell-Objekte daraus machen und diese in einer Tabelle darstellen:
$jsonString01 | ConvertFrom-Json | Format-Table



# Die zweite Abfrage:

$query02 = @'
SELECT (SELECT   Users.Id, Users.DisplayName, Users.Reputation
        ,        (SELECT   Posts.Id, Posts.CreationDate, Posts.AnswerCount
                  FROM     dbo.Posts
                  WHERE    Posts.OwnerUserId = Users.Id
                  AND      Posts.AnswerCount > 0
                  ORDER BY Posts.CreationDate
                  FOR JSON PATH
                 ) "Posts"
        FROM     dbo.Users
        WHERE    Users.Reputation > 500000
        ORDER BY Users.Reputation DESC
        FOR JSON PATH
       ) AS Ausgabe;
'@

$jsonString02 = Invoke-DbaQuery -SqlInstance $connection -Query $query02 -As SingleValue

# Wir können nun den JSON-String ausgeben:
$jsonString02

# Oder alternativ PowerShell-Objekte daraus machen und diese in einer Tabelle darstellen:
$jsonString02 | ConvertFrom-Json | Format-Table

# Die Spalte "Posts" ist wiederum eine "Tabelle". Wir stellen einfach mal die Posts der ersten Zeile dar:
($jsonString02 | ConvertFrom-Json) | Select-Object -First 1 -ExpandProperty Posts | Format-Table



# Die dritte Abfrage:

$query03 = @'
SELECT (SELECT   Users.Id          AS "User.Id"
        ,        Users.DisplayName AS "User.DisplayName"
        ,        Users.Reputation  AS "User.Reputation"
        ,        (SELECT   Posts.Id, Posts.CreationDate, Posts.AnswerCount
                  FROM     dbo.Posts
                  WHERE    Posts.OwnerUserId = Users.Id
                  AND      Posts.AnswerCount > 0
                  ORDER BY Posts.CreationDate
                  FOR JSON PATH
                 ) "Posts"
        FROM     dbo.Users
        WHERE    Users.Reputation > 500000
        ORDER BY Users.Reputation desc
        FOR JSON PATH
       ) AS Ausgabe;
'@

$jsonString03 = Invoke-DbaQuery -SqlInstance $connection -Query $query03 -As SingleValue

# Wir können nun den JSON-String ausgeben:
$jsonString03

# Oder alternativ PowerShell-Objekte daraus machen und diese in einer Tabelle darstellen:
$jsonString03 | ConvertFrom-Json | Format-Table

# Jetzt ist auch die Spalte "User" wiederum eine "Tabelle", allerdings mit jeweils nur einer Zeile. Wir stellen einfach mal die Informationen der ersten Zeile dar:
($jsonString03 | ConvertFrom-Json) | Select-Object -First 1 -ExpandProperty User | Format-Table



# Die vierte Abfrage:

$query04 = @'
SELECT (SELECT name AS "DatabaseName"
        ,      (SELECT file_id, type_desc, name, physical_name, size
                FROM   sys.master_files
                WHERE  master_files.database_id = databases.database_id
                FOR JSON PATH
               ) "Files"
        FROM   sys.databases
        WHERE  database_id <= 4 FOR JSON PATH
       ) AS Ausgabe;
'@

$jsonString04 = Invoke-DbaQuery -SqlInstance $connection -Query $query04 -As SingleValue

# An diesem String zeige ich nun, das auch PowerShell den String "hübsch" formatieren kann:

($jsonString04 | ConvertFrom-Json) | ConvertTo-Json -Depth 3

# Und natürlich kann der String (in beiden Darstellungen) in eine Datei gespeichert werden und auch wieder gelesen werden:

$jsonString04 | Set-Content -Path $env:TEMP\json_demo.txt
Get-Content -Path $env:TEMP\json_demo.txt | ConvertFrom-Json | Format-Table
Remove-Item -Path $env:TEMP\json_demo.txt



# Das war der erste Artikel mit den Abfragen, jetzt folgt der zweite mit dem Import.



# Das sind die Datenpakete aus dem Artikel:

$datenpaket01 = @'
[{
		"Id": 22656,
		"DisplayName": "Jon Skeet",
		"Reputation": 990402
	}, {
		"Id": 29407,
		"DisplayName": "Darin Dimitrov",
		"Reputation": 768383
	}, {
		"Id": 157882,
		"DisplayName": "BalusC",
		"Reputation": 766766
	}, {
		"Id": 6309,
		"DisplayName": "VonC",
		"Reputation": 730237
	}, {
		"Id": 17034,
		"DisplayName": "Hans Passant",
		"Reputation": 728015
	}
] 
'@


$datenpaket02 = @'
[{ 
      "User": { 
         "Id": 22656, 
         "DisplayName": "Jon Skeet", 
         "Reputation": 990402 }, 
      "Posts": [{ 
            "Id": 194484, 
            "CreationDate": "2008-10-11T19:30:45.407", 
            "AnswerCount": 37 
         }, { 
            "Id": 215548, 
            "CreationDate": "2008-10-18T20:47:40.003", 
            "AnswerCount": 42 
         }, { 
            "Id": 3438806, 
            "CreationDate": "2010-08-09T09:40:42.517", 
            "AnswerCount": 10 
         }, { 
            "Id": 3657778, 
            "CreationDate": "2010-09-07T10:27:17.253", 
            "AnswerCount": 9 
         }
      ]
    }, { 
      "User": { 
         "Id": 29407, 
         "DisplayName": "Darin Dimitrov", 
         "Reputation": 768383 }, 
      "Posts": [{ 
            "Id": 269988, 
            "CreationDate": "2008-11-06T19:40:47.670", 
            "AnswerCount": 6 
         }, { 
            "Id": 311696, 
            "CreationDate": "2008-11-22T19:51:53.737", 
            "AnswerCount": 5 
         }, { 
            "Id": 3220242, 
            "CreationDate": "2010-07-10T17:47:54.397", 
            "AnswerCount": 6 
         }
      ]
   }, { 
      "User": { 
         "Id": 69083, 
         "DisplayName": "Guffa", 
         "Reputation": 504630 }, 
      "Posts": [{ 
            "Id": 2643812, 
            "CreationDate": "2010-04-15T08:41:19.703", 
            "AnswerCount": 2 
         }, { 
            "Id": 2740709, 
            "CreationDate": "2010-04-29T20:53:45.680", 
            "AnswerCount": 1 
         }
      ]
   }
] 
'@



# Aufbau der Zieltabellen:

$createTable01 = @'
CREATE TABLE UserReputation
( Id            INT PRIMARY KEY
, DisplayName   VARCHAR(100)
, Reputation    INT
)
'@
Invoke-DbaQuery -SqlInstance $connection -Query $createTable01 

$createTable02 = @'
CREATE TABLE UserPosts
( Id            INT PRIMARY KEY
, CreationDate  DATETIME
, AnswerCount   INT
, UserId        INT FOREIGN KEY REFERENCES UserReputation (Id)
)
'@
Invoke-DbaQuery -SqlInstance $connection -Query $createTable02 



# Wir definieren einen SQL-Parameter mit dem JSON-String des erstes Datenpaketes:

$sqlParameter = @{
    JsonString = $datenpaket01
}

# Damit funktioniert dann schon mal die ganz einfache Abfrage, die sich am besten im GridView darstellen lässt:

Invoke-DbaQuery -SqlInstance $connection -Query "SELECT * FROM OPENJSON(@JsonString)" -SqlParameter $sqlParameter | Out-GridView



# Zunächst noch einmal als Abfrage, aber dafür schon mit den richtigen Spaltennamen:

$query05 = @'
SELECT * 
  FROM OPENJSON(@JsonString)
       WITH ( Id           INT
            , DisplayName  VARCHAR(100)
            , Reputation   INT
            ) 
'@

Invoke-DbaQuery -SqlInstance $connection -Query $query05 -SqlParameter $sqlParameter | Format-Table



# Jetzt als INSERT:

$query06 = @'
INSERT INTO UserReputation 
SELECT * 
  FROM OPENJSON(@JsonString)
       WITH ( Id           INT
            , DisplayName  VARCHAR(100)
            , Reputation   INT
            ) 
'@

Invoke-DbaQuery -SqlInstance $connection -Query $query06 -SqlParameter $sqlParameter

# Sind die Daten eingefügt worden? Ja:

Invoke-DbaQuery -SqlInstance $connection -Query "SELECT * FROM UserReputation" | Format-Table

# Und wieder löschen:

Invoke-DbaQuery -SqlInstance $connection -Query "DELETE UserReputation" 



# Nun verwenden wir das zweite Datenpaket, zunächst wieder als Abfrage, aber schon komplett mit der Zerlegung aller Daten:

$sqlParameter = @{
    JsonString = $datenpaket02
}

$query07 = @'
SELECT [User].*, Posts.* 
  FROM OPENJSON(@JsonString) WITH ( [User]  NVARCHAR(MAX) AS JSON
                                  , Posts   NVARCHAR(MAX) AS JSON
                                  ) AS UserAndPosts
       CROSS APPLY OPENJSON(UserAndPosts.[User]) WITH ( Id           INT
                                                      , DisplayName  VARCHAR(100)
                                                      , Reputation   INT
                                                      ) AS [User] 
       CROSS APPLY OPENJSON(UserAndPosts.Posts) WITH ( Id           INT
                                                     , CreationDate  DATETIME
                                                     , AnswerCount   INT
                                                     ) AS Posts
'@

Invoke-DbaQuery -SqlInstance $connection -Query $query07 -SqlParameter $sqlParameter | Format-Table



# Jetzt auch diese Daten als INSERT:


$query08 = @'
INSERT INTO UserReputation
SELECT [User].*
  FROM OPENJSON(@JsonString) WITH ( [User]  NVARCHAR(MAX) AS JSON
                                  , Posts   NVARCHAR(MAX) AS JSON
                                  ) AS UserAndPosts
       CROSS APPLY OPENJSON(UserAndPosts.[User]) WITH ( Id           INT
                                                      , DisplayName  VARCHAR(100)
                                                      , Reputation   INT
                                                      ) AS [User]
'@

$query09 = @'
INSERT INTO UserPosts
SELECT Posts.*, [User].Id AS UserId
  FROM OPENJSON(@JsonString) WITH ( [User]  NVARCHAR(MAX) AS JSON
                                  , Posts   NVARCHAR(MAX) AS JSON
                                  ) AS UserAndPosts
       CROSS APPLY OPENJSON(UserAndPosts.[User]) WITH ( Id           INT
                                                      , DisplayName  VARCHAR(100)
                                                      , Reputation   INT
                                                      ) AS [User] 
       CROSS APPLY OPENJSON(UserAndPosts.Posts) WITH ( Id           INT
                                                     , CreationDate  DATETIME
                                                     , AnswerCount   INT
                                                     ) AS Posts 
'@

Invoke-DbaQuery -SqlInstance $connection -Query $query08 -SqlParameter $sqlParameter
Invoke-DbaQuery -SqlInstance $connection -Query $query09 -SqlParameter $sqlParameter

# Sind die Daten eingefügt worden? Ja:

Invoke-DbaQuery -SqlInstance $connection -Query "SELECT * FROM UserReputation" | Format-Table
Invoke-DbaQuery -SqlInstance $connection -Query "SELECT * FROM UserPosts" | Format-Table

# Und wieder löschen:

Invoke-DbaQuery -SqlInstance $connection -Query "DELETE UserPosts"
Invoke-DbaQuery -SqlInstance $connection -Query "DELETE UserReputation" 



# Zum Abschluss jetzt noch ohne die JSON-Funktionalität der Datenbank, statt dessen direkt mit dbatools.



# Für das Datenpaket 1 geht das ganz einfach in einer Zeile:

$datenpaket01 | ConvertFrom-Json | Write-DbaDbTableData -SqlInstance $connection -Table UserReputation

# Sind die Daten eingefügt worden? Ja:

Invoke-DbaQuery -SqlInstance $connection -Query "SELECT * FROM UserReputation" | Format-Table

# Und wieder löschen:

Invoke-DbaQuery -SqlInstance $connection -Query "DELETE UserReputation" 



# Für das Datenpaket 2 nutzen wir eine Schleife:

foreach ($row in ($datenpaket02 | ConvertFrom-Json)) {
    $row.User | Write-DbaDbTableData -SqlInstance $connection -Table UserReputation
    $row.Posts | Write-DbaDbTableData -SqlInstance $connection -Table UserPosts
}

# Oder als Alternative ForEach-Object:

$datenpaket02 | ConvertFrom-Json | ForEach-Object -Process {
    $_.User | Write-DbaDbTableData -SqlInstance $connection -Table UserReputation
    $_.Posts | Write-DbaDbTableData -SqlInstance $connection -Table UserPosts
}

# Sind die Daten eingefügt worden? Ja:

Invoke-DbaQuery -SqlInstance $connection -Query "SELECT * FROM UserReputation" | Format-Table
Invoke-DbaQuery -SqlInstance $connection -Query "SELECT * FROM UserPosts" | Format-Table

# Und wieder löschen:

Invoke-DbaQuery -SqlInstance $connection -Query "DELETE UserPosts"
Invoke-DbaQuery -SqlInstance $connection -Query "DELETE UserReputation" 
