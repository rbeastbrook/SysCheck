# Check if the script is running with Administrator privileges
function Test-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# If the script is not running as administrator, relaunch it with elevated privileges
if (-not (Test-Admin)) {
    # Relaunch the script as administrator
    $arg = "-NoProfile -ExecutionPolicy Bypass -File ""$PSCommandPath"""
    Start-Process powershell -ArgumentList $arg -Verb runAs
    exit
}
# Define log file name based on PC name and current timestamp
$PCName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFolder = "C:\logs"
$logFile = "$logFolder\$PCName-$timestamp.log"

# Create the logs folder if it doesn't exist
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory
}

# Print status and log to file
function Log-Status($status) {
    Write-Host "Status: $status"
    Add-Content -Path $logFile -Value $status
}

# 1. Log Environment Information
Log-Status "Logging environment information..."
Add-Content -Path $logFile -Value "PC Name: $PCName"
Add-Content -Path $logFile -Value "Username: $env:USERNAME"
Add-Content -Path $logFile -Value "Date and Time: $(Get-Date)"
Add-Content -Path $logFile -Value "IP Configuration:"
ipconfig /all | Add-Content -Path $logFile

# 2. Run Network Diagnostics (nslookup, ping, tracert)
Log-Status "Running network diagnostics..."
Add-Content -Path $logFile -Value "NSLookup for ${PCName}:"
nslookup $PCName | Add-Content -Path $logFile

Add-Content -Path $logFile -Value "Ping test to ${PCName}:"
ping $PCName | Add-Content -Path $logFile

Add-Content -Path $logFile -Value "Traceroute to ${PCName}:"
tracert $PCName | Add-Content -Path $logFile

# 3. Fetch System Information using WMIC if CIM fails
Log-Status "Fetching system information using WMIC..."
try {
    Add-Content -Path $logFile -Value "BIOS Information:"
    wmic bios get /format:list | Add-Content -Path $logFile

    Add-Content -Path $logFile -Value "System Information:"
    wmic computersystem get /format:list | Add-Content -Path $logFile

    Add-Content -Path $logFile -Value "Operating System Information:"
    wmic os get /format:list | Add-Content -Path $logFile
} catch {
    Add-Content -Path $logFile -Value "Error fetching system information: $_"
}

# 4. Collect CPU and Memory Usage (Using Get-Process and Win32_OperatingSystem)
Log-Status "Collecting CPU and memory usage..."
try {
    $uptime = (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime
    $cpuUsage = (Get-WmiObject -Class Win32_Processor).LoadPercentage
    $memoryUsage = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory
    $memoryTotal = (Get-WmiObject -Class Win32_OperatingSystem).TotalVisibleMemorySize
    $memoryUsedPercentage = [math]::round(((($memoryTotal - $memoryUsage) / $memoryTotal) * 100), 2)
    Add-Content -Path $logFile -Value "System Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
    Add-Content -Path $logFile -Value "CPU Usage: $cpuUsage%"
    Add-Content -Path $logFile -Value "Memory Usage: $memoryUsedPercentage%"
} catch {
    Add-Content -Path $logFile -Value "Error fetching CPU/Memory usage: $_"
}

# 5. Collect Disk Usage
Log-Status "Collecting disk usage..."
$diskInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
foreach ($disk in $diskInfo) {
    $diskUsage = [math]::round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
    Add-Content -Path $logFile -Value "Disk Usage for $($disk.DeviceID): $diskUsage% (Total: $([math]::round($disk.Size / 1GB, 2)) GB, Free: $([math]::round($disk.FreeSpace / 1GB, 2)) GB)"
}

# 6. Check System Temperature (Using WMIC instead of Get-CimInstance)
Log-Status "Checking system temperature..."
try {
    $temperatureInfo = wmic /namespace:"\\root\wmi" path MSAcpi_ThermalZoneTemperature get CurrentTemperature
    if ($temperatureInfo) {
        $temperature = ($temperatureInfo -replace '\s+', '').Split('=')[-1]
        $temperature = [math]::round(($temperature / 10) - 273.15, 2)
        Add-Content -Path $logFile -Value "System Temperature: $temperature°C"
    } else {
        Add-Content -Path $logFile -Value "Temperature information not available."
    }
} catch {
    Add-Content -Path $logFile -Value "Error fetching temperature info: $_"
}

# 7. Collect Battery Status (if applicable)
Log-Status "Collecting battery status..."
try {
    $battery = Get-WmiObject -Class Win32_Battery
    if ($battery) {
        $batteryPercentage = $battery.EstimatedChargeRemaining
        $pluggedIn = if ($battery.PowerOnline) { "Yes" } else { "No" }
        Add-Content -Path $logFile -Value "Battery Percentage: $batteryPercentage%"
        Add-Content -Path $logFile -Value "Battery Plugged In: $pluggedIn"
    } else {
        Add-Content -Path $logFile -Value "No battery information available (likely a desktop)."
    }
} catch {
    Add-Content -Path $logFile -Value "Error fetching battery info: $_"
}

# 8. Get Active Directory Information (if applicable)
Log-Status "Fetching Active Directory information..."
try {
    # Check if the Active Directory cmdlet is available
    if (Get-Command -Name 'Get-ADComputer' -ErrorAction SilentlyContinue) {
        $adComputerInfo = Get-ADComputer $PCName -Properties Name, Description, LastLogonDate, DistinguishedName
        Add-Content -Path $logFile -Value "Active Directory Information:"
        Add-Content -Path $logFile -Value "Name: $($adComputerInfo.Name)"
        Add-Content -Path $logFile -Value "Description: $($adComputerInfo.Description)"
        Add-Content -Path $logFile -Value "Last Logon Date: $($adComputerInfo.LastLogonDate)"
        Add-Content -Path $logFile -Value "Distinguished Name: $($adComputerInfo.DistinguishedName)"
    } else {
        Add-Content -Path $logFile -Value "Active Directory module not found. Skipping AD information."
    }
} catch {
    Add-Content -Path $logFile -Value "Active Directory information not available: $_"
}


# 9. Collect Local User and Group Information
Log-Status "Collecting local user and group information..."
$users = net user
$groups = net localgroup

Add-Content -Path $logFile -Value "Local Users:"
Add-Content -Path $logFile -Value $users

Add-Content -Path $logFile -Value "Local Groups:"
Add-Content -Path $logFile -Value $groups

# 10. Pending Updates
Log-Status "Checking for pending Windows updates..."

$updateSession = New-Object -ComObject Microsoft.Update.Session
$updateSearcher = $updateSession.CreateUpdateSearcher()
$searchResult = $updateSearcher.Search("IsInstalled=0")

Add-Content -Path $logFile -Value "Pending Windows Updates: $($searchResult.Updates.Count)"

Write-Host "Diagnostic completed. The log has been saved to: $logFile"
Read-Host -Prompt "Press Enter to exit"
