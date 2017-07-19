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

Add-PSSnapin VeeamPSSnapin
Connect-VIServer -Server ssa-vc


$testProxyList = Get-VBRViProxy | Where-Object {$_.ChassisType -eq "ViVirtual"}
$testProxyNameList = $testProxyList.host.name
$testVBRProxyDNSList = foreach ($proxy in $testProxyNameList)
    {
        $vbrproxyDNS = Resolve-DnsName -Name $proxy
        $testProxyDNSList +=, $vbrproxyDNS.name
    }

foreach($vbrProxy in ($testProxyDNSList | select -Unique))
    {
        #Use Resolved DNS List to search VMware for VM with matching DNS name since display name can be different
        Try
            {
                $vmwareProxy = Get-VM | Where-Object -FilterScript { $_.Guest.Hostname -contains $vbrProxy }
                $vmwareList +=, $vmwareProxy.Name
            }
        Catch
            {

            }
        
    }