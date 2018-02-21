# Add VMware Plugins
Get-Module -ListAvailable "VMware*" | Import-Module
$vcenter = Read-Host("Please enter your vCenter name to connect and gather VM info: ")
Try{Connect-VIServer -Server $vcenter} 
Catch 
{
    Write-Host "Cannot connect to VMware. Is PowerCLI installed?" -ForegroundColor Red
    Break
}


# get Thumbprint, compliments of https://gist.github.com/lamw/988e4599c0f88d9fc25c9f2af8b72c92
Function Get-SSLThumbprint {
    param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [Alias('FullName')]
    [String]$URL
    )

add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
            public class IDontCarePolicy : ICertificatePolicy {
            public IDontCarePolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy

    # Need to connect using simple GET operation for this to work
    Invoke-RestMethod -Uri $URL -Method Get | Out-Null

    $ENDPOINT_REQUEST = [System.Net.Webrequest]::Create("$URL")
    $SSL_THUMBPRINT = $ENDPOINT_REQUEST.ServicePoint.Certificate.GetCertHashString()

    return $SSL_THUMBPRINT -replace '(..(?!$))','$1:'
}

# vCenter Server URL
#$vcurl = Read-Host("Please enter your VC URL in https form")
$vcurl = "https://" + $vcenter + "/"

# Example output

$thumb = Get-SSLThumbprint $vcurl


############################################
############################################
# define variables #########################
############################################
############################################

# VDLS Paths:





# define user name and pass ! this is in plaintext
$userName = Read-Host("Please enter the host/vc USERNAME as it was added to Veeam: ")
$pass = Read-Host("Please enter the PASSWORD for that user. Note, this IS IN PLAINTEXT!: ")

# pick your VM
$vm = Get-VM -Name (Read-Host("Enter the VM Name you wish to test: "))
$trimstring = "VirtualMachine-"
$addstring = "moref="
$vmTrim = $vm.Id.Trim($trimstring)
$myVM = $addstring + $vmTrim
$myVM
# get more VM data
# snap info:
# create snap
Write-Host "Creating snapshot for VM" $vm.Name -ForegroundColor Green
$diskPath = Get-HardDisk -VM $vm
$diskPath.FileName
New-Snapshot -VM $vm -Name "VDLS Test Snap" -Memory:$false -Quiesce:$false
$snapString = Get-Snapshot -VM $vm
$snapTrim = "VirtualMachineSnapshot-"
$snap = "snapshot-" + $snapString.Id.Trim($snapTrim)




# set transport mode selection
$transModeSelection = Read-Host("What mode shall we test? Enter 1 for NBD, 2 for HotAdd, 3 for SAN: ")
if($transModeSelection -eq 1) {$transport = "nbd"} elseif($transModeSelection -eq 2){$transport = "hotadd"} elseif($transModeSelection = 3){$transport = "san"}

# determin read or write tests
$readOrWrite = Read-Host("Read or Write Test? Enter 1 for Read or 2 for Write: ")
if($readOrWrite -eq 1) {$mode = "-readbench"} else {$mode = "-writebench"}

# Execute!!
# pick VDDK Version to use:
$version = Read-Host('Which VDDK Version shall we use? Enter 1 for 6.5; 2 for 6.0; 3 for 5.5: ')
Switch ($version)
    {
        1
            {
                $isFileThere = gci C:\temp\VMware-vix-disklib-6.5.0-4604867.x86_64 -ErrorAction SilentlyContinue
                    if($isFileThere -eq $null)
                    {
                        Write-Host 'Please Extract the folder "VMware-vix-disklib-6.0.0-2498720.x86_64" to C:\temp and retry.' -ForegroundColor Red
                        Break
                    }

                
                $initEx = "C:\temp\VMware-vix-disklib-6.5.0-4604867.x86 64\doc\functions\VixDiskLib_InitEx.txt"
                $libDir = "C:\Program Files (x86)\Veeam\Backup Transport\x64\vddk_6_5"
                $libList = gci $libDir -ErrorAction SilentlyContinue
                if ($libList -eq $null)
                    {
                        Write-Host 'Cannot find Veeam VDDK files. Is this a proxy server?' -ForegroundColor Red
                        break
                    }
                C:\temp\VMware-vix-disklib-6.5.0-4604867.x86_64\bin\vixDiskLibSample.exe $mode 1024 -host $vcenter -user $userName -password $pass -mode $transport -vm "$myVM" -ssmoref "$snap" -thumb $thumb -initex "$initEx" -libdir "$libDir" $diskPath.FileName
            }
        2
            {
                $isFileThere = gci C:\temp\VMware-vix-disklib-6.0.0-2498720.x86_64 -ErrorAction SilentlyContinue
                    if($isFileThere -eq $null)
                    {
                        Write-Host 'Please Extract the folder "VMware-vix-disklib-6.0.0-2498720.x86_64" to C:\temp and retry.' -ForegroundColor Red
                        Break
                    }
                $initEx = "C:\temp\VMware-vix-disklib-6.0.0-2498720.x86_64\initex.txt"
                $libDir = "C:\Program Files (x86)\Veeam\Backup Transport\x64\vddk_6_0"
                $libList = gci $libDir -ErrorAction SilentlyContinue
                if($libList -eq $null)
                {
                    Write-Host 'Cannot find Veeam VDDK files. Is this a proxy server?' -ForegroundColor Red
                    break
                }
                C:\temp\VMware-vix-disklib-6.0.0-2498720.x86_64\bin\vixDiskLibSample.exe $mode 1024 -host $vcenter -user $userName -password $pass -mode $transport -vm "$myVM" -ssmoref "$snap" -thumb $thumb -initex "$initEx" -libdir "$libDir" $diskPath.FileName
            }
        3
            {
                
            }
    }


#C:\temp\VMware-vix-disklib-6.0.0-2498720.x86_64\bin\vixDiskLibSample.exe $mode 1024 -host $vcenter -user $userName -password $pass -mode $transport -vm "$myVM" -ssmoref "$snap" -thumb $thumb -initex "$initEx" -libdir "$libDir" $diskPath.FileName

# Clean up snaps
Write-Host "Removing  Snapshot: " $snapString.Name -ForegroundColor Green
Remove-Snapshot -Snapshot $snapString -Confirm:$false
#VixDiskLibSample.exe -writebench 1024 -host 10.3.41.8 s-user x -password y -mode nbd -vm "v" -ssmoref "s" -thumb "F2:9D:D7:8D:F1:0E:1E:15:B0:FA:CD:AC:29:ED:9E:98:1A:25:81:99" -initex "d" -libdir "C:\Program Files (x86)\Veeam\Backup Transport\x64\vddk_6_0" Q