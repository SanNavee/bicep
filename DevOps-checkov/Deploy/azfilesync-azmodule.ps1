# Gather the OS version
$osver = [System.Environment]::OSVersion.Version

# Download the appropriate version of the Azure File Sync agent for our OS.
# Azure File Sync Version 14.0
# Windows Server 2022
if ($osver.Equals([System.Version]::new(10, 0, 20348, 0))) {
    Invoke-WebRequest `
        -Uri https://download.microsoft.com/download/1/8/D/18DC8184-E7E2-45EF-823F-F8A36B9FF240/StorageSyncAgent_WS2022.msi `
        -OutFile "StorageSyncAgent.msi" 
}
# Windows Server 2019
elseif ($osver.Equals([System.Version]::new(10, 0, 17763, 0))) {
    Invoke-WebRequest `
        -Uri https://download.microsoft.com/download/1/8/D/18DC8184-E7E2-45EF-823F-F8A36B9FF240/StorageSyncAgent_WS2019.msi `
        -OutFile "StorageSyncAgent.msi" 
}
# Windows Server 2016
elseif ($osver.Equals([System.Version]::new(10, 0, 14393, 0))) {
    Invoke-WebRequest `
        -Uri https://download.microsoft.com/download/1/8/D/18DC8184-E7E2-45EF-823F-F8A36B9FF240/StorageSyncAgent_WS2016.msi `
        -OutFile "StorageSyncAgent.msi" 
}
# Windows Server 2012 R2
elseif ($osver.Equals([System.Version]::new(6, 3, 9600, 0))) {
    Invoke-WebRequest `
        -Uri https://download.microsoft.com/download/1/8/D/18DC8184-E7E2-45EF-823F-F8A36B9FF240/StorageSyncAgent_WS2012R2.msi `
        -OutFile "StorageSyncAgent.msi" 
}
else {
    throw [System.PlatformNotSupportedException]::new("Azure File Sync is only supported on Windows Server 2012 R2, Windows Server 2016, Windows Server 2019, and Windows Server 2022")
}

Start-Process -FilePath ".\StorageSyncAgent.msi" -ArgumentList "/quiet" -Wait



Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Make sure you have the latest version of PowerShellGet installed
Install-Module -Name PowerShellGet -Force
# Install and update to the latest Az PowerShell module
Install-Module -Name Az -AllowClobber -Force
# Install and update to the latest Microsoft Azure PowerShell - Storage Sync cmdlets
Install-Module -Name Az.StorageSync


## Download the MSI
 #Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
 
## Invoke the MSI installer suppressing all output
 #Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

##Remove the MSI installer
 #Remove-Item -Path .\AzureCLI.msi