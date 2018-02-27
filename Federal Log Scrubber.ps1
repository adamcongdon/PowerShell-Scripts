
 
<#     
.NOTES 
#=========================================================================== 
# Script: Fed Scrubber   
# Author: Koga  
# Purpose: To scrub Veeam Logs of sensative information
#=========================================================================== 
.DESCRIPTION 
       $location   Make sure to change location
       $Find_1     Change this 
       $Repl_1     Change this 
       $Find_2     Change this 
       $Repl_2     Change this 
#> 


# Get Start Time
$startDTM = (Get-Date)


# Get the date
$DateStamp = get-date -uformat "%Y-%m-%d@%H-%M-%S"
$Space     = write-host ""
$Wait      = Start-Sleep -Seconds 3
$Cls       = Clear-Host

# First two Items Find and Replace           
$Find_1    = Read-Host "Enter Hostname to scrub: "           # Find What 
$Repl_1    = "xxxxxx"           # Replace to 

# Second two Items Find and Replace 
$Find_2    =  Read-Host "Set octet to scrub: (ex. 192.168. or 192.168.1. etc) "             # Find What
$Replace_2 = "x.x"              # Replace to 

# Location of Logs
$location  = Read-Host "Set location of logs to scrub: "


# locating files 
$name      =  Get-childitem $location | Select-Object name

# Counting Logs
$name_C = ($name).count 


Write-host " Getting    logs..."
Write-Host " Located  $name_C logs..." 
$name
Write-Host ".................." -fore green

# Checking Location to make sure it exist 

# Verify Log folder location exists 
  if(( Test-Path -path  $location ) -eq $false ) { 
        Write-host "Log folder does not exist" -f red
        $location 
    }

Else { Write-host " Log folder exist " -f green 
       $location

}

Write-Host " Find    ($Find_1 )..." -f green
Write-Host " Replace ($Repl_1) ..." -f green
$Space
$Space
Write-Host " Find    ($Find_2 )..." -f green
Write-Host " Replace ($Repl_2) ..." -f green


$wait
# looping Through 
Get-childitem $location -recurse | 
 select -expand fullname |
  foreach {
            (Get-Content $_) -replace $Find_1,$Replace_1 |
             Set-Content $_
            (Get-Content $_) -replace $Find_2,$Replace_2 |
             Set-Content $_
          }

# Re-name Files & Day Stamp 

Get-ChildItem $location | rename-item -NewName { $_.DirectoryName +'\' + $_.BaseName + '-Sanitized' + $_.Extension}


Write-Host "Sanitize has ben completed  ..." -f green


# Echo Time elapsed
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

