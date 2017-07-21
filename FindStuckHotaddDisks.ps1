#Written by Adam Congdon (adam.congdon@veeam.com)
# Requires server 2012 + as some CMDlets are not present in prior versions.
# Must be ran on a server with Veeam Backup Console installed
# Must have PowerCLI installed

#add the snapin for Veeam and connect to VBR Server
    Try
        {
            Get-PSSnapin -Registered Veeam* -ErrorAction stop | Add-PSSnapin
        }
    Catch 
        {
            Write-host "Cannot add Veeam PS Snapin. Is Veeam Console installed locally?" -foregroundcolor red
            exit
        }
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

# Add PowerCLI Module or Snapin
    Try
        {
            Get-PsSnapin -registered -erroraction SilentlyContinue | Add-PsSnapin -ErrorAction SilentlyContinue
        }
    Catch
        {
            Write-Host $Error[0] -ForegroundColor Red
            exit
        }
    Try
        {
            Get-Module -ListAvailable VM* -ErrorAction SilentlyContinue | Import-Module -ErrorAction SilentlyContinue
        }
    Catch
        {
            Write-Host $Error[0] -ForegroundColor Red
            exit
        }
                            
#connect to VC by asking for user's VC
    $vcenter = Read-Host -Prompt "Please enter your VC or host name"
    connect-viserver -Server $vcenter

# Gather Proxy and VM list > Compare to find Proxy VM > Find IndependentNonPersistent disks
# Prompt if user would like to remove the disk with double confirmation.
    Write-Host "`nGathering Proxy List. Please note this time table is relative to infrastructure size" -ForegroundColor Green
    $VeeamProxyList = Get-VBRViProxy | Where-Object {$_.ChassisType -eq "ViVirtual"} | Resolve-DnsName -Name {$_.host.name}
    $VMwareProxyList = Get-VM | select Name, {$_.Guest.Hostname}
    
    $trueProxyList = @()
    
    foreach($viVM in $VMwareProxyList.'$_.guest.hostname')
        {
            if ($VeeamProxyList.name -contains $viVM)
                {
                    $matchedlist = $VMwareProxyList -match $viVM
                    $trueProxyList += $matchedlist
                }
        }
    foreach($trueProxy in $trueProxyList.name)
        {
            $disks = Get-HardDisk -vm $trueproxy | where {$_.Persistence -like "*IndependentNon*"}
            if($disks -eq $null) {Write-Host "No foreign disks found on $trueProxy"}
            else
                {
                    Write-Host "`nDisk list for proxy $trueProxy" -ForegroundColor Green
                }
            foreach($vdisk in $disks)
                {
                    Write-Host `n $vdisk.persistence `t $vdisk.filename
                    $input = Read-Host "'nRemove disk from proxy? Yes or No"
                    while("yes","no" -notcontains $input)
                        {
                            $input = Read-Host "'nRemove disk from proxy? Yes or No"
                        }
                    switch($input)
                        {
                            Yes { Remove-HardDisk $vdisk -Confirm}
                            No {}
                        }
                }
        }    
#Log output
         $trueProxyList | Out-File 'StuckHotaddDisks.log'
	 Add-Content 'StuckHotaddDisks.log' 'Disks:'
	 $disks | Out-File 'StuckHotaddDisks.log' -Append
         if($disks -eq $null) {Add-Content 'StuckHotaddDisks.log' "No foreign disks found"}        
