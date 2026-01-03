<#
================================================================================
    NAPELLAM BANK - WS02 WORKSTATION SETUP SCRIPT
================================================================================

PURPOSE:
    This script configures WS02 workstation and joins it to napellam.local domain.
    It works in TWO PHASES (like DC01 script):
    
    Phase 1: Network config + Domain join → Restarts
    Phase 2: Add local admin → Complete

USAGE:
    1. Run this script on fresh Windows 10 Pro as Administrator
    2. After restart, run it AGAIN as Administrator
    3. Done!

AUTHOR: Built for Napellam Bank AD Pentesting Lab
DATE: January 2026
================================================================================
#>

# Check for Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  NAPELLAM BANK - WS02 WORKSTATION SETUP" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

#================================================================================
# PHASE DETECTION
#================================================================================

Write-Host "[*] Detecting current setup phase..." -ForegroundColor Yellow

# Check if already domain-joined
$CurrentDomain = (Get-WmiObject Win32_ComputerSystem).Domain
$IsDomainJoined = ($CurrentDomain -eq "napellam.local")

# Check if ravi.teja is already local admin
$IsLocalAdminConfigured = $false
if ($IsDomainJoined) {
    try {
        $LocalAdmins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
        $IsLocalAdminConfigured = ($LocalAdmins.Name -contains "NAPELLAM\ravi.teja")
    } catch {
        # Fallback check
        $output = net localgroup Administrators 2>$null
        $IsLocalAdminConfigured = ($output -match "ravi.teja")
    }
}

Write-Host ""

#================================================================================
# PHASE 1: NETWORK CONFIGURATION + DOMAIN JOIN
#================================================================================

if (-not $IsDomainJoined) {
    Write-Host ">>> PHASE 1: NETWORK SETUP + DOMAIN JOIN <<<" -ForegroundColor Green
    Write-Host ""
    
    # Configure Network
    Write-Host "[*] Configuring network settings..." -ForegroundColor Yellow
    
    $Adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    
    if ($Adapter) {
        Write-Host "    [+] Found network adapter: $($Adapter.Name)" -ForegroundColor Gray
        
        Remove-NetIPAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $Adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        
        New-NetIPAddress -InterfaceAlias $Adapter.Name `
                        -IPAddress "192.168.100.30" `
                        -PrefixLength 24 `
                        -DefaultGateway "192.168.100.10" `
                        -AddressFamily IPv4 | Out-Null
        
        Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name `
                                   -ServerAddresses "192.168.100.10"
        
        Write-Host "    [+] IP address set to: 192.168.100.30" -ForegroundColor Green
        Write-Host "    [+] DNS server: 192.168.100.10 (DC01)" -ForegroundColor Green
    } else {
        Write-Host "    [!] No active network adapter found!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    
    # Test connectivity
    Write-Host "[*] Testing connectivity to Domain Controller..." -ForegroundColor Yellow
    $PingResult = Test-Connection -ComputerName "192.168.100.10" -Count 2 -Quiet
    
    if ($PingResult) {
        Write-Host "    [+] Successfully connected to DC01" -ForegroundColor Green
    } else {
        Write-Host "    [!] Cannot reach DC01!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    
    # Rename Computer
    $CurrentName = $env:COMPUTERNAME
    Write-Host "[*] Checking computer name..." -ForegroundColor Yellow
    Write-Host "    Current name: $CurrentName" -ForegroundColor Gray
    
    if ($CurrentName -ne "WS02") {
        Write-Host "    [+] Renaming computer to WS02..." -ForegroundColor Yellow
        Rename-Computer -NewName "WS02" -Force | Out-Null
        Write-Host "    [+] Computer will be renamed to WS02" -ForegroundColor Green
    } else {
        Write-Host "    [+] Computer is already named WS02" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # Join Domain
    Write-Host "[*] Joining domain napellam.local..." -ForegroundColor Yellow
    Write-Host ""
    
    $DomainUser = "napellam\Administrator"
    $DomainPassword = ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($DomainUser, $DomainPassword)
    
    try {
        Add-Computer -DomainName "napellam.local" `
                     -Credential $Credential `
                     -Force `
                     -ErrorAction Stop
        
        Write-Host "    [+] Successfully joined napellam.local domain!" -ForegroundColor Green
        Write-Host ""
        
        # Enable Remote Management
        Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
        Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True -Profile Any -ErrorAction SilentlyContinue
        
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "  PHASE 1 COMPLETE" -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "WHAT HAPPENED:" -ForegroundColor Yellow
        Write-Host "  1. Network configured: 192.168.100.30" -ForegroundColor White
        Write-Host "  2. Computer renamed to: WS02" -ForegroundColor White
        Write-Host "  3. Joined domain: napellam.local" -ForegroundColor White
        Write-Host "  4. Remote management enabled" -ForegroundColor White
        Write-Host ""
        Write-Host "NEXT STEP:" -ForegroundColor Yellow
        Write-Host "  The computer will now RESTART." -ForegroundColor White
        Write-Host "  After restart, run this script AGAIN to complete setup." -ForegroundColor White
        Write-Host ""
        Write-Host "Restarting in 10 seconds..." -ForegroundColor Yellow
        
        Start-Sleep -Seconds 10
        Restart-Computer -Force
        
    } catch {
        Write-Host "    [!] Failed to join domain!" -ForegroundColor Red
        Write-Host "    [!] Error: $_" -ForegroundColor Red
        exit 1
    }
}

