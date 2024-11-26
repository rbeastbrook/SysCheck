import os
import platform
import subprocess
import datetime
import psutil
import logging
from pathlib import Path

# Function to ensure the logs folder exists
def ensure_logs_folder():
    logs_folder = Path("C:/logs/")
    if not logs_folder.exists():
        logs_folder.mkdir(parents=True, exist_ok=True)

# Function to print status updates
def print_status(percentage, message):
    print(f"Status {percentage}%: {message}")

# Get the computer name
PCName = platform.node()

# Get the current date and time to format for the log file name
current_time = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

# Construct the log file name as "PC-NAMEdateandtime.log"
log_file = Path(f"C:/logs/{PCName}-{current_time}.log")

# Ensure the logs folder exists
ensure_logs_folder()

# Setup logging to file
logging.basicConfig(filename=log_file, level=logging.INFO, format='%(asctime)s - %(message)s')

# Start logging
print_status(10, "Logging Environment Information...")
logging.info(f"Logged Environment Information for {PCName}")
logging.info(f"Current Date and Time: {datetime.datetime.now()}")
logging.info(f"Username: {os.getenv('USERNAME')}")
logging.info(f"Computer Name: {PCName}")

# Collect Local System Information (BIOS, OS, System)
print_status(20, "Collecting local system information...")
bios_info = subprocess.run("wmic bios get /format:list", capture_output=True, text=True, shell=True)
logging.info(f"BIOS Information:\n{bios_info.stdout}")

system_info = subprocess.run("wmic computersystem get /format:list", capture_output=True, text=True, shell=True)
logging.info(f"System Information:\n{system_info.stdout}")

os_info = subprocess.run("wmic os get /format:list", capture_output=True, text=True, shell=True)
logging.info(f"Operating System Information:\n{os_info.stdout}")
print_status(30, "Local system information collected.")

# Run Network Diagnostics (nslookup, ping, tracert)
print_status(40, "Running network diagnostics...")
try:
    # nslookup equivalent
    nslookup_result = subprocess.run(f"nslookup {PCName}", capture_output=True, text=True, shell=True)
    logging.info(f"NSLookup for {PCName}:\n{nslookup_result.stdout}")
    
    # ping equivalent
    ping_result = subprocess.run(f"ping {PCName}", capture_output=True, text=True, shell=True)
    logging.info(f"Ping to {PCName}:\n{ping_result.stdout}")
    
    # tracert equivalent
    tracert_result = subprocess.run(f"tracert {PCName}", capture_output=True, text=True, shell=True)
    logging.info(f"Tracert to {PCName}:\n{tracert_result.stdout}")
except Exception as e:
    logging.error(f"Error during network investigation: {str(e)}")
print_status(50, "Network diagnostics complete.")

# Collect CPU and Memory Usage (psutil)
print_status(60, "Collecting CPU and memory usage...")
cpu_usage = psutil.cpu_percent(interval=1)  # Get CPU usage over 1 second
memory_usage = psutil.virtual_memory().percent  # Memory usage as a percentage
logging.info(f"CPU Usage: {cpu_usage}%")
logging.info(f"Memory Usage: {memory_usage}%")
print_status(65, "CPU and Memory usage collected.")

# Collect Disk Usage (psutil)
print_status(70, "Collecting disk usage...")
disk_usage = psutil.disk_usage('/')
logging.info(f"Disk Usage: {disk_usage.percent}% free on {disk_usage.total / (1024 ** 3):.2f} GB total")
print_status(75, "Disk usage collected.")

# Fetch Active Directory Information (using PowerShell cmdlet `Get-ADComputer`)
print_status(80, "Fetching Active Directory information...")
try:
    # Using PowerShell to fetch AD information (requires the Active Directory module)
    ad_info = subprocess.run(f"powershell Get-ADComputer {PCName} | Select-Object Name, ParentContainer, Description, LastLogonDate", capture_output=True, text=True, shell=True)
    logging.info(f"Active Directory Information for {PCName}:\n{ad_info.stdout}")
except Exception as e:
    logging.error(f"Error fetching Active Directory info: {str(e)}")
print_status(85, "Active Directory info fetched.")

# Collect System Health Checks (Temperature, Battery)
print_status(90, "Collecting system health checks...")
try:
    # Check if sensors_temperatures() method exists before using it
    if hasattr(psutil, 'sensors_temperatures'):
        temperatures = psutil.sensors_temperatures()
        if 'coretemp' in temperatures:
            logging.info(f"CPU Temperature: {temperatures['coretemp'][0].current}°C")
    else:
        logging.info("Temperature information is not available on this system.")
except Exception as e:
    logging.error(f"Error fetching temperature info: {str(e)}")

# Check battery health (for laptops)
if psutil.sensors_battery():
    battery = psutil.sensors_battery()
    logging.info(f"Battery Percentage: {battery.percent}%")
    logging.info(f"Battery Plugged In: {'Yes' if battery.power_plugged else 'No'}")

# Collect Local User and Group Information
print_status(100, "Collecting local user and group information...")
users = subprocess.run("net user", capture_output=True, text=True, shell=True)
logging.info(f"Local Users:\n{users.stdout}")

groups = subprocess.run("net localgroup", capture_output=True, text=True, shell=True)
logging.info(f"Local Groups:\n{groups.stdout}")

# Final message indicating script completion and log file location
print(f"Log file has been saved to: {log_file}")
