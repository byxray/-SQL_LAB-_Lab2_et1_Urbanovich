<#
.SYNOPSIS
    .
.DESCRIPTION
    .
.PARAMETER Path
    The path to the .
.PARAMETER LiteralPath
    YOU MUST CHOOSE ONE OF THIS OPTIONS:
    1.	Create a backup for Adventure Work DB,  and restore it on the instance 1.
    2.	Make update of any table with SELECT Before and SELECT after. 
    3.	Create full compressed backup of DB
    4.	Restore it on second Instance.
.EXAMPLE
    C:\PS> 
.NOTES
    Author: Urbanovich Sergei
    Date:   Nov 16, 2018    
#>


[CmdletBinding()] 

Param (

[parameter(Mandatory=$true,HelpMessage="OPTION. [e.g. - 1]")] 
[string]$swOpt,
[parameter(Mandatory=$true,HelpMessage="Password for SQL DB")] 
[String]$pass 

)


$Logfile = "C:\log\$(gc env:computername).log"

$date = Get-Date
LogWrite -logstring "Start time script $($date)" -error "false"


Function LogWrite
{
   Param ([string]$logstring, [string]$error)

   If($error -eq "false") {

       Add-content $Logfile -value $logstring
       Write-Host $logstring -ForegroundColor White -BackgroundColor DarkGreen

   } else {

       Add-content $Logfile -value "ERROR=> $($logstring)"
       Add-content $Logfile -value "=== UNEXPECTED COMPLETION ==="
       Write-Host $logstring -ForegroundColor White -BackgroundColor DarkRed
   }
}


If($swOpt -eq 1){

    $nameOfDB = "AdventureWorks2012" # Read-Host -Prompt 'Input name of BU DB'

    $Query_CrBU = @"
BACKUP DATABASE [$nameOfDB] TO  DISK = N'P:\\$nameOfDB.bak' WITH NOFORMAT, NOINIT,  NAME = N'$nameOfDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
"@

    try{

        Invoke-Sqlcmd -ServerInstance localhost -Username 'Sa' -Password $pass -Query $Query_CrBU
        LogWrite -logstring "BU - $($nameOfDB) was created" -error "false"

       } 
    catch{

        LogWrite -logstring "BU - $($nameOfDB) wasn't created" -error "true"
        Exit

       }

    $Query_ReBU = @"
USE [master]
ALTER DATABASE [$nameOfDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [$nameOfDB] FROM  DISK = N'E:\\$nameOfDB.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
ALTER DATABASE [$nameOfDB] SET MULTI_USER
"@

    try{

        Invoke-Sqlcmd -ServerInstance localhost -Username 'Sa' -Password $pass -Query $Query_ReBU
        LogWrite -logstring "BU - $($nameOfDB) was restored" -error "false"

       } 
    catch{

        LogWrite -logstring "BU - $($nameOfDB) wasn't restored" -error "true"
        Exit

       }    


} elseif ($swOpt -eq 2) {

    $newVal = Read-Host -Prompt 'Input new PhoneNumber'
    $BEID = Read-Host -Prompt 'Input BusinessEntityID'
       
    $Query_Upd = @"
SELECT PhoneNumber FROM urbanovich_db.Person.PersonPhone
WHERE BusinessEntityID = $BEID;

begin tran
UPDATE urbanovich_db.Person.PersonPhone
SET PhoneNumber='$newVal'
WHERE BusinessEntityID = $BEID;

SELECT PhoneNumber FROM urbanovich_db.Person.PersonPhone
WHERE BusinessEntityID = $BEID;
rollback tran
"@    

    try{

        Invoke-Sqlcmd -ServerInstance localhost -Username 'Sa' -Password $pass -Query $Query_Upd
        LogWrite -logstring "Phone Number was changed on $($newVal) for ID $($BEID)" -error "false"

       } 
    catch{

        LogWrite -logstring "Phone Number wasn't cnanged on $($newVal) for ID $($BEID)" -error "true"
        Exit

       }    

} elseif ($swOpt -eq 3) {

    $nameOfBUDB = "urbanovich_db"    # Read-Host -Prompt 'Input name of DB'
    $nameOfBU = "AdventureWorks2012" # Read-Host -Prompt 'Input name of BU DB'

    $Query_FullComprBU = @"
BACKUP DATABASE [$nameOfBUDB] TO  DISK = N'E:\$nameOfBU.bak' WITH NOFORMAT, NOINIT,  NAME = N'$nameOfBUDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
"@

    try{

        Invoke-Sqlcmd -ServerInstance localhost -Username 'Sa' -Password $pass -Query $Query_FullComprBU
        LogWrite -logstring "Full Compressed BU - $($nameOfBU) was created" -error "false"

       } 
    catch{

        LogWrite -logstring "Full Compressed BU - $($nameOfBU) was FAILED" -error "true"
        Exit

       }
    

} elseif ($swOpt -eq 4) {

    $ipRemouteHost = Read-Host -Prompt 'Input IP remote host'
    $nameOfBUDB = "urbanovich_db"    # Read-Host -Prompt 'Input name of DB'
    $nameOfBU = "AdventureWorks2012" # Read-Host -Prompt 'Input name of BU DB'

    $Query_ReFullComprBU = @"
USE [master]
RESTORE DATABASE [$nameOfBUDB] FROM  DISK = N'L:\$nameOfBU.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
"@
    try{

        Invoke-Sqlcmd -ServerInstance $ip -Username 'Sa' -Password $pass -Query $Query_ReFullComprBU
        LogWrite -logstring "BU - $($nameOfBU) was restored on $($ip)" -error "false"

       } 
    catch{

        LogWrite -logstring "BU - $($nameOfBU) was FAILED on $($ip)" -error "true"
        Exit

       }   

}

LogWrite -logstring "Finish time script $($date)" -error "false"