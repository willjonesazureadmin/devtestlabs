$storageType = 'StandardSSD_LRS'
$dataDiskNameSuffix =  '_datadisk1'
$diskSize = 200

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted 
Install-PackageProvider -Name nuget -Confirm:$False
Install-Module Az -Confirm:$False


$VM = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET  -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
Login-AzAccount -Identity

$dataDiskName = $VM.compute.name + $dataDiskNameSuffix
$diskConfig = New-AzDiskConfig -SkuName $storageType -Location $vm.compute.location -CreateOption Empty -DiskSizeGB $diskSize 
$dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $vm.compute.resourceGroupName 

$vmToUpdate = Get-AzVM -Name $VM.Compute.Name -ResourceGroupName $vm.compute.resourceGroupName
Add-AzVMDataDisk -VM $vmToUpdate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1

Update-AzVM -VM $vmToUpdate -ResourceGroupName $vm.compute.resourceGroupName -AsJob

Start-Sleep -Seconds 15

$disks = Get-Disk | Where-Object partitionstyle -eq 'raw' | Sort-Object number

    $letters = 70..89 | ForEach-Object { [char]$_ }
    $count = 0
    $labels = "data1","data2"

    foreach ($disk in $disks) {
        $driveLetter = $letters[$count].ToString()
        $disk |
        Initialize-Disk -PartitionStyle MBR -PassThru |
        New-Partition -UseMaximumSize -DriveLetter $driveLetter |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel $labels[$count] -Confirm:$false -Force
	$count++
    }
