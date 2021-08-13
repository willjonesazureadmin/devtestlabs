az login --identity

spID=$(az resource list -n <VM-NAME> --query [*].identity.principalId --out tsv)
echo The managed identity for Azure resources service principal ID is $spID


az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADLoginForWindows \
    --resource-group myResourceGroup \
    --vm-name myVM
        
