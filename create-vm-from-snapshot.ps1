# Provide the subscription Id
subscriptionId='2fbf906e-1101-4bc0-b64f-adc44e462fff'

# Provide the name of your resource group
resourceGroupName='LB'

# Provide the name of the snapshot that will be used to create OS disk
snapshotName='web1-snapshot'

# Provide the name of the OS disk that will be created using the snapshot
osDiskName='web1_OsDisk_1_910158270e0b4a4893ba269b1301c609'

# Provide the name of an existing virtual network where virtual machine will be created
virtualNetworkName='hybrid-rg'

# Provide the name of the virtual machine
virtualMachineName='web1'

# Provide the size of the virtual machine
# e.g. Standard_DS3
# Get all the vm sizes in a region using below script:
# e.g. az vm list-sizes --location 'East US 2'
virtualMachineSize='Standard_D3_v2'

# Set the context to the subscription Id where Managed Disk will be created
az account set --subscription $subscriptionId

# Get the snapshot details
snapshot=$(az snapshot show --resource-group $resourceGroupName --name $snapshotName)

# Get the location of the snapshot
snapshotLocation=$(echo $snapshot | jq -r '.location')

# Get the ID of the snapshot
snapshotId=$(echo $snapshot | jq -r '.id')

# Create disk configuration
diskConfig=$(az disk create --location $snapshotLocation --source $snapshotId --create-option Copy)

# Extract disk ID from diskConfig
diskId=$(echo $diskConfig | jq -r '.id')

# Initialize virtual machine configuration
VirtualMachine=$(az vm create \
    --resource-group $resourceGroupName \
    --name $virtualMachineName \
    --location $snapshotLocation \
    --size $virtualMachineSize \
    --nics $nicId \
    --os-disk $diskId \
    --attach-os-disk attach)

# Create a public IP for the VM
publicIp=$(az network public-ip create \
    --resource-group $resourceGroupName \
    --name ${virtualMachineName,,}_ip \
    --location $snapshotLocation \
    --allocation-method Dynamic)

# Get the virtual network where virtual machine will be hosted
vnet=$(az network vnet show --name $virtualNetworkName --resource-group $resourceGroupName)

# Create NIC in the first subnet of the virtual network
nic=$(az network nic create \
    --resource-group $resourceGroupName \
    --name ${virtualMachineName,,}_nic \
    --location $snapshotLocation \
    --vnet-name $virtualNetworkName \
    --subnet $(echo $vnet | jq -r '.subnets[0].id') \
    --public-ip-address $publicIp)

# Extract NIC ID from NIC
nicId=$(echo $nic | jq -r '.id')

# Update VM with NIC
az vm nic add --resource-group $resourceGroupName --vm-name $virtualMachineName --nics $nicId