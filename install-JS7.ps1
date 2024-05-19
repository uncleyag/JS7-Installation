# downloads the release tarball from the SOS Web Site using Invoke-WebRequest
# extracts the tarball to the Agent's home directory
# creates the Agent's Windows service
# stops and starts the Agent's Windows service
# operates the Agent for HTTP port 4445

# port number changed from 4445 to 4745 due to existing port number in the server

param (
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$HomeDir,

    [string]$Tarball,
    [string]$Data,
    [int]$HttpPort,
    [string]$MakeDirs,
    

    [switch]$InstallAgent,
    [switch]$RunAgent,
    [switch]$RunService
)



# Creating target directories if they do not exist
$directories = @(
    "C:\Program Files\sos-berlin.com\js7\agent3",
    "C:\ProgramData\sos-berlin.com\js7\agent3",
    "C:\tmp"
)

# Check if directories can be created, if not, abort the script
foreach ($dir in $directories) {
    if (-not (Test-Path $dir -PathType Container)) {
        try {
            New-Item -Path $dir -ItemType Directory -Force -ErrorAction Stop
        } catch {
            Write-Host "Failed to create directory $dir. Aborting script."
            exit 1
        }
    }
}

# Downloading the JS7 agent tarball
$Tarball = "C:\tmp\js7_agent_windows.2.5.2.zip"
Invoke-WebRequest `
    -Uri 'https://download.sos-berlin.com/JobScheduler.2.5/js7_agent_windows.2.5.2.zip' `
    -Outfile $Tarball


# Extract the tarball only if it's not already extracted
$ExtractionPath = Join-Path -Path $HomeDir -ChildPath "agent3"
if (-not (Test-Path $ExtractionPath)) {
    try {
        Expand-Archive -Path $Tarball -DestinationPath $ExtractionPath -Force
        Write-Host "Extraction successful."
    } catch {
        Write-Host "Extraction failed: $_"
        exit 1
    }
}

# Define installation parameters
$Data = "C:\ProgramData\sos-berlin.com\js7\agent_4485"
$HomeDir = "C:\Program Files\sos-berlin.com\js7"
$HttpPort = 4495
$MakeDirs = $true

# Install JS7 Agent command if specified
if ($InstallAgent) {
    $installResult = .\Install-JS7Agent.ps1 -HomeDir $HomeDir -Tarball $Tarball -Data $Data -HttpPort $HttpPort -MakeDirs $MakeDirs

    # Check if the installation was successful
    if ($installResult) {
        Write-Host "Installation successful."
    } else {
        Write-Host "Installation failed."
    }
}

# Run the agent if specified
if ($RunAgent) {
    $agentCmdPath = Join-Path -Path "C:\Program Files\sos-berlin.com\js7\agent\agent\bin" -ChildPath "agent.cmd"
    if (Test-Path $agentCmdPath) {
        Start-Process -FilePath $agentCmdPath -ArgumentList "start" -NoNewWindow
        Write-Host "Agent started successfully."
    } else {
        Write-Host "agent.cmd not found. Could not start the agent."
    }
}

# Run the service if specified
if ($RunService) {
    # Run the install_agent_windows_service.cmd script
    $serviceCmdPath = Join-Path -Path "C:\Program Files\sos-berlin.com\js7\agent\agent\service" -ChildPath "install_agent_windows_service.cmd"
    if (Test-Path $serviceCmdPath) {
        Start-Process -FilePath $serviceCmdPath -ArgumentList "$HttpPort" -NoNewWindow
        Write-Host "Service installed successfully."
    } else {
        Write-Host "install_agent_windows_service.cmd not found. Could not install the service."
    }

    # Wait for a few seconds before checking service status
    Start-Sleep -Seconds 60

    # Check if the JS7 Agent service is running
    if (Get-Service -Name "js7_agent" -ErrorAction SilentlyContinue) {
        Write-Host "JS7 Agent service is running."
    } else {
        Write-Host "JS7 Agent service is not running."
    }
}
exit 0

# To run the script
.\install-JS7agent.ps1 -InstallAgent -RunAgent -RunService -HomeDir "C:\Program Files\sos-berlin.com\js7"

