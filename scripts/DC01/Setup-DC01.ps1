<#
================================================================================
    NAPELLAM BANK - DC01 DOMAIN CONTROLLER SETUP SCRIPT
================================================================================

PURPOSE:
    This script sets up DC01 as the Domain Controller for napellam.local domain.
    It is designed to run MULTIPLE TIMES (2-3 times) because Windows requires
    restarts after major changes like installing AD DS role and promoting to DC.

HOW IT WORKS:
    The script detects which phase it's in by checking:
    - Is AD DS role installed?
    - Is this already a Domain Controller?
    - Do the OUs and users already exist?
    
    Based on what's already done, it continues from the next step.

PHASES:
    Phase 1: Network configuration, rename computer, install AD DS role
    Phase 2: Promote to Domain Controller (creates napellam.local domain)
    Phase 3: Create OUs, users, groups, and configure all vulnerabilities

USAGE:
    1. Run this script on a fresh Windows Server 2022 machine
    2. After it restarts, run it again
    3. After it restarts again, run it one more time
    4. Lab will be ready!

AUTHOR: Built for Napellam Bank AD Pentesting Lab
DATE: January 2026
================================================================================
#>

# Ensure script runs with Administrator privileges
# This checks if we are running as admin. If not, script will fail.
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  NAPELLAM BANK - DC01 SETUP SCRIPT" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

#================================================================================
# PHASE DETECTION
#================================================================================
# We need to figure out which phase we're in by checking what's already done

Write-Host "[*] Detecting current setup phase..." -ForegroundColor Yellow

# Check 1: Is AD DS role installed?
# The role name is "AD-Domain-Services". We check using Get-WindowsFeature
$ADDSInstalled = (Get-WindowsFeature -Name AD-Domain-Services).Installed

# Check 2: Is this machine a Domain Controller?
# We check this by trying to get the domain information
# If this is not a DC, this will return $null
$IsDomainController = $null
try {
    $IsDomainController = Get-ADDomain -ErrorAction SilentlyContinue
} catch {
    # This is fine - just means we're not a DC yet
}

# Check 3: Do our custom OUs exist?
# We check if "OU=Bank-Users" exists in the domain
$OUsExist = $false
if ($IsDomainController) {
    try {
        $OUsExist = [bool](Get-ADOrganizationalUnit -Filter 'Name -eq "Bank-Users"' -ErrorAction SilentlyContinue)
    } catch {
        # OUs don't exist yet
    }
}

Write-Host ""

#================================================================================
# PHASE 1: NETWORK CONFIGURATION + AD DS ROLE INSTALLATION
#================================================================================
# This phase runs on a fresh Windows Server installation

