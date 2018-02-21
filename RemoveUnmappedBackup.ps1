# by Adam.Congdon
# see here for more detail: https://helpcenter.veeam.com/docs/backup/powershell/
# Use at your own risk - I tested with success in my lab.

# WHAT DO?
# Removed all un-mapped backups from configuration. You can change the flag to delete from DISK if you so choose

Add-PSSnapin VeeamPSSnapin

    $vbrServer = Read-Host -Prompt "Please Enter Veeam Backup Server you wish to connect or use localhost to connect locally"
    Try
        {
            Disconnect-VBRServer -ErrorAction SilentlyContinue #This is to ensure connections are cleared to prevent failure/duplicate connections to VBRServer
            Connect-VBRServer -Server $vbrServer -ErrorAction Stop
        }
    Catch
        {
            Write-Host $Error[0] -ForegroundColor Red
            exit
        }


$backups = Get-VBRBackup
$jobs = Get-VBRJob

foreach ($backup in $backups)
{
    if($backup.jobid -notin $jobs.id)
    {
        try
        {
            Write-Host "Removing backup: " $backup.Name -ForegroundColor Green
            Remove-VBRBackup $backup -Confirm:$false -FromDisk:$false > $null
        }
        catch
        {
            Write-Host "Failed to remove backup, please try manually." -ForegroundColor Red
        }
    }
}