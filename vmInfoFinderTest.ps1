#add the snapin for Veeam
    Add-PSSnapin VeeamPSSnapin
                                $PowerCLIModulePath = “C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Modules”
                            $OldModulePath = [Environment]::GetEnvironmentVariable(‘PSModulePath’,’Machine’)
                            if ($OldModulePath -notmatch “PowerCLI”) {
                            Write-Host “[Adding PowerCLI Module directory to Machine PSModulePath]” -ForegroundColor Green
                            $OldModulePath += “;$PowerCLIModulePath”
                            [Environment]::SetEnvironmentVariable(‘PSModulePath’,”$OldModulePath”,’Machine’)
                            } else {
                            Write-Host “[PowerCLI Module directory already in PSModulePath. No action taken]” -ForegroundColor Cyan
                            }
                            Add-PSSnapin vmware.vimautomation.core -ErrorAction Stop

                                $vcenter = Read-Host -Prompt "Please enter your VC or host name"
    connect-viserver -Server $vcenter


#get list of proxies and pull the name
    $VeeamProxyList = Get-VBRViProxy | Where-Object {$_.ChassisType -eq "ViVirtual"} | Resolve-DnsName -Name {$_.host.name}
    $VMwareProxyList = Get-VM | select Name, {$_.Guest.Hostname}
    $listA = $VeeamProxyList.name
    $listB = $VMwareProxyList.'$_.Guest.Hostname'
    Compare-Object $listA $listB -ExcludeDifferent

    foreach ($item in $listB) {if ($listA -contains $item) {Write-Host $item}}
    foreach ($viVM in $VMwareProxyList.'$_.guest.hostname') {if ($VeeamProxyList.name -contains $viVM) {$vmtoquery += ,$VMwareProxyList -match $viVM}}





#Get Proxy disk list to display in window for viewing.
    Write-Host "`nChecking Proxies, please wait" -ForegroundColor Green
    foreach ($vm in $VeeamProxyList.name)
    {
        
        if($VMwareProxyList.'$_.Guest.HostName' -match $vm)
                    {
                        Write-Host "`nDisk list for proxy $vm" -ForegroundColor Green
                        $disks = Get-HardDisk -vm $_.name
                        foreach($vdisk in $disks)
                            {
                                Write-Host $vdisk.Filename
                            }
                    }
        elseif(($viIP = Get-VM | Where-Object -FilterScript {$_.Guest.IPAddress -contains $DNS.IP4Address[0]})-ne $null)
                            {
                                Write-Host "`nDisk list for proxy $viIP" -ForegroundColor Green
                                $disks = Get-HardDisk -VM $viIP
                                foreach($disk in $disks)
                                    {
                                        Write-Host $disk.Filename
                                    }
                            }
        else
        {
            break
        }
    }
