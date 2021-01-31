param (
    [parameter (
        mandatory = $false
        )
    ]
    [string]$Computer_Name = "172.27.125.150",
    
    [parameter (
        mandatory = $false
        )
    ]
    [string]$User_Name = "INTIMETEC\Administrator",

    [parameter (
        mandatory = $false
        )
    ]
    [string]$Website_Name = "deploytest",

    [parameter (
        mandatory = $true
        )
    ]
    [int]$Port_Number
)

function Manage-Remote {
#####################################################################################################
<#CREATING & ENTERING PS SESSION#>

    try{
        $password = ConvertTo-SecureString 'BlueBug0811' -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($User_Name, $password)
        $session = New-PSSession -ComputerName $Computer_Name -Credential $credential -ErrorAction stop
        write-host "Created Session"
        }
    catch{
         write-host "Cannot Create Session"
    }
   
    
    Invoke-Command -Session $Session -ScriptBlock {
        <#ENABLING IIS SERVER#>
        param($Web_Name)
        if($((Get-WindowsFeature -Name web-server).installed)) {
            Write-Host "WEB MANAGEMENT SERVICE ALREADY INSTALLED"
        }
        else {
            try {
                add-windowsfeature -name web-server -includemanagementtools
                Write-Host "SUCCESSFULLY ENABLED IISServer"
            }
            catch {
                Write-Host "CANNOT ENABLE IIS SERVER"
                Break;
            }
        }
        <#ENABLING WEB MANAGEMENT SERVICE#>
        if($((Get-WindowsFeature -Name Web-Mgmt-Service).installed)) {
            Write-Host "WEB MANAGEMENT SERVICE ALREADY INSTALLED"
        }
        else {
            try {
                add-windowsfeature -name Web-Mgmt-Service
                Write-Host "SUCCESSFULLY INSTALLED WEB MANAGEMENT SERVICE"
            }
            catch {
                Write-Host "CANNOT INSTALL WEB MANAGEMENT SERVICE"
                Break;
            }
        }
        <#CREATING DIRECTORY FOR WEBSITE#>
        try {
            New-Item -Path "C:\" -Name "$Web_Name" -ItemType Directory
            Write-Host "DIRECTORY CREATED FOR WEBSITE"
        }
        catch {
            Write-Host "CANNOT CREATE A DIRECTORY FOR WEBSITE"
            Break;
        }
    } -Args $Website_Name
    <#COPYING FILES FOR WEBSITE#>
    try {
        Copy-Item -path "WebContent\netcoreapp3.1.zip" -Destination "C:\$Website_Name" -ToSession $Session 
        Write-Host "FILES COPIED FOR WEBSITE"
    }
    catch {
        Write-Host "CANNOT COPY FILES FOR WEBSITE"
        Break;
    }

    Invoke-Command -Session $Session -ScriptBlock {
        param($Web_Name,$Port)
        Set-ExecutionPolicy Unrestricted -Force
        Import-Module IISAdministration
        <#UNZIPPING CONTENTS FOR WEBSITEE#>
        Expand-Archive -Path "C:\$Web_Name\netcoreapp3.1.zip" -DestinationPath "C:\$Web_Name"
        <#HOSTING AND STARTING WEBSITEE#>
        try {
            New-IISSite -Name "$Web_Name" -PhysicalPath "C:\$Web_Name\netcoreapp3.1" -BindingInformation "*: $Port :"
            Start-IISSite -Name "$Web_Name"
            Write-Host "STARTED HOSTING WEBSITE"
        }
        catch {
            throw
        }
    } -Args $Website_Name, $Port_Number
}
Manage-Remote
