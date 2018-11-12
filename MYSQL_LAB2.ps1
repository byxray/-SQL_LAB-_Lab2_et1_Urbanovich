# You must uncomment and run this code one per session

#Set-Item wsman:\localhost\Client\TrustedHosts -value "192.168.1.1"
#Enable-PSRemoting -SkipNetworkProfileCheck -Force
#Start-Service WinRM
#Get-Item WSMan:\localhost\Client\TrustedHosts


###############################################################################

[CmdletBinding()] 

Param ( 

[parameter(Mandatory=$true,HelpMessage="DISK. [e.g. - D:]")] 
[string]$letterDisk,
[parameter(Mandatory=$true,HelpMessage="Password")] 
[String]$pass 

)

$arrPath = @()


Write-Host $StandardStringPass

$Login = "Sa"

$freeSpace = Get-WMIObject Win32_LogicalDisk | Where-Object {($_.DeviceID -like "$($letterDisk)")} | ForEach-Object {$_.FreeSpace}
    
If ($freeSpace/1Gb -gt 0.3) {    
    Write-Host "Enough space on the disk - " $letterDisk -ForegroundColor White -BackgroundColor Green     
    
} else {
    Write-Host "NOT enough space on the disk - " $letterDisk -ForegroundColor White -BackgroundColor Red
    Exit
}

Write-Host "Free space on disk on DISK: $($letterDisk) - $($freeSpace/1Gb) Gb" -ForegroundColor White -BackgroundColor Blue        


# code returns DB files locations before execution
#Try
# {

Invoke-Sqlcmd -ServerInstance 192.168.1.1 -Username $Login -Password $pass -Query @'

SELECT name, physical_name,size,max_size,growth  
FROM sys.master_files  
WHERE database_id = DB_ID(N'tempdb'); 

'@ | ForEach-Object {
    $arrPath += $_.physical_name
}

#}
#Catch [system.exception]
#{

#Write-Host "caught a system exception (open connection)" -ForegroundColor White -BackgroundColor Red

#}


###############################################################################

Try{

Invoke-Sqlcmd -ServerInstance 192.168.1.1 -Username $Login -Password $pass -Query @'

USE [master]
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev', SIZE = 10240KB, FILEGROWTH = 5120KB, FILENAME = 'E:\tempdb.mdf')
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', SIZE = 10240KB, FILEGROWTH = 1024KB, FILENAME = 'E:\templog.ldf')
GO

'@

}
Catch {

Write-Host "caught a system exception (MODIFY FILEs)" -ForegroundColor White -BackgroundColor Red 

}

# Delete old files / Restart SQL to apply changes 

try {

Stop-Service -Name 'MSSQLSERVER' -Force
Write-Host "Stop-Service 'MSSQLSERVER'" -ForegroundColor White -BackgroundColor Blue

foreach($k in $arrPath) {        
    Remove-Item –path $k -Force  
    Write-Host "Remove old file - " $k -ForegroundColor White -BackgroundColor Blue
}

Start-Service -Name 'MSSQLSERVER'
Write-Host "Start-Service 'MSSQLSERVER'" -ForegroundColor White -BackgroundColor Blue

}
catch {

Write-Host "caught a system exception (Delete old files / Restart SQL to apply changes)" -ForegroundColor White -BackgroundColor Red 

}


###############################################################################

# code returns DB files locations after execution 

$arrPath = @()

Invoke-Sqlcmd -ServerInstance 192.168.1.1 -Username $Login -Password $pass -Query @'

SELECT name, physical_name,size,max_size,growth  
FROM sys.master_files  
WHERE database_id = DB_ID(N'tempdb'); 

'@ | ForEach-Object {
    $arrPath += $_.physical_name
}

###############################################################################

# check the existing files with the same name in the target location, and check free space on disk

try {


foreach($i in $arrPath) {
        
    $chkPath = Test-Path $i

    if($chkPath) {            
        Write-Host $i " - File is Existing in the target location" -ForegroundColor White -BackgroundColor DarkGreen
    } else {
        Write-Host $i " - File isn't Existing in the target location" -ForegroundColor White -BackgroundColor DarkYellow
    }
}

$diskLetter = $arrPath[0] -split "\\"

$freeSpace = Get-WMIObject Win32_LogicalDisk | Where-Object {$_.DeviceID -like "$($diskLetter[0])"} | ForEach-Object {$_.FreeSpace}
Write-Host "Free space on disk on DISK: $($diskLetter[0]) - $($freeSpace/1Gb) Gb" -ForegroundColor White -BackgroundColor Blue         


}
catch {

Write-Host "caught a system exception (check files in the target location)" -ForegroundColor White -BackgroundColor Blue 

}

###############################################################################

# Run fom local PC

#$Login = "Administrator"
#$Creds = New-Object -TypeName System.Management.Automation.PSCredential($Login,$pass)
#Invoke-Command -FilePath C:\Users\urbs\OneDrive\sql2\MYSQL_LAB2.ps1 -ComputerName 192.168.1.1 -Credential $Creds








