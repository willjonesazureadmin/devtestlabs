$VM = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET  -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
Install-Module -Name Az.ConnectedMachine -Force
Login-AzAccount -Identity
az vm extension set --publisher Microsoft.Azure.ActiveDirectory --name AADLoginForWindows --resource-group $vm.compute.resourceGroupName --vm-name $vm.compute.name