if (-not $ADDSInstalled) {
    Write-Host ">>> PHASE 1: NETWORK SETUP + AD DS INSTALLATION <<<" -ForegroundColor Green
    Write-Host ""
    
    # Step 1.1: Configure Static IP Address
    # ====================================
    # We need to give this server a static IP address: 192.168.100.10
    # Windows uses network adapters. We need to find the active adapter and configure it.
    
    Write-Host "[*] Configuring network settings..." -ForegroundColor Yellow
    
    # Get the network adapter (usually called "Ethernet" or "Ethernet0")
    # We get the one that is "Up" (connected)
    $Adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    
    if ($Adapter) {
        # Get current IP configuration to see what we have
        $CurrentIP = (Get-NetIPAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
        
        Write-Host "    [+] Found network adapter: $($Adapter.Name)" -ForegroundColor Gray
        Write-Host "    [+] Current IP: $CurrentIP" -ForegroundColor Gray
        
        # Remove any existing IP configuration
        # This ensures we start fresh without conflicts
        Remove-NetIPAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $Adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        
        # Set new static IP: 192.168.100.10
        # Subnet mask: 255.255.255.0 which is /24 in CIDR notation
        New-NetIPAddress -InterfaceAlias $Adapter.Name `
                        -IPAddress "192.168.100.10" `
                        -PrefixLength 24 `
                        -AddressFamily IPv4 | Out-Null
        
        # Set DNS to 127.0.0.1 (localhost)
        # This is important! As a DC, this server will run its own DNS service.
        # So it should point to itself for DNS queries.
        Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name `
                                   -ServerAddresses "127.0.0.1"
        
        Write-Host "    [+] IP address set to: 192.168.100.10" -ForegroundColor Green
        Write-Host "    [+] Subnet mask: 255.255.255.0 (/24)" -ForegroundColor Green
        Write-Host "    [+] DNS server: 127.0.0.1 (localhost)" -ForegroundColor Green
    } else {
        Write-Host "    [!] No active network adapter found!" -ForegroundColor Red
        Write-Host "    [!] Please check your network adapter and try again" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    
    # Step 1.2: Rename Computer to DC01
    # ==================================
    # The computer needs to be named DC01 before we promote it to Domain Controller
    
    $CurrentName = $env:COMPUTERNAME
    Write-Host "[*] Renaming computer..." -ForegroundColor Yellow
    Write-Host "    [+] Current name: $CurrentName" -ForegroundColor Gray
    
    if ($CurrentName -ne "DC01") {
        # Rename the computer to DC01
        # This requires a restart, so we'll handle that later
        Rename-Computer -NewName "DC01" -Force | Out-Null
        Write-Host "    [+] Computer will be renamed to: DC01" -ForegroundColor Green
        $RequireRestart = $true
    } else {
        Write-Host "    [+] Computer is already named DC01" -ForegroundColor Green
        $RequireRestart = $false
    }
    
    Write-Host ""
    
    # Step 1.3: Install Active Directory Domain Services Role
    # ========================================================
    # AD DS (Active Directory Domain Services) is the role that makes this a DC
    # We install the role and all its management tools
    
    Write-Host "[*] Installing Active Directory Domain Services role..." -ForegroundColor Yellow
    Write-Host "    This may take 5-10 minutes. Please wait..." -ForegroundColor Gray
    Write-Host ""
    
    # Install-WindowsFeature does the actual installation
    # -Name: The feature name
    # -IncludeManagementTools: Also install RSAT tools for managing AD
    $InstallResult = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    
    if ($InstallResult.Success) {
        Write-Host "    [+] AD DS role installed successfully!" -ForegroundColor Green
        Write-Host "    [+] Management tools installed" -ForegroundColor Green
    } else {
        Write-Host "    [!] Failed to install AD DS role!" -ForegroundColor Red
        Write-Host "    [!] Error: $($InstallResult.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  PHASE 1 COMPLETE" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "WHAT HAPPENED:" -ForegroundColor Yellow
    Write-Host "  1. Static IP configured: 192.168.100.10/24" -ForegroundColor White
    Write-Host "  2. DNS set to: 127.0.0.1" -ForegroundColor White
    Write-Host "  3. Computer renamed to: DC01" -ForegroundColor White
    Write-Host "  4. AD DS role installed" -ForegroundColor White
    Write-Host ""
    Write-Host "NEXT STEP:" -ForegroundColor Yellow
    Write-Host "  The computer will now RESTART." -ForegroundColor White
    Write-Host "  After restart, run this script AGAIN to continue Phase 2." -ForegroundColor White
    Write-Host ""
    Write-Host "Restarting in 10 seconds..." -ForegroundColor Yellow
    
    Start-Sleep -Seconds 10
    Restart-Computer -Force
    exit 0
}

#================================================================================
# PHASE 2: PROMOTE TO DOMAIN CONTROLLER
#================================================================================
# At this point, AD DS role is installed but we're not yet a DC

if ($ADDSInstalled -and -not $IsDomainController) {
    Write-Host ">>> PHASE 2: DOMAIN CONTROLLER PROMOTION <<<" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[*] Promoting this server to Domain Controller..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "DOMAIN CONFIGURATION:" -ForegroundColor Cyan
    Write-Host "  Domain Name:       napellam.local" -ForegroundColor White
    Write-Host "  NetBIOS Name:      NAPELLAM" -ForegroundColor White
    Write-Host "  Forest:            napellam.local (new forest)" -ForegroundColor White
    Write-Host "  Functional Level:  Windows Server 2016" -ForegroundColor White
    Write-Host ""
    Write-Host "This will take 10-15 minutes. Please wait..." -ForegroundColor Gray
    Write-Host ""
    
    # Set the Directory Services Restore Mode (DSRM) password
    # This is a special password used to recover the DC if AD fails
    # We use the same password as the built-in Administrator for this lab
    $DSRMPassword = ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force
    
    # Install-ADDSForest creates a NEW Active Directory forest
    # This is used when you're creating the FIRST DC in a new domain
    #
    # Parameters explained:
    # -DomainName: The fully qualified domain name (FQDN) of the domain
    # -DomainNetbiosName: The short name (used in older Windows systems)
    # -ForestMode: The forest functional level (Win2016 gives us modern features)
    # -DomainMode: The domain functional level
    # -InstallDns: Also install DNS server (required for AD to work)
    # -SafeModeAdministratorPassword: The DSRM password
    # -Force: Don't ask for confirmation
    # -NoRebootOnCompletion: We'll handle the restart ourselves
    
    try {
        Install-ADDSForest `
            -DomainName "napellam.local" `
            -DomainNetbiosName "NAPELLAM" `
            -ForestMode "Win2016" `
            -DomainMode "Win2016" `
            -InstallDns:$true `
            -SafeModeAdministratorPassword $DSRMPassword `
            -Force:$true `
            -NoRebootOnCompletion:$false
        
        # NOTE: The server will restart automatically after this command
        # We won't reach this line, but if we do, it means something went wrong
        
    } catch {
        Write-Host "[!] Failed to promote to Domain Controller!" -ForegroundColor Red
        Write-Host "[!] Error: $_" -ForegroundColor Red
        exit 1
    }
    
    # This code won't execute because the server restarts automatically
    # But we keep it here for documentation
    exit 0
}

#================================================================================
# PHASE 3: CREATE OUs, USERS, GROUPS, AND CONFIGURE VULNERABILITIES
#================================================================================
# At this point, we are a Domain Controller but haven't created our lab setup yet

if ($IsDomainController -and -not $OUsExist) {
    Write-Host ">>> PHASE 3: CREATING LAB ENVIRONMENT <<<" -ForegroundColor Green
    Write-Host ""
    
    # Import the Active Directory module
    # This gives us all the AD commandlets like New-ADUser, New-ADOrganizationalUnit, etc.
    Import-Module ActiveDirectory
    
    # Get the domain DN (Distinguished Name)
    # For napellam.local, this will be: DC=napellam,DC=local
    $DomainDN = (Get-ADDomain).DistinguishedName
    Write-Host "[*] Working with domain: $DomainDN" -ForegroundColor Yellow
    Write-Host ""
    
    #============================================================================
    # STEP 3.1: CREATE ORGANIZATIONAL UNITS (OUs)
    #============================================================================
    # OUs are containers that hold users, groups, and computers
    # We organize our lab into logical groups using OUs
    
    Write-Host "[*] Creating Organizational Units..." -ForegroundColor Yellow
    
    # Create the top-level OU for all bank users
    # Path will be: OU=Bank-Users,DC=napellam,DC=local
    New-ADOrganizationalUnit -Name "Bank-Users" -Path $DomainDN -ProtectedFromAccidentalDeletion $false
    Write-Host "    [+] Created OU: Bank-Users" -ForegroundColor Green
    
    # Create IT Department OU
    # Path: OU=IT-Department,OU=Bank-Users,DC=napellam,DC=local
    $BankUsersOU = "OU=Bank-Users,$DomainDN"
    New-ADOrganizationalUnit -Name "IT-Department" -Path $BankUsersOU -ProtectedFromAccidentalDeletion $false
    Write-Host "    [+] Created OU: IT-Department" -ForegroundColor Green
    
    # Create Management OU
    New-ADOrganizationalUnit -Name "Management" -Path $BankUsersOU -ProtectedFromAccidentalDeletion $false
    Write-Host "    [+] Created OU: Management" -ForegroundColor Green
    
    # Create Operations OU
    New-ADOrganizationalUnit -Name "Operations" -Path $BankUsersOU -ProtectedFromAccidentalDeletion $false
    Write-Host "    [+] Created OU: Operations" -ForegroundColor Green
    
    # Create Service Accounts OU
    # This holds service accounts like svc_backup
    New-ADOrganizationalUnit -Name "Service-Accounts" -Path $DomainDN -ProtectedFromAccidentalDeletion $false
    Write-Host "    [+] Created OU: Service-Accounts" -ForegroundColor Green
    
    # Create Workstations OU
    # This will hold computer accounts for WS01 and WS02
    New-ADOrganizationalUnit -Name "Workstations" -Path $DomainDN -ProtectedFromAccidentalDeletion $false
    Write-Host "    [+] Created OU: Workstations" -ForegroundColor Green
    
    # Create Servers OU
    New-ADOrganizationalUnit -Name "Servers" -Path $DomainDN -ProtectedFromAccidentalDeletion $false
    Write-Host "    [+] Created OU: Servers" -ForegroundColor Green
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.2: CREATE SECURITY GROUPS
    #============================================================================
    # Security groups are used to assign permissions to multiple users at once
    
    Write-Host "[*] Creating Security Groups..." -ForegroundColor Yellow
    
    # IT-Managers group
    # This group will have special permissions (GenericAll on lakshmi.devi)
    New-ADGroup -Name "IT-Managers" `
                -GroupScope Global `
                -GroupCategory Security `
                -Path "OU=IT-Department,$BankUsersOU" `
                -Description "IT Management Team"
    Write-Host "    [+] Created Group: IT-Managers" -ForegroundColor Green
    
    # IT-Admins group
    New-ADGroup -Name "IT-Admins" `
                -GroupScope Global `
                -GroupCategory Security `
                -Path "OU=IT-Department,$BankUsersOU" `
                -Description "IT Administrators"
    Write-Host "    [+] Created Group: IT-Admins" -ForegroundColor Green
    
    # Bank-Managers group
    New-ADGroup -Name "Bank-Managers" `
                -GroupScope Global `
                -GroupCategory Security `
                -Path "OU=Management,$BankUsersOU" `
                -Description "Bank Management"
    Write-Host "    [+] Created Group: Bank-Managers" -ForegroundColor Green
    
    # Backup-Operators group
    # svc_backup will be a member of this
    New-ADGroup -Name "Backup-Operators" `
                -GroupScope Global `
                -GroupCategory Security `
                -Path "OU=Service-Accounts,$DomainDN" `
                -Description "Backup Service Operators"
    Write-Host "    [+] Created Group: Backup-Operators" -ForegroundColor Green
    
    # Operations-Staff group
    New-ADGroup -Name "Operations-Staff" `
                -GroupScope Global `
                -GroupCategory Security `
                -Path "OU=Operations,$BankUsersOU" `
                -Description "Operations Department Staff"
    Write-Host "    [+] Created Group: Operations-Staff" -ForegroundColor Green
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.3: CREATE USER ACCOUNTS
    #============================================================================
    Write-Host "[*] Creating User Accounts..." -ForegroundColor Yellow
    Write-Host ""
    
    # For each user, we need to set:
    # - sAMAccountName: The logon name (e.g., vamsi.krishna)
    # - UserPrincipalName: The full email-style name (vamsi.krishna@napellam.local)
    # - Password: As a SecureString
    # - Path: Which OU the user belongs to
    # - Enabled: $true (account is active)
    
    # We'll create all users with their specific passwords from the specification
    
    Write-Host "    Creating IT Department Users..." -ForegroundColor Cyan
    
    # User: ammulu.orsu (IT Manager - DOMAIN ADMIN)
    $Password = ConvertTo-SecureString "princess" -AsPlainText -Force
    New-ADUser -Name "Ammulu Orsu" `
               -SamAccountName "ammulu.orsu" `
               -UserPrincipalName "ammulu.orsu@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=IT-Department,$BankUsersOU" `
               -Title "IT Manager" `
               -Department "IT" `
               -Description "IT Manager - Vulnerable DA account" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: ammulu.orsu (Password: princess)" -ForegroundColor Green
    
    # User: lakshmi.devi (System Administrator - ACL TARGET)
    $Password = ConvertTo-SecureString "sunshine" -AsPlainText -Force
    New-ADUser -Name "Lakshmi Devi" `
               -SamAccountName "lakshmi.devi" `
               -UserPrincipalName "lakshmi.devi@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=IT-Department,$BankUsersOU" `
               -Title "System Administrator" `
               -Department "IT" `
               -Description "System Administrator - ACL abuse target" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: lakshmi.devi (Password: sunshine)" -ForegroundColor Green
    
    # User: ravi.teja (Network Administrator)
    $Password = ConvertTo-SecureString "football" -AsPlainText -Force
    New-ADUser -Name "Ravi Teja" `
               -SamAccountName "ravi.teja" `
               -UserPrincipalName "ravi.teja@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=IT-Department,$BankUsersOU" `
               -Title "Network Administrator" `
               -Department "IT" `
               -Description "Network Administrator - Local admin on WS02" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: ravi.teja (Password: football)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "    Creating Management Users..." -ForegroundColor Cyan
    
    # User: vamsi.krishna (Bank Manager - INITIAL ACCESS)
    $Password = ConvertTo-SecureString "iloveyou" -AsPlainText -Force
    New-ADUser -Name "Vamsi Krishna" `
               -SamAccountName "vamsi.krishna" `
               -UserPrincipalName "vamsi.krishna@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=Management,$BankUsersOU" `
               -Title "Bank Manager" `
               -Department "Management" `
               -Description "Bank Manager - Initial access target" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: vamsi.krishna (Password: iloveyou)" -ForegroundColor Green
    
    # User: pranavi (Branch Manager - AS-REP ROASTABLE)
    $Password = ConvertTo-SecureString "butterfly" -AsPlainText -Force
    New-ADUser -Name "Pranavi" `
               -SamAccountName "pranavi" `
               -UserPrincipalName "pranavi@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=Management,$BankUsersOU" `
               -Title "Branch Manager" `
               -Department "Management" `
               -Description "Branch Manager - AS-REP Roastable" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: pranavi (Password: butterfly)" -ForegroundColor Green
    
    # User: madhavi (Operations Manager)
    $Password = ConvertTo-SecureString "letmein" -AsPlainText -Force
    New-ADUser -Name "Madhavi" `
               -SamAccountName "madhavi" `
               -UserPrincipalName "madhavi@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=Management,$BankUsersOU" `
               -Title "Operations Manager" `
               -Department "Management" `
               -Description "Operations Manager" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: madhavi (Password: letmein)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "    Creating Operations Users..." -ForegroundColor Cyan
    
    # User: divya (Loan Officer)
    $Password = ConvertTo-SecureString "chocolate" -AsPlainText -Force
    New-ADUser -Name "Divya" `
               -SamAccountName "divya" `
               -UserPrincipalName "divya@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=Operations,$BankUsersOU" `
               -Title "Loan Officer" `
               -Department "Operations" `
               -Description "Loan Officer" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: divya (Password: chocolate)" -ForegroundColor Green
    
    # User: harsha.vardhan (Customer Service)
    $Password = ConvertTo-SecureString "passw0rd" -AsPlainText -Force
    New-ADUser -Name "Harsha Vardhan" `
               -SamAccountName "harsha.vardhan" `
               -UserPrincipalName "harsha.vardhan@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=Operations,$BankUsersOU" `
               -Title "Customer Service" `
               -Department "Operations" `
               -Description "Customer Service Representative" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: harsha.vardhan (Password: passw0rd)" -ForegroundColor Green
    
    # User: kiran.kumar (Analyst)
    $Password = ConvertTo-SecureString "trustno1" -AsPlainText -Force
    New-ADUser -Name "Kiran Kumar" `
               -SamAccountName "kiran.kumar" `
               -UserPrincipalName "kiran.kumar@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=Operations,$BankUsersOU" `
               -Title "Analyst" `
               -Department "Operations" `
               -Description "Business Analyst" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: kiran.kumar (Password: trustno1)" -ForegroundColor Green
    
    # User: sai.kiran (Compliance Officer)
    $Password = ConvertTo-SecureString "dragon" -AsPlainText -Force
    New-ADUser -Name "Sai Kiran" `
               -SamAccountName "sai.kiran" `
               -UserPrincipalName "sai.kiran@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=Operations,$BankUsersOU" `
               -Title "Compliance Officer" `
               -Department "Operations" `
               -Description "Compliance Officer" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: sai.kiran (Password: dragon)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "    Creating Service Accounts..." -ForegroundColor Cyan
    
    # User: svc_backup (CRITICAL - KERBEROASTABLE + DCSYNC)
    $Password = ConvertTo-SecureString "backup123" -AsPlainText -Force
    New-ADUser -Name "Backup Service Account" `
               -SamAccountName "svc_backup" `
               -UserPrincipalName "svc_backup@napellam.local" `
               -AccountPassword $Password `
               -Path "OU=Service-Accounts,$DomainDN" `
               -Title "Backup Service" `
               -Department "IT" `
               -Description "Backup Service Account - Kerberoastable + DCSync" `
               -Enabled $true `
               -PasswordNeverExpires $true `
               -ChangePasswordAtLogon $false
    Write-Host "      [+] Created: svc_backup (Password: backup123)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "[*] Setting the built-in Administrator password..." -ForegroundColor Yellow
    
    # Set Administrator password
    # The built-in Administrator account already exists, we just change its password
    $AdminPassword = ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force
    Set-ADAccountPassword -Identity "Administrator" -NewPassword $AdminPassword -Reset
    Set-ADUser -Identity "Administrator" -PasswordNeverExpires $true -Enabled $true
    Write-Host "    [+] Administrator password set to: P@ssw0rd!" -ForegroundColor Green
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.4: ADD USERS TO GROUPS
    #============================================================================
    # Now that users and groups are created, we assign group memberships
    # This defines what permissions each user has
    
    Write-Host "[*] Adding users to security groups..." -ForegroundColor Yellow
    
    # Add ammulu.orsu to Domain Admins (CRITICAL VULNERABILITY)
    # Domain Admins have complete control over the entire domain
    # This simulates a real-world mistake where IT managers use DA accounts daily
    Add-ADGroupMember -Identity "Domain Admins" -Members "ammulu.orsu"
    Write-Host "    [+] ammulu.orsu added to Domain Admins" -ForegroundColor Green
    
    # Add ammulu.orsu to IT-Managers
    Add-ADGroupMember -Identity "IT-Managers" -Members "ammulu.orsu"
    Write-Host "    [+] ammulu.orsu added to IT-Managers" -ForegroundColor Green
    
    # Add ammulu.orsu to IT-Admins
    Add-ADGroupMember -Identity "IT-Admins" -Members "ammulu.orsu"
    Write-Host "    [+] ammulu.orsu added to IT-Admins" -ForegroundColor Green
    
    # Add lakshmi.devi to IT-Managers
    Add-ADGroupMember -Identity "IT-Managers" -Members "lakshmi.devi"
    Write-Host "    [+] lakshmi.devi added to IT-Managers" -ForegroundColor Green
    
    # Add lakshmi.devi to IT-Admins
    Add-ADGroupMember -Identity "IT-Admins" -Members "lakshmi.devi"
    Write-Host "    [+] lakshmi.devi added to IT-Admins" -ForegroundColor Green
    
    # Add ravi.teja to IT-Admins
    Add-ADGroupMember -Identity "IT-Admins" -Members "ravi.teja"
    Write-Host "    [+] ravi.teja added to IT-Admins" -ForegroundColor Green
    
    # Add management users to Bank-Managers
    Add-ADGroupMember -Identity "Bank-Managers" -Members "vamsi.krishna","pranavi","madhavi"
    Write-Host "    [+] Management users added to Bank-Managers" -ForegroundColor Green
    
    # Add operations users to Operations-Staff
    Add-ADGroupMember -Identity "Operations-Staff" -Members "divya","harsha.vardhan","kiran.kumar","sai.kiran"
    Write-Host "    [+] Operations users added to Operations-Staff" -ForegroundColor Green
    
    # Add svc_backup to Backup-Operators
    Add-ADGroupMember -Identity "Backup-Operators" -Members "svc_backup"
    Write-Host "    [+] svc_backup added to Backup-Operators" -ForegroundColor Green
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.5: CONFIGURE KERBEROASTING VULNERABILITY (svc_backup)
    #============================================================================
    # For Kerberoasting to work, we need to register SPNs on the service account
    # SPN = Service Principal Name
    # It tells Kerberos "this account runs these services"
    
    Write-Host "[*] Configuring Kerberoasting vulnerability..." -ForegroundColor Yellow
    Write-Host "    Target: svc_backup" -ForegroundColor Gray
    
    # What is an SPN?
    # An SPN is a unique identifier for a service instance
    # Format: ServiceClass/hostname:port
    # For example: MSSQLSvc/dc01.napellam.local:1433
    # This says "SQL Server service running on dc01.napellam.local port 1433"
    
    # When we register an SPN on svc_backup, it means:
    # "svc_backup account is running these services"
    # "To access these services, users get service tickets encrypted with svc_backup's password"
    
    # We register two fake SPNs to make this account Kerberoastable:
    Set-ADUser -Identity "svc_backup" -ServicePrincipalNames @{
        Add = "MSSQLSvc/dc01.napellam.local:1433",
              "HTTP/backup.napellam.local"
    }
    
    Write-Host "    [+] Registered SPN: MSSQLSvc/dc01.napellam.local:1433" -ForegroundColor Green
    Write-Host "    [+] Registered SPN: HTTP/backup.napellam.local" -ForegroundColor Green
    Write-Host "    [!] svc_backup is now Kerberoastable!" -ForegroundColor Yellow
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.6: CONFIGURE AS-REP ROASTING VULNERABILITY (pranavi)
    #============================================================================
    # AS-REP Roasting requires disabling Kerberos pre-authentication
    # This is done by setting the DONT_REQUIRE_PREAUTH flag
    
    Write-Host "[*] Configuring AS-REP Roasting vulnerability..." -ForegroundColor Yellow
    Write-Host "    Target: pranavi" -ForegroundColor Gray
    
    # What is pre-authentication?
    # Normally, when you request a TGT from the DC, you must prove you know the password
    # You do this by sending a timestamp encrypted with your password hash
    # The DC decrypts it and checks if the timestamp is valid
    # This is "pre-authentication" - you prove yourself BEFORE getting a ticket
    
    # When we disable pre-auth:
    # The user can request a TGT without proving they know the password
    # The DC responds with a TGT encrypted with the user's password hash
    # An attacker can request this TGT and crack it offline
    
    # We disable pre-auth by setting the DoesNotRequirePreAuth flag
    Set-ADAccountControl -Identity "pranavi" -DoesNotRequirePreAuth $true
    
    Write-Host "    [+] Disabled Kerberos pre-authentication for pranavi" -ForegroundColor Green
    Write-Host "    [!] pranavi is now AS-REP Roastable!" -ForegroundColor Yellow
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.7: CONFIGURE ACL ABUSE VULNERABILITY (lakshmi.devi)
    #============================================================================
    # We give the IT-Managers group GenericAll permission on lakshmi.devi
    # GenericAll means "full control" - they can do ANYTHING to this user object
    
    Write-Host "[*] Configuring ACL abuse vulnerability..." -ForegroundColor Yellow
    Write-Host "    Target: lakshmi.devi" -ForegroundColor Gray
    Write-Host "    Granting: IT-Managers → GenericAll" -ForegroundColor Gray
    
    # What is GenericAll?
    # It's an Access Control Entry (ACE) that grants all permissions:
    # - Read all properties
    # - Write all properties  
    # - Delete the object
    # - Change permissions
    # - Reset password (without knowing old password!)
    # - Add to groups
    
    # Step 1: Get the user object
    $TargetUser = Get-ADUser -Identity "lakshmi.devi"
    
    # Step 2: Get the group's SID
    # SID = Security Identifier (unique ID for each security principal)
    $GroupSID = (Get-ADGroup -Identity "IT-Managers").SID
    
    # Step 3: Get the current ACL (Access Control List) of lakshmi.devi
    # The ACL is like a permission list attached to every AD object
    $ACL = Get-Acl -Path "AD:$($TargetUser.DistinguishedName)"
    
    # Step 4: Create a new Access Control Entry (ACE)
    # This is a single permission rule
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
        $GroupSID,                    # Who gets the permission
        "GenericAll",                 # What permission they get
        "Allow"                       # Allow or Deny
    )
    
    # Step 5: Add this ACE to the ACL
    $ACL.AddAccessRule($ACE)
    
    # Step 6: Apply the modified ACL back to the user object
    Set-Acl -Path "AD:$($TargetUser.DistinguishedName)" -AclObject $ACL
    
    Write-Host "    [+] Granted IT-Managers GenericAll permission on lakshmi.devi" -ForegroundColor Green
    Write-Host "    [!] lakshmi.devi is now vulnerable to ACL abuse!" -ForegroundColor Yellow
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.8: CONFIGURE DCSYNC VULNERABILITY (svc_backup)
    #============================================================================
    # DCSync is an attack where we pretend to be a Domain Controller
    # We ask the real DC to replicate directory data to us
    # This includes ALL password hashes in the domain!
    
    Write-Host "[*] Configuring DCSync vulnerability..." -ForegroundColor Yellow
    Write-Host "    Target: svc_backup" -ForegroundColor Gray
    
    # What is DCSync?
    # Domain Controllers sync their databases using the Directory Replication Service (DRS)
    # When DC2 wants updates from DC1, it uses the GetNCChanges operation
    # DC1 sends all changed objects, including password hashes
    
    # To perform DCSync, you need two Extended Rights:
    # 1. DS-Replication-Get-Changes
    # 2. DS-Replication-Get-Changes-All
    
    # These are normally only granted to Domain Controllers
    # By giving these rights to svc_backup, we create a vulnerability
    
    # Step 1: Get svc_backup's SID
    $UserSID = (Get-ADUser -Identity "svc_backup").SID
    
    # Step 2: Get the domain's distinguished name
    $DomainDN = (Get-ADDomain).DistinguishedName
    
    # Step 3: Get the current ACL of the domain root
    $DomainACL = Get-Acl -Path "AD:$DomainDN"
    
    # Step 4: Create ACE for DS-Replication-Get-Changes
    # This GUID is the unique identifier for this Extended Right
    $GUID1 = [GUID]"1131f6aa-9c07-11d1-f79f-00c04fc2dcd2"
    $ACE1 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
        $UserSID,
        "ExtendedRight",              # This is an Extended Right permission
        "Allow",
        $GUID1                        # The specific Extended Right
    )
    $DomainACL.AddAccessRule($ACE1)
    
    # Step 5: Create ACE for DS-Replication-Get-Changes-All
    # This GUID allows replicating secret domain data (passwords!)
    $GUID2 = [GUID]"1131f6ad-9c07-11d1-f79f-00c04fc2dcd2"
    $ACE2 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
        $UserSID,
        "ExtendedRight",
        "Allow",
        $GUID2
    )
    $DomainACL.AddAccessRule($ACE2)
    
    # Step 6: Apply the modified ACL
    Set-Acl -Path "AD:$DomainDN" -AclObject $DomainACL
    
    Write-Host "    [+] Granted DS-Replication-Get-Changes to svc_backup" -ForegroundColor Green
    Write-Host "    [+] Granted DS-Replication-Get-Changes-All to svc_backup" -ForegroundColor Green
    Write-Host "    [!] svc_backup can now perform DCSync attack!" -ForegroundColor Yellow
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.9: DISABLE SMB SIGNING (RELAY ATTACKS)
    #============================================================================
    # SMB signing adds cryptographic signatures to SMB packets
    # When disabled, SMB relay attacks become possible
    
    Write-Host "[*] Disabling SMB signing requirement..." -ForegroundColor Yellow
    
    # What is SMB Signing?
    # SMB (Server Message Block) is used for file sharing and remote admin in Windows
    # SMB signing adds a digital signature to each packet
    # This prevents man-in-the-middle attacks and relay attacks
    
    # When SMB signing is disabled:
    # An attacker can capture authentication attempts
    # And relay them to another server
    # Gaining access without knowing the password
    
    # We disable it on both server and client sides
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
                     -Name "RequireSecuritySignature" -Value 0 -Type DWord -Force
    
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
                     -Name "RequireSecuritySignature" -Value 0 -Type DWord -Force
    
    Write-Host "    [+] SMB signing disabled on server" -ForegroundColor Green
    Write-Host "    [+] SMB signing disabled on client" -ForegroundColor Green
    Write-Host "    [!] SMB relay attacks are now possible!" -ForegroundColor Yellow
    
    Write-Host ""
    
    #============================================================================
    # STEP 3.10: ENABLE REMOTE ACCESS (WinRM, RDP)
    #============================================================================
    # We enable remote management so workstations can connect
    
    Write-Host "[*] Enabling remote management..." -ForegroundColor Yellow
    
    # Enable WinRM (Windows Remote Management)
    # This allows PowerShell Remoting and remote admin via WinRM
    Enable-PSRemoting -Force | Out-Null
    Write-Host "    [+] WinRM enabled (PowerShell Remoting)" -ForegroundColor Green
    
    # Enable Remote Desktop
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
                     -Name "fDenyTSConnections" -Value 0 -Force
    
    # Allow RDP through firewall
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    
    Write-Host "    [+] Remote Desktop (RDP) enabled" -ForegroundColor Green
    
    # Enable File and Printer Sharing (for SMB enumeration)
    Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True -Profile Any -ErrorAction SilentlyContinue
    Write-Host "    [+] File and Printer Sharing enabled" -ForegroundColor Green
    
    Write-Host ""
    
    #============================================================================
    # FINAL SUMMARY
    #============================================================================
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  PHASE 3 COMPLETE - LAB IS READY!" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DOMAIN CONFIGURATION:" -ForegroundColor Yellow
    Write-Host "  Domain:            napellam.local" -ForegroundColor White
    Write-Host "  Domain Controller: DC01.napellam.local" -ForegroundColor White
    Write-Host "  IP Address:        192.168.100.10" -ForegroundColor White
    Write-Host ""
    Write-Host "USERS CREATED: 12 accounts" -ForegroundColor Yellow
    Write-Host "  IT Department:     ammulu.orsu, lakshmi.devi, ravi.teja" -ForegroundColor White
    Write-Host "  Management:        vamsi.krishna, pranavi, madhavi" -ForegroundColor White
    Write-Host "  Operations:        divya, harsha.vardhan, kiran.kumar, sai.kiran" -ForegroundColor White
    Write-Host "  Service Account:   svc_backup" -ForegroundColor White
    Write-Host "  Built-in:          Administrator" -ForegroundColor White
    Write-Host ""
    Write-Host "VULNERABILITIES CONFIGURED:" -ForegroundColor Yellow
    Write-Host "  [1] Kerberoasting:   svc_backup (SPNs registered)" -ForegroundColor Red
    Write-Host "  [2] AS-REP Roasting: pranavi (no pre-auth required)" -ForegroundColor Red
    Write-Host "  [3] ACL Abuse:       lakshmi.devi (IT-Managers has GenericAll)" -ForegroundColor Red
    Write-Host "  [4] DCSync:          svc_backup (replication rights granted)" -ForegroundColor Red
    Write-Host "  [5] Domain Admin:    ammulu.orsu (weak password + DA)" -ForegroundColor Red
    Write-Host "  [6] SMB Signing:     Disabled (relay attacks possible)" -ForegroundColor Red
    Write-Host "  [7] Weak Passwords:  10 users with rockyou.txt passwords" -ForegroundColor Red
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Set up WS01 (192.168.100.20) and join to domain" -ForegroundColor White
    Write-Host "  2. Set up WS02 (192.168.100.30) and join to domain" -ForegroundColor White
    Write-Host "  3. Set up KALI (192.168.100.100) for attacks" -ForegroundColor White
    Write-Host "  4. Begin pentesting!" -ForegroundColor White
    Write-Host ""
    Write-Host "DC01 setup is complete! Have fun learning AD pentesting!" -ForegroundColor Green
    Write-Host ""
}

#================================================================================
# ALREADY CONFIGURED
#================================================================================
# If we reach this point, Phase 3 was already completed in a previous run

if ($OUsExist) {
    Write-Host ">>> LAB ALREADY CONFIGURED <<<" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This lab has already been set up. All users, groups, and vulnerabilities exist." -ForegroundColor White
    Write-Host ""
    Write-Host "If you want to rebuild from scratch:" -ForegroundColor Yellow
    Write-Host "  1. Demote this DC (Remove-ADDomain or reinstall Windows)" -ForegroundColor White
    Write-Host "  2. Run this script again" -ForegroundColor White
    Write-Host ""
}
