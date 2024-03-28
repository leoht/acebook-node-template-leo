# This IaC script provisions a VM within Azure
#
[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipal,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalSecret,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalTenantId,

    [Parameter(Mandatory = $True)]
    [string]
    $azureSubscriptionName,

    [Parameter(Mandatory = $True)]  
    [string]
    $serverName,

    [Parameter(Mandatory = $True)]
    [string]
    $sshPrivateKeyPath,

    [Parameter(Mandatory = $True)]  
    [string]
    $sshPublicKeyPath
)


#region Login
# This logs into Azure with a Service Principal Account
#
Write-Output "Logging in to Azure with a service principal..."
az login `
    --service-principal `
    --username $servicePrincipal `
    --password $servicePrincipalSecret `
    --tenant $servicePrincipalTenantId
Write-Output "Done"
Write-Output ""
#endregion

#region Subscription
#This sets the subscription the resources will be created in

Write-Output "Setting default azure subscription..."
az account set `
    --subscription $azureSubscriptionName
Write-Output "Done"
Write-Output ""
#endregion

# Create resource group
az group create -l uksouth -n rg-provisioning

#region Create VM
# Create a VM in the resource group
Write-Output "Creating VM..."
try {
    az vm create  `
        --resource-group rg-provisioning `
        --security-type TrustedLaunch `
        --name $serverName `
        --image "/subscriptions/c8c5a280-46f0-42c8-bf18-cef74238b5bd/resourceGroups/Test_group/providers/Microsoft.Compute/galleries/default/images/test-vm-image-definition/versions/0.0.1" `
        --authentication-type ssh `
        --ssh-key-values $sshPublicKeyPath
    }
catch {
    Write-Output "VM already exists"
    }
Write-Output "Done creating VM"
Write-Output ""

Write-Output "Updating SSH key..."
az vm user update -u azureuser --ssh-key-value "$(cat $sshPublicKeyPath)"  -n $serverName -g  rg-provisioning

Write-Output "Deleting resource group"
az group delete -y -n rg-provisioning --force-deletion-types Microsoft.Compute/virtualMachines