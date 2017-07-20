#Written by Adam Congdon (adam.congdon@veeam.com)
# Requires server 2012 + as some CMDlets are not present in prior versions.

#add the snapin for Veeam
    Try
        {
            Get-PSSnapin -Registered Veeam* | Add-PSSnapin
        }
    Catch 
        {
            Write-host "Cannot add Veeam PS Snapin. Is Veeam Console installed locally?" -foregroundcolor red
            exit
        }
    $vbrServer = Read-Host -Prompt "Please Enter Veeam Backup Server you wish to connect or use localhost to connect locally."
    Try
        {
            Disconnect-VBRServer #This is to ensure connections are cleared to prevent failure/duplicate connections to VBRServer
            Connect-VBRServer -Server $vbrServer -ErrorAction Stop
        }
    Catch
        {
            Write-Host $Error[0] -ForegroundColor Red
            exit
        }

#Menu to pick with PowerCLI version to use
    $title = "Select PowerCLI Version"
    Try
        {
            Get-PsSnapin -registered -erroraction SilentlyContinue | Add-PsSnapin -ErrorAction SilentlyContinue
        }
    Catch
        {
            $Error
        }
    Try
        {
            Get-Module -ListAvailable VM* -ErrorAction SilentlyContinue | Import-Module -ErrorAction SilentlyContinue
        }
    Catch
        {
            write-host $Error
            exit
        }
                            
        
         


#connect to VC by asking for user's VC
    $vcenter = Read-Host -Prompt "Please enter your VC or host name"
    connect-viserver -Server $vcenter

#Get Proxy disk list to display in window for viewing.
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