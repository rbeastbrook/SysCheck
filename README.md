# System Diagnostic PowerShell Script

This PowerShell script is designed to run a comprehensive system diagnostic on a Windows machine, logging important system information, network diagnostics, hardware statistics, and more to a log file for troubleshooting or monitoring purposes. It ensures that the script runs with administrator privileges and logs the following data:

- **Environment information**: PC name, username, IP configuration
- **Network diagnostics**: nslookup, ping, tracert
- **System information**: BIOS, system, and OS info
- **CPU and memory usage**
- **Disk usage**
- **System temperature**
- **Battery status** (if applicable)
- **Active Directory information** (if applicable)
- **Local user and group information**
- **Pending Windows updates**

## Features

- **Administrator Check**: The script first checks if it's running with Administrator privileges. If not, it will relaunch itself with elevated privileges.
- **Log File Creation**: A log file is generated with a unique name based on the PC name and the current timestamp. The log file is saved in the `C:\logs` directory (it will create the folder if it does not already exist).
- **Comprehensive Diagnostics**: Collects data on environment details, system status, CPU and memory usage, disk usage, battery status, and more.
- **Active Directory Integration**: If available, the script will fetch information from Active Directory.
- **Battery Info**: If the machine has a battery (e.g., laptop), the script will report the battery status, including the current charge and whether it is plugged in.

## Usage

### Run the Script:
1. Open PowerShell as **Administrator**.
2. Copy and paste the script into PowerShell or save it as a `.ps1` file and execute it.
Alternatively:
1. Run the file as normal, it will automatically ask to elevate privileges

### Log File:
- The log file will be created in the `C:\logs` directory with a timestamp and the PC name in the filename, e.g., `PCName-2024-11-26_15-30-00.log`.

### Script Output:
- The script will display live status updates in the PowerShell window as it runs, such as "Logging environment information..." or "Running network diagnostics...".
- After the diagnostic is complete, it will output the path to the log file where all the information has been saved.

## Script Breakdown

- **Test-Admin**: Checks whether the script is running with Administrator privileges.
- **Log-Status**: A helper function to log status messages to both the console and the log file.
- **Logging Environment Information**: Logs the PC name, username, and IP configuration.
- **Network Diagnostics**: Runs `nslookup`, `ping`, and `tracert` to test network connectivity.
- **System Information**: Collects BIOS, system, and OS information using `WMIC`.
- **CPU and Memory Usage**: Collects data on CPU usage, memory usage, and system uptime.
- **Disk Usage**: Logs the disk usage for each local drive.
- **Temperature Monitoring**: Checks the system temperature using `WMIC`.
- **Battery Status**: Logs battery information if available.
- **Active Directory Info**: Retrieves information from Active Directory if the required cmdlets are available.
- **Local User and Group Information**: Logs the list of local users and groups.
- **Pending Updates**: Logs the number of pending Windows updates.

## Requirements

- **PowerShell Version**: PowerShell 5.1 or higher is required.
- **Administrator Privileges**: The script must be run as an Administrator for some commands (like `WMIC` and `Get-WmiObject`) to work correctly.
- **Active Directory**: Active Directory cmdlets (`Get-ADComputer`) are required for fetching AD information. The script checks if the cmdlet is available before attempting to fetch AD data.

## Known Limitations

- **System Temperature**: The temperature information may not be available on all systems, especially desktops without thermal sensors exposed via WMI.
- **Active Directory Information**: The script will only fetch Active Directory data if the system is part of a domain and the necessary cmdlets are available.

## Example Output
`Status: Logging environment information... 
Status: Running network diagnostics... 
Status: Fetching system information using WMIC... 
Status: Collecting CPU and memory usage... 
Status: Collecting disk usage... 
Status: Checking system temperature... 
Status: Collecting battery status... 
Status: Fetching Active Directory information... 
Status: Collecting local user and group information... 
Status: Checking for pending updates...
Diagnostic completed. The log has been saved to: C:\logs\PCName-2024-11-26_15-30-00.log`

## Troubleshooting

- **Script not running as Administrator**: Ensure you have elevated privileges. Right-click PowerShell and choose "Run as Administrator".
- **Missing cmdlets for Active Directory**: Make sure you have the Active Directory module installed if you need that functionality.
