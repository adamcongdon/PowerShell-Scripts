# by Adam.Congdon
# see here for more detail: https://helpcenter.veeam.com/docs/backup/powershell/
# Use at your own risk - I tested with success in my lab.

# WHAT DOES IT DO:
# this tool should remove all backups from configuration database but skip replicas, and encrypted backups

Add-PSSnapin VeeamPSSnapin
$backups = Get-VBRBackup

foreach($backup in $backups)
{
    Write-Host "Removing backups from: " $backup.Name -ForegroundColor Yellow
    Try
    {
        Remove-VBRBackup $backup -FromDisk:$false -confirm:$false > $null
    }
    Catch
    {
        Write-Host "Failed to remove backup for " $backup.Name " try doing so manually" -ForegroundColor Red
    }
}