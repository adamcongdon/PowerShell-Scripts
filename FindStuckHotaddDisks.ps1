#Written by Adam Congdon (adam.congdon@veeam.com)

#add the snapin for Veeam
    Add-PSSnapin VeeamPSSnapin

#Menu to pick with PowerCLI version to use
    $title = "Select PowerCLI Version"
    $message = "Pick which PowerCLI version you have installed `n Mouse over the option for Details"
    $65 = New-Object System.Management.Automation.Host.ChoiceDescription "&6.5", `
        "Selects version 6.5 (compatible with vCenter 5.5 through 6.5 excluding 5.5u3)"

    $50 = New-Object System.Management.Automation.Host.ChoiceDescription "&5-6.0", `
        "Specifies installed version of 6.0 (compatible with vCenter 5.0 through 6.0u2)"

    $40 = New-Object System.Management.Automation.Host.ChoiceDescription "&4.x", `
        "Specifies vCenter of 4.x which requires untested powerCLI. Please manually adjust script or allow time for updated version"

    $help = New-Object System.Management.Automation.Host.ChoiceDescription "&HELP", `
        "Prints the URL for the VMware Compatibility Matrix to help you decide"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($65, $50, $40, $help)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0)

    switch ($result)
        {
            0 
                {
                    Try
                        {
                            Install-Module -Name VMware.PowerCLI –Scope CurrentUser
                        }
                    Catch
                        {
                            exit
                        }
                }
            1 
                {
                    Try
                        {
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
                        }
                    Catch
                        {
                            Write-Host "Appropriate PowerCLI module not installed or not found in default install path. Please check script for appropriate path"
                            exit
                        }
                }
            2 
                {
                    Write-Host "This PowerCLI/vSphere version combo was not tested. Try using 5x-6.0 option"
                    exit
                }
            3 
                {
                    Write-Host "https://www.vmware.com/resources/compatibility/sim/interop_matrix.php#interop&299=&2=" 
                    exit
                }
        }


#connect to VC by asking for user's VC
    $vcenter = Read-Host -Prompt "Please enter your VC or host name"
    connect-viserver -Server $vcenter

#Get Proxy disk list to display in window for viewing.
    Write-Host "Checking Proxies, please note this time table is relative to total VM count" -ForegroundColor Green
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
            Write-Host "`nDisk list for proxy $trueProxy" -ForegroundColor Green
            $disks = Get-HardDisk -vm $trueproxy
            foreach($vdisk in $disks)
                {
                    Write-Host $vdisk.Filename
                }
        }