#================================================================================
# PHASE 2: ADD LOCAL ADMINISTRATOR
#================================================================================

if ($IsDomainJoined -and -not $IsLocalAdminConfigured) {
    Write-Host ">>> PHASE 2: POST-DOMAIN JOIN CONFIGURATION <<<" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[*] Adding ravi.teja to local Administrators group..." -ForegroundColor Yellow
    
    try {
        Add-LocalGroupMember -Group "Administrators" -Member "napellam\ravi.teja" -ErrorAction Stop
        Write-Host "    [+] ravi.teja added to local Administrators" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*already a member*") {
            Write-Host "    [+] ravi.teja is already a local Administrator" -ForegroundColor Green
        } else {
            net localgroup Administrators napellam\ravi.teja /add 2>$null
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 2) {
                Write-Host "    [+] ravi.teja added to local Administrators" -ForegroundColor Green
            } else {
                Write-Host "    [!] Failed to add local admin" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  WS02 SETUP COMPLETE!" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "FINAL CONFIGURATION:" -ForegroundColor Yellow
    Write-Host "  Computer:      WS02.napellam.local" -ForegroundColor White
    Write-Host "  IP Address:    192.168.100.30" -ForegroundColor White
    Write-Host "  Domain:        napellam.local" -ForegroundColor White
    Write-Host "  Local Admin:   ravi.teja (IT Admin)" -ForegroundColor White
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Log out of current session" -ForegroundColor White
    Write-Host "  2. Login as: napellam\ravi.teja" -ForegroundColor White
    Write-Host "  3. Password: football" -ForegroundColor White
    Write-Host "  4. This caches credentials in memory!" -ForegroundColor White
    Write-Host ""
    Write-Host "WS02 is ready for pentesting!" -ForegroundColor Green
    Write-Host ""
}

#================================================================================
# ALREADY CONFIGURED
#================================================================================

if ($IsDomainJoined -and $IsLocalAdminConfigured) {
    Write-Host ">>> WS02 ALREADY CONFIGURED <<<" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This workstation is already set up:" -ForegroundColor White
    Write-Host "  - Domain joined: napellam.local" -ForegroundColor White
    Write-Host "  - Local admin: ravi.teja" -ForegroundColor White
    Write-Host ""
    Write-Host "You can login as: napellam\ravi.teja (password: football)" -ForegroundColor Green
    Write-Host ""
}
