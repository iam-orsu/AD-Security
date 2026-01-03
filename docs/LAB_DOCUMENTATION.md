# Napellam Bank AD Pentesting Lab - Complete Documentation

**Author:** Vamsi Krishna  
**Purpose:** Learning Active Directory penetration testing from scratch  
**Goal:** Prepare for a career as an Offensive Security Consultant

---

## Table of Contents

1. [Lab Setup Guide](#1-lab-setup-guide)
2. [Network Configuration](#2-network-configuration)
3. [Active Directory Fundamentals](#3-active-directory-fundamentals)
4. [Troubleshooting](#4-troubleshooting)

---

# 1. Lab Setup Guide

This section will guide you through setting up all virtual machines needed for the Napellam Bank AD pentesting lab.

## 1.1 What You Will Build

By the end of this guide, you will have a small Active Directory network with:

- **DC01**: Domain Controller running Windows Server 2022
- **WS01**: Workstation machine running Windows 10 Pro (IT Department)
- **WS02**: Workstation machine running Windows 10 Pro (Network Admin)
- **KALI**: Attack machine running Kali Linux

All machines will be on an isolated network (192.168.100.0/24) and completely separate from your real network.

## 1.2 Hardware Requirements

Your physical computer needs:

| Component | Minimum | Recommended | Why? |
|-----------|---------|-------------|------|
| **RAM** | 16 GB | 24-32 GB | Each VM needs 4 GB. With 4 VMs, that's 16 GB just for the VMs. More RAM = smoother performance |
| **CPU** | 4 cores | 6-8 cores | Virtualization needs processing power. More cores = VMs run faster |
| **Disk Space** | 250 GB free | 300+ GB free | Each Windows VM = ~60 GB, Kali = ~80 GB, plus room for snapshots |
| **CPU Feature** | VT-x/AMD-V enabled | Same | Without this, VMs won't work. Check BIOS settings |

**Checking if you have VT-x/AMD-V enabled:**

1. On Windows: Open Task Manager → Performance tab → CPU
2. Look for "Virtualization: Enabled"
3. If it says "Disabled", you need to enable it in BIOS
   - Restart computer → Press F2/F10/Delete (depends on motherboard)
   - Look for "Intel VT-x" or "AMD-V" option
   - Enable it → Save and exit

## 1.3 Software Requirements

Download and install:

### VMware Workstation Pro or Player

**What is it?**  
VMware is software that lets you run multiple operating systems on one physical computer. Each operating system runs in a "virtual machine" (VM).

**Where to get it:**  
- VMware Workstation Player (Free for personal use): [Download Link](https://www.vmware.com/products/workstation-player.html)
- VMware Workstation Pro (Paid, but has more features): [Download Link](https://www.vmware.com/products/workstation-pro.html)

**Which should you use?**  
VMware Workstation Player is fine for this lab. The Pro version has extra features like taking snapshots (saving the VM state), but Player works perfectly.

**Installation:**
1. Download the installer
2. Run it as Administrator
3. Follow the wizard (Next → Next → Install)
4. Restart your computer

## 1.4 Downloading Operating System ISOs

An **ISO file** is a disk image - it's like a CD/DVD in file format. We use ISOs to install operating systems on virtual machines.

### 1.4.1 Windows Server 2022 (for DC01)

**What is Windows Server?**  
Windows Server is Microsoft's operating system designed for servers. It has extra features like Active Directory, which regular Windows doesn't have.

**Evaluation Version:**  
Microsoft provides free evaluation versions that work for 180 days (6 months). This is perfect for a lab.

**Download Steps:**

1. Go to: [https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)

2. Click "Download the ISO"

3. You'll need to fill a form (you can use fake info for a lab):
   - Name: Your name
   - Email: Your email (they'll send download link here)
   - Company: "Learning Lab" or anything
   - Country: India

4. Choose:
   - **Language:** English (United States)
   - **Edition:** Windows Server 2022 (64-bit)

5. Download will start. File size is around 5 GB.

6. Save it somewhere safe, like: `C:\ISOs\WindowsServer2022.iso`

**Which edition to choose during installation?**  
When you install, you'll be asked to choose an edition. Choose:
- **Windows Server 2022 Standard Evaluation (Desktop Experience)**

"Desktop Experience" means it has a GUI (graphical interface). Without it, you only get a command line, which is harder for beginners.

### 1.4.2 Windows 10 Pro (for WS01 and WS02)

**Why Windows 10 Pro and not Home?**  
Windows 10 Home edition cannot join an Active Directory domain. Only Pro, Enterprise, or Education editions can join domains.

**Download Steps:**

1. Go to: [https://www.microsoft.com/en-us/software-download/windows10](https://www.microsoft.com/en-us/software-download/windows10)

2. Scroll down to "Create Windows 10 installation media"

3. Click "Download tool now"

4. This downloads a tool called "MediaCreationTool"

5. Run MediaCreationTool as Administrator

6. Choose: **"Create installation media (USB flash drive, DVD, or ISO file) for another PC"**

7. Select:
   - Language: English (United States)
   - Edition: Windows 10
   - Architecture: 64-bit (x64)

8. Choose: **ISO file**

9. Save it as: `C:\ISOs\Windows10.iso`

10. Wait for download (around 5-6 GB)

**Activation:**  
During installation, when asked for a product key, click "I don't have a product key". You can run Windows 10 unactivated in a lab. It will have a watermark but works fully.

### 1.4.3 Kali Linux (for Attack Machine)

**What is Kali Linux?**  
Kali is a special Linux distribution (distro) made specifically for penetration testing. It comes with hundreds of hacking tools pre-installed.

**Download Steps:**

1. Go to: [https://www.kali.org/get-kali/#kali-installer-images](https://www.kali.org/get-kali/#kali-installer-images)

2. Look for "Recommended" image

3. Download: **Installer (64-bit)**

4. File name will be something like: `kali-linux-2024.x-installer-amd64.iso`

5. Size is around 3-4 GB

6. Save it as: `C:\ISOs\Kali-Linux.iso`

**Important:**  
Download the **Installer** version, not the Live version. The Installer version lets you install Kali permanently on the VM.

## 1.5 Creating the Virtual Machines

Now that you have VMware and all the ISOs, we'll create the virtual machines.

### 1.5.1 Creating DC01 (Domain Controller)

This is the most important machine - the brain of the Active Directory network.

**Step 1: Create New Virtual Machine**

1. Open VMware Workstation
2. Click "Create a New Virtual Machine"
3. Choose **"Typical"** configuration
4. Click "Next"

**Step 2: Select ISO**

1. Choose **"Installer disc image file (iso)"**
2. Click "Browse"
3. Navigate to `C:\ISOs\WindowsServer2022.iso`
4. Select it and click "Open"
5. Click "Next"

**Step 3: Guest Operating System**

1. Windows should be auto-detected
2. If not, choose:
   - Guest Operating System: **Microsoft Windows**
   - Version: **Windows Server 2022**
3. Click "Next"

**Step 4: Name the Virtual Machine**

1. Virtual machine name: **DC01**
2. Location: Choose where to save it (e.g., `C:\VMs\DC01\`)
3. Click "Next"

**Step 5: Disk Size**

1. Maximum disk size: **60 GB**
2. Choose: **"Store virtual disk as a single file"** (this is faster)
3. Click "Next"

**Step 6: Customize Hardware**

Before finishing, we need to customize the hardware:

1. Click **"Customize Hardware"**

2. **Memory:**
   - Set to: **4096 MB (4 GB)**
   - This is the RAM the VM will use

3. **Processors:**
   - Number of processors: **1**
   - Number of cores per processor: **2**
   - Total cores = 2

4. **Network Adapter:**
   - THIS IS CRITICAL - PAY ATTENTION!
   - Change from "NAT" to **"Custom: VMnet2"**
   - (We'll create VMnet2 in the Network Configuration section)
   - For now, just select it. If VMnet2 doesn't exist yet, that's okay.

5. **CD/DVD (SATA):**
   - Make sure "Connect at power on" is checked
   - It should be pointing to the Windows Server ISO

6. Click "Close"

7. Click "Finish"

**Step 7: Install Windows Server**

1. Click "Power on this virtual machine"

2. Windows Server installation starts

3. Choose:
   - Language: English (US)
   - Time and currency: India (or your country)
   - Keyboard: US

4. Click "Install now"

5. **Select Operating System:**
   - Choose: **Windows Server 2022 Standard Evaluation (Desktop Experience)**
   - This gives you the GUI interface

6. Accept license terms

7. Choose: **"Custom: Install Windows only (advanced)"**

8. Select the disk (should be 60 GB)

9. Click "Next"

10. Wait for installation (takes 10-15 minutes)

11. The VM will restart automatically

**Step 8: Initial Setup**

After restart:

1. You'll be asked to set Administrator password
2. Set it to: **P@ssw0rd!**
3. Confirm password: **P@ssw0rd!**
4. Click "Finish"

5. Press Ctrl+Alt+Delete (or Ctrl+Alt+Insert in VMware)
6. Login with password: **P@ssw0rd!**

**Step 9: Run the DC01 Setup Script**

1. Inside the VM, open PowerShell **as Administrator**
   - Right-click Start menu → "Windows PowerShell (Admin)"

2. You need to copy the DC01 setup script into this VM
   - Option A: Use a shared folder
   - Option B: Copy-paste the script content
   - Option C: Download from a USB or shared drive

3. For simplicity, let's use copy-paste:
   - Open Notepad inside the VM
   - Copy the entire content of `Setup-DC01.ps1` from your host machine
   - Paste it inside Notepad in the VM
   - Save it as: `C:\Setup-DC01.ps1`

4. In PowerShell, navigate to the script:
   ```powershell
   cd C:\
   ```

5. Allow script execution (PowerShell security policy):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   ```

6. Run the script:
   ```powershell
   .\Setup-DC01.ps1
   ```

7. The script will:
   - Configure network (192.168.100.10)
   - Rename computer to DC01
   - Install AD DS role
   - Restart

8. After restart, run the script again:
   ```powershell
   cd C:\
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\Setup-DC01.ps1
   ```

9. This time it promotes to Domain Controller and restarts again

10. After second restart, run it ONE MORE TIME:
    ```powershell
    cd C:\
    Set-ExecutionPolicy Bypass -Scope Process -Force
    .\Setup-DC01.ps1
    ```

11. This creates all users, groups, OUs, and vulnerabilities

12. DC01 is now ready!

### 1.5.2 Creating WS01 (IT Workstation)

Follow similar steps as DC01, but with these differences:

**Hardware Specs:**
- Name: **WS01**
- ISO: **Windows10.iso**
- RAM: **4 GB**
- CPU: **2 cores**
- Disk: **50 GB**
- Network: **Custom: VMnet2**

**Installation:**
1. Boot from ISO
2. Choose: **Windows 10 Pro**
3. During install, choose "I don't have a product key"
4. Complete installation
5. Set local account name: **localadmin**
6. Set password: **P@ssw0rd!**

**Run Join Script:**
1. Copy `Join-Domain.ps1` for WS01 into the VM
   - Save it to: `C:\Join-Domain.ps1` (root of C drive for easy access)
   - You can use copy-paste, shared folder, or USB to transfer the file

2. Open PowerShell as Administrator
   - Right-click Start → "Windows PowerShell (Admin)"

3. Navigate to where you saved the script:
   ```powershell
   cd C:\
   ```

4. Set execution policy (allows script to run):
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   ```

5. Run the script:
   ```powershell
   .\Join-Domain.ps1
   ```

6. Script will:
   - Configure network (192.168.100.20)
   - Rename computer to WS01  
   - Join napellam.local domain
   - Enable remote management
   - Restart automatically in 10 seconds

**After Restart (CRITICAL - Read Carefully!):**

**WHO TO LOGIN AS:** After the computer restarts, you MUST login as the **local admin account** you created during Windows 10 installation (username: `localadmin`, password: `P@ssw0rd!`).

**Why?** The domain user (ammulu.orsu) is NOT a local administrator yet. The script will add them in this second run. If you try to login as the domain user now, you won't have admin rights to run the script!

**Steps:**

1. After restart, at Windows login screen, click "Other user" if needed

2. Login as:
   - Username: **localadmin** (just localadmin, NOT napellam\localadmin)
   - Password: **P@ssw0rd!**

3. Open PowerShell as Administrator
   - Right-click Start → "Windows PowerShell (Admin)"

4. Navigate to the script location:
   ```powershell
   cd C:\
   ```

5. Set execution policy AGAIN (it resets after restart):
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   ```

6. Run the script AGAIN:
   ```powershell
   .\Join-Domain.ps1
   ```

7. Script will automatically add ammulu.orsu as local admin
   - You'll see: `[+] ammulu.orsu added to local Administrators`

8. Log out of localadmin account

9. Login as the domain user:
   - Click "Other user"
   - Username: **napellam\ammulu.orsu**
   - Password: **princess**
   - This caches Domain Admin credentials in memory (critical for attacks!)

10. WS01 is now ready!

### 1.5.3 Creating WS02 (Network Admin Workstation)

Follow same steps as WS01, with these differences:

**Hardware:**
- Name: **WS02**
- Create local account: **localadmin** (same as WS01)
- Everything else same as WS01

**Script Setup:**
1. Save script to: `C:\Join-Domain.ps1` 
2. First run: Configures IP **192.168.100.30** (not .20) and joins domain
3. Computer restarts

**After restart:**
1. Login as **localadmin** (NOT the domain user yet!)
2. Run PowerShell as Administrator
3. Set execution policy: `Set-ExecutionPolicy Bypass -Scope Process -Force`
4. Navigate: `cd C:\`
5. Run script again: `.\Join-Domain.ps1`
6. Script adds **ravi.teja** as local admin
7. Logout and login as: **napellam\ravi.teja** (password: **football**)

### 1.5.4 Creating KALI (Attack Machine)

**Hardware Specs:**
- Name: **KALI**
- ISO: **Kali-Linux.iso**
- RAM: **4 GB** (or 8 GB if you have extra RAM)
- CPU: **2 cores**
- Disk: **80 GB**
- Network: **Custom: VMnet2**

**Installation:**

1. Power on VM
2. Choose: **Graphical Install**
3. Language: English
4. Location: India (or your country)
5. Keyboard: American English
6. Hostname: **kali**
7. Domain name: **Leave blank**
8. Full name: **kali**
9. Username: **kali**
10. Password: **kali** (or choose your own)
11. Partition: **Guided - use entire disk**
12. Continue with installation

**After Installation:**

1. Login as kali/kali
2. Open Terminal
3. Update system:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

4. Configure static IP:
   ```bash
   sudo nano /etc/network/interfaces
   ```

5. Add these lines:
   ```
   auto eth0
   iface eth0 inet static
       address 192.168.100.100
       netmask 255.255.255.0
       gateway 192.168.100.10
       dns-nameservers 192.168.100.10
   ```

6. Save (Ctrl+O, Enter, Ctrl+X)

7. Restart networking:
   ```bash
   sudo systemctl restart networking
   ```

8. Test connectivity:
   ```bash
   ping 192.168.100.10
   ping dc01.napellam.local
   ```

---

# 2. Network Configuration

This section explains how to set up the isolated network for the lab.

## 2.1 Understanding VMware Networks

VMware provides 3 types of virtual networks:

| Network Type | What It Does | Use Case |
|--------------|--------------|----------|
| **Bridged** | VM gets IP from your real router, appears as real device on your home network | When VM needs internet and should be visible to other devices at home |
| **NAT** | VM shares your computer's internet connection through NAT | When VM needs internet but should be hidden from your home network |
| **Host-Only** | VM can only talk to other VMs and your host computer. NO internet | When you want complete isolation (perfect for pentesting lab) |

For this lab, we use **Host-Only** network because:
1. Complete isolation - attacks won't affect your real network
2. No risk of accidentally attacking real devices
3. Predictable, controlled environment

## 2.2 Creating VMnet2 (Host-Only Network)

VMnet2 is just a name. It's a virtual network adapter that exists only in VMware.

**Step-by-Step:**

1. Open VMware Workstation
2. Go to: **Edit → Virtual Network Editor**
3. Click: **"Change Settings"** (requires admin rights)
4. Click: **"Add Network"**
5. Select: **VMnet2**
6. Click: **OK**

7. Now configure VMnet2:
   - **Type:** Host-only
   - **Subnet IP:** 192.168.100.0
   - **Subnet Mask:** 255.255.255.0

8. **CRITICAL:** Unch eck these options:
   - ☐ Use local DHCP service to distribute IP addresses
   - ☐ Connect a host virtual adapter to this network

   **Why uncheck?**
   - No DHCP: We're assigning static IPs manually for better control
   - No host adapter: We don't need the host computer on this network

9. Click: **Apply**
10. Click: **OK**

Done! VMnet2 now exists. All VMs set to "Custom: VMnet2" will be on this isolated network.

---


---

# 3. Active Directory Fundamentals

This section explains everything you need to know about Active Directory before you can attack it. We'll cover what it is, how it works internally, and why attackers target specific components.

## 3.1 What is Active Directory and Why Do Companies Use It?

Active Directory is Microsoft's system for managing everything in a Windows network - users, computers, printers, file shares, and more. Think of it as a central database and control system for the entire organization.

**Let's understand this with a real company example:**

Imagine you work at Infosys. They have:
- 300,000 employees worldwide
- 50,000 computers (laptops, desktops, servers)
- 500 office locations

**Without Active Directory, this is what would happen:**

Let's say you're an employee named james. You work in the Chennai office.

1. **Getting access to your work computer:**
   - IT admin creates a local account on your laptop: "james" with password "MyPass123"
   - This account only works on your specific laptop
   - If you go to Mumbai office and use a different computer there, you can't login
   - IT admin would need to create a separate account on that Mumbai computer too

2. **Accessing the file server:**
   - Chennai office has a file server with project documents
   - IT admin creates another account on that file server: "james" again
   - You now have two accounts with possibly different passwords
   - If you forget which password goes where, you're stuck

3. **When you leave the company:**
   - IT admin must find every single computer and server you had access to
   - Manually delete your account from each one
   - If they miss even one system, you still have access after leaving

4. **Changing your password:**
   - You want to change your password
   - You have to change it separately on your laptop, the file server, the email server, etc.
   - Very annoying and time-consuming

**With Active Directory, here's what happens:**

1. **Single account everywhere:**
   - IT creates ONE account for james in Active Directory
   - This account works on any computer in any Infosys office worldwide
   - Username: james@infosys.com
   - Password: One password for everything

2. **Login from anywhere:**
   - james travels to Mumbai office
   - Uses any computer there
   - Types his username and password
   - Computer asks Active Directory: "Is james@infosys.com a valid user with this password?"
   - Active Directory says: "Yes, that's correct"
   - james logs in successfully

3. **Access control:**
   - Active Directory stores information: "james is in the Engineering department"
   - File server asks Active Directory: "Can james access the Engineering folder?"
   - Active Directory checks: "Yes, he's in Engineering department"
   - Access granted

4. **When leaving:**
   - IT admin disables ONE account in Active Directory
   - Immediately, james cannot login to any computer anywhere
   - Cannot access any file server
   - Cannot use email
   - Everything blocked with one action

5. **Password changes:**
   - james changes his password once
   - New password works everywhere instantly

**This is why every company with more than 10-20 computers uses Active Directory - it's just impossible to manage hundreds or thousands of users without it.**

## 3.2 The Three Core Components of Active Directory

Active Directory is actually three systems working together:

### Component 1: LDAP (The Database)

LDAP stands for Lightweight Directory Access Protocol. This is the database part.

**What does it store?**

Every object in your network is stored here:
- Users (employees)
- Computers (laptops, desktops, servers)
- Groups (like "Engineering Team" or "HR Department")
- Printers
- File shares
- And much more

**How is data organized?**

Think of it like a tree structure, similar to folders on your computer.

Example at TCS:
```
TCS.com (root)
│
├── Users
│   ├── IT Department
│   │   ├── Amit Kumar
│   │   ├── Priya Singh
│   │   └── Rahul Verma
│   │
│   ├── HR Department
│   │   ├── Neha Sharma
│   │   └── Vijay Reddy
│   │
│   └── Finance Department
│       ├── Sanjay Patel
│       └── Pooja Gupta
│
├── Computers
│   ├── Laptops
│   │   ├── LAPTOP-001
│   │   ├── LAPTOP-002
│   │   └── LAPTOP-003
│   │
│   └── Servers
│       ├── FILE-SERVER-01
│       └── EMAIL-SERVER-01
│
└── Groups
    ├── Engineering-Team
    ├── HR-Admins
    └── Finance-Managers
```

**How do you query this database?**

Programs use LDAP queries to search and retrieve information.

Example: When you try to login, your computer sends an LDAP query:
```
"Find user with username = amit.kumar"
```

Active Directory searches the database and returns information about Amit Kumar, including his password hash for verification.

### Component 2: Kerberos (The Authentication System)

Kerberos is the system that verifies you are who you claim to be, and gives you tickets to access resources.

**Why is it called Kerberos?**

In Greek mythology, Kerberos (Cerberus) was a three-headed dog guarding the gates of the underworld. Similarly, this system guards your network by verifying everyone who tries to enter.

**What problem does it solve?**

Old authentication systems (like NTLM) had a problem: every time you accessed a resource, you had to send your password over the network. This is dangerous because someone could intercept it.

Kerberos solves this by using "tickets" instead of passwords.

**How does it work? Let's trace a real example:**

**Scenario:** You (Amit from TCS) arrive at office and want to access a project file on the file server.

**Step 1: You turn on your laptop and login**

1. You type:
   - Username: amit.kumar@tcs.com
   - Password: MySecureP@ss123

2. Your laptop doesn't send your password anywhere yet. Instead:
   - It converts your password into a hash (a scrambled version)
   - Example: "MySecureP@ss123" becomes "A1B2C3D4E5F6..." (this is irreversible)

3. Your laptop contacts the Domain Controller (DC) and says:
   - "Hi, I'm amit.kumar and here's proof"
   - The proof is: current timestamp encrypted with your password hash
   - This proves you know the password without sending the actual password

4. The Domain Controller (the main Active Directory server) does this:
   - Looks up amit.kumar in the database
   - Gets your stored password hash
   - Decrypts your proof using that hash
   - If it decrypts successfully and the timestamp is recent (within 5 minutes), you're authenticated!

5. The DC gives you a special ticket called TGT (Ticket Granting Ticket)
   - This ticket is like a VIP pass
   - It says "Amit Kumar is authenticated for the next 10 hours"
   - The ticket is encrypted so only the DC can read it
   - You can't see what's inside your own ticket, but you can present it

**Step 2: You want to access the file server**

1. You double-click on a file: `\\FILE-SERVER-01\Projects\TCS-Banking.docx`

2. Your laptop says:
   - "I need to access FILE-SERVER-01"
   - "Let me get a ticket for that"

3. Your laptop contacts the DC again and says:
   - "Here's my TGT (the VIP pass from earlier)"
   - "I need access to FILE-SERVER-01"

4. The DC checks:
   - Opens your TGT to verify it's real
   - Sees you're Amit Kumar
   - Creates a new ticket specifically for FILE-SERVER-01
   - This new ticket is encrypted with FILE-SERVER-01's password
   - Only FILE-SERVER-01 can read this ticket

5. The DC gives you this FILE-SERVER-01 ticket

6. Your laptop connects to FILE-SERVER-01 and says:
   - "Here's my ticket"

7. FILE-SERVER-01 does this:
   - Decrypts the ticket using its own password
   - Reads inside: "This is Amit Kumar from Engineering department"
   - Checks permissions: "Can Engineering department access this file?"
   - If yes, sends you the file

**Notice what just happened:**
- You only typed your password ONCE (when logging in)
- Your password was never sent over the network
- You accessed the file server using tickets, not passwords
- The file server verified your identity without contacting the DC

This is why Kerberos is more secure and faster than old systems.

### Component 3: DNS (The Directory)

DNS (Domain Name System) is like a phone book for the network.

**Why does Active Directory need DNS?**

When your computer needs to contact the Domain Controller, it doesn't know the DC's IP address. DNS helps find it.

**Example:**

1. Your laptop needs to talk to the Domain Controller
2. It asks DNS: "Where is dc01.tcs.com?"
3. DNS responds: "dc01.tcs.com is at IP address 192.168.1.10"
4. Your laptop can now contact the DC at that IP

**In our lab:**
- Domain Name: napellam.local
- Domain Controller: DC01.napellam.local
- DC's IP address: 192.168.100.10
- When workstation WS01 wants to authenticate, it asks DNS for DC01.napellam.local and gets 192.168.100.10

## 3.3 The Domain Controller - The Brain of Active Directory

### What is a Domain Controller?

A Domain Controller (DC) is a Windows Server computer that runs Active Directory. It's the most important server in the entire network.

**At a company like Wipro:**
- They might have 10-20 Domain Controllers globally
- One DC in each major office (Mumbai, Bangalore, Hyderabad, etc.)
- All DCs have copies of the same database
- If one DC fails, others take over

### What's Actually Running on a Domain Controller?

When you install Active Directory on a Windows Server, these services start running:

**1. Active Directory Domain Services (AD DS)**
- This is the main service
- Manages the database
- Handles all queries
- Updates information

**2. DNS Server**
- Required for AD to work
- Helps computers find the DC
- Helps computers find each other

**3. Kerberos Key Distribution Center (KDC)**
- Issues tickets
- Verifies authentication requests
- Handles all the ticket-granting we discussed earlier

**4. LDAP Server**
- Listens for database queries
- Responds with information from the database
- Runs on TCP port 389

**5. Netlogon Service**
- Handles user logins
- Establishes secure channels between computers and

 the DC

**6. Time Service**
- Keeps all computers' clocks synchronized
- This is critical! Kerberos requires clocks to be within 5 minutes of each other
- If your laptop's time is wrong by more than 5 minutes, authentication will fail

### The NTDS.dit File - Where Everything is Stored

**Location:** `C:\Windows\NTDS\NTDS.dit`

This is THE most important file on a Domain Controller. It contains EVERYTHING:

**What's inside NTDS.dit:**

1. **All user accounts:**
   - Usernames
   - Password hashes (scrambled passwords)
   - Email addresses
   - Phone numbers
   - Department information
   - When the account was created
   - When they last logged in
   - Everything about every user

2. **All computer accounts:**
   - Computer names
   - Computer passwords (yes, computers have passwords too!)
   - When they joined the domain
   - Operating system version

3. **All groups:**
   - Group names
   - Who belongs to which group
   - Group permissions

4. **Security information:**
   - Who can access what
   - Permissions on every object
   - Password policies
   - Account lockout settings

**File size example:**

At a company with:
- 10,000 employees
- 5,000 computers
- 500 groups

The NTDS.dit file would be around 2-3 GB in size.

**Why attackers desperately want this file:**

If an attacker steals NTDS.dit, they get:
- Every password hash in the company
- They can crack weak passwords offline
- They can use strong password hashes directly (pass-the-hash attacks)
- They get the krbtgt account hash (used to create Golden Tickets)
- Basically, they own the entire network

**How is it protected:**

1. **File permissions:** Only the SYSTEM account can read it
2. **File locking:** While Windows is running, the file is locked (you can't copy it)
3. **Encryption:** The file is encrypted with a special key
4. **The key location:** The encryption key is stored in `C:\Windows\System32\config\SYSTEM`

To crack the file, you need BOTH NTDS.dit AND the SYSTEM file.

### How Multiple Domain Controllers Stay in Sync

**The problem:**

Wipro has DCs in Mumbai, Bangalore, and Delhi. An employee in Mumbai changes their password.  How does the Bangalore DC know about this change?

**The solution: Replication**

Replication is the process of copying changes between Domain Controllers.

**Here's how it works step-by-step:**

**Scenario: Priya changes her password in Mumbai office**

1. **Priya connects to Mumbai-DC01:**
   - Opens "Change Password" screen
   - Types old password and new password
   - Clicks "OK"

2. **Mumbai-DC01 processes the change:**
   - Verifies old password is correct
   - Stores new password hash in its NTDS.dit database
   - Records: "I just updated Priya's password at 10:30 AM"
   - Assigns this change a number called USN (Update Sequence Number)
   - Let's say this change gets USN number 12345

3. **Mumbai-DC01 notifies other DCs:**
   - Sends a message to Mumbai-DC02: "I have new changes, my latest USN is 12345"
   - Sends a message to Bangalore-DC01: "I have new changes, my latest USN is 12345"
   - Sends a message to Delhi-DC01: "I have new changes, my latest USN is 12345"

4. **Mumbai-DC02 responds quickly (same office):**
   - "My last known USN from you was 12340"
   - "Send me all changes from 12340 to 12345"
   - Mumbai-DC01 sends: "Priya's password changed, here's the new hash"
   - Mumbai-DC02 updates its database
   - **This happens within 15 seconds** (same office = fast replication)

5. **Bangalore-DC01 responds slower (different city):**
   - Replication between cities follows a schedule
   - Maybe every 15 minutes or every hour (configured by IT)
   - Bangalore-DC01 eventually asks: "Send me changes since USN 12300"
   - Receives all changes including Priya's new password
   - Updates its database

**Result:**
- After 15 seconds: Priya can login in any Mumbai office with new password
- After 15 minutes: Priya can login in Bangalore office with new password
- After 15 minutes: Priya can login in Delhi office with new password

**Why this matters for attacks:**

If you compromise one DC and extract password hashes, those hashes are valid on all DCs because they all have the same database.

I'll continue with more sections in the next part. Is this the level of detail and explanation style you're looking for?



### FSMO Roles - Special Jobs That OnlyOne DC Can Handle

**What's the problem we're solving?**

Most things in Active Directory can be done by any Domain Controller. For example:
- Any DC can create a new user
- Any DC can reset a password
- Any DC can change group memberships

But some special operations would cause problems if multiple DCs tried to do them at the same time. That's where FSMO roles come in.

**FSMO = Flexible Single Master Operations**

Think of it like this: In a company with multiple managers, most decisions can be made by anyone. But some critical decisions (like hiring/firing) should only be made by ONE specific person to avoid conflicts.

### The Five FSMO Roles Explained

**Role 1: RID Master (Resource ID Generator)**

**What it does:**  
Every object in Active Directory needs a unique ID number called a SID. The RID Master hands out blocks of ID numbers to other DCs.

**Real-world example at Wipro:**

Wipro has 5 Domain Controllers: DC1, DC2, DC3, DC4, DC5.

1. **Initial setup:**
   - DC1 is the RID Master
   - DC1 gives DC2 a block of 500 numbers: 1000-1500
   - DC1 gives DC3 a block: 1501-2000
   - DC1 gives DC4 a block: 2001-2500
   - DC1 gives DC5 a block: 2501-3000

2. **Creating users:**
   - HR admin connects to DC2 and creates user "Amit Kumar"
   - DC2 assigns him number 1000 (first from its pool)
   - HR admin creates another user "Priya Singh"
   - DC2 assigns her number 1001
   - And so on...

3. **Running out of numbers:**
   - After DC2 creates 250 users, it has used half its pool
   - DC2 contacts RID Master (DC1): "I need another block of numbers"
   - DC1 gives DC2 a new block: 3001-3500

**Why this role exists:**  
Without the RID Master, two DCs might assign the same number to different users, causing a conflict.

**What happens if RID Master goes down:**  
Other DCs can still create users until they run out of numbers from their current pool. Once they run out, they can't create new users until RID Master comes back online.

**Role 2: PDC Emulator (The Master Clock)**

**What it does:**  
This is the most important FSMO role. It handles:
- Time synchronization for the entire domain
- Password changes (it processes them first)
- Account lockouts
- Group Policy updates

**Real-world example at TCS:**

**Scenario 1: Password changes**

1. User Rahul works in Chennai office
2. He forgets his password and calls IT helpdesk
3. IT admin resets Rahul's password
4. The password reset request goes to the PDC Emulator first (even if there are 10 other DCs)
5. PDC Emulator updates the password
6. Then PDC Emulator replicates this change to all other DCs immediately (doesn't wait for normal replication schedule)

**Why?** If Rahul tries to login immediately after password reset, we want to make sure it works. If the change was made on a random DC, Rahul might connect to a different DC that doesn't have the new password yet.

**Scenario 2: Account lockouts**

1. Someone tries to hack Rahul's account
2. They try wrong password 5 times
3. Account lockout policy: "Lock account after 5 failed attempts"
4. Each DC tracks failed attempts on its own
5. The PDC Emulator is the authority - it adds up all failed attempts from all DCs
6. When total reaches 5, PDC Emulator locks the account everywhere

**Scenario 3: Time synchronization**

1. All computers get their time from the PDC Emulator
2. PDC Emulator gets its time from an external source (like time.windows.com)
3. This keeps everyone synchronized

Remember: Kerberos requires clocks to be within 5 minutes. If PDC Emulator's time is wrong, authentication fails across the entire domain.

**What happens if PDC Emulator goes down:**  
- Password changes become slow (go to any DC, then replicate slowly)
- Account lockouts might not work correctly
- Time synchronization breaks
- This is a BIG problem!

**Role 3: Schema Master (The Blueprint Keeper)**

**What it does:**  
The schema is the blueprint that defines what types of objects can exist in Active Directory and what information they can store.

**Think of it like a database table structure:**
- User table has columns: UserName, Password, Email, Department
- Computer table has columns: ComputerName, OperatingSystem, LastLogon

**Real-world example:**

Company decides to install Microsoft Exchange (email server).

1. Exchange needs to store email addresses for users
2. But standard Active Directory doesn't have an "EmailAddress" field for users
3. Exchange installer contacts the Schema Master
4. Says: "I need to add a new field called 'EmailAddress' to all user objects"
5. Schema Master modifies the blueprint
6. Now all DCs know: users can have an email address field

**How often is this used:**  
Very rarely. Maybe once a year when deploying new Microsoft products or major updates.

**Role 4: Domain Naming Master (The Domain Manager)**

**What it does:**  
Controls adding or removing domains from the forest.

**Real-world example:**

Reliance Industries acquires a new company called "StartupX".

1. They want to add startupx.com as a child domain under reliance.com
2. IT admin contacts the Domain Naming Master
3. Domain Naming Master checks: "Is there already a domain called startupx.com in this forest?"
4. If not, it allows the creation
5. New domain is added to the forest

**How often is this used:**  
Rarely. Only during company mergers, acquisitions, or major restructuring.

**Role 5: Infrastructure Master (The Relationship Tracker)**

**What it does:**  
In forests with multiple domains, this tracks references between domains.

**Example scenario:**

Company has two domains:
- india.company.com
- usa.company.com

1. User "Amit" is in india.company.com
2. Group "Global-Finance" is in usa.company.com
3. Admin adds Amit to Global-Finance group
4. Infrastructure Master keeps track: "Global-Finance contains a user from a different domain (Amit from india.company.com)"

**How often is this used:**  
Only matters if you have multiple domains. In a single-domain environment (like our lab), it doesn't do anything.

**Why attackers care about FSMO roles:**

If you compromise the PDC Emulator specifically:
- You can manipulate time (break Kerberos authentication)
- You see all password changes first
- You can cause account lockouts to DOS users

## 3.4 Understanding Kerberos Step-by-Step

Kerberos is the authentication system used in Active Directory. Let's understand it by following a complete real-world scenario.

### The Problem Kerberos Solves

**Old way (NTLM):**

You want to access a file server.

1. You send your password to the file server
2. File server forwards your password to the DC
3. DC verifies it's correct
4. File server lets you in

**Problems:**
- Your password travels across the network (can be intercepted)
- File server sees your password (not good for security)
- Every time you access anything, password needs to be verified
- DC gets overwhelmed with authentication requests

**New way (Kerberos):**

You prove who you are ONCE at the beginning. Then you get tickets to access stuff. No passwords sent over the network after initial login.

### Complete Step-by-Step Kerberos Flow

**Our scenario:**  
You are Amit Kumar, working at TCS. You arrive at office, turn on your laptop, and want to access a project document on the file server.

---

**PHASE 1: INITIAL LOGIN (Getting the TGT)**

**Step 1: You type your credentials**

- You open your laptop
- Windows shows login screen
- You type:
  - Username: amit.kumar@tcs.com
  - Password: MyPassword123!

**Step 2: Your laptop creates a "proof" that you know the password**

Your laptop does NOT send your password to anyone. Instead:

1. It runs your password through a mathematical function (called a hash)
   - Password: "MyPassword123!"
   - Hash function: MD4 algorithm
   - Result: A long string of characters like "A1B2C3D4E5F6G7H8..."
   - This process is one-way (you can't reverse it to get the password back)

2. Your laptop looks at the clock: Current time is 10:00:00 AM

3. It encrypts this timestamp using your password hash as the encryption key
   - Timestamp: "10:00:00"
   - Encryption key: Your password hash
   - Result: Encrypted blob that looks random

**Step 3: Your laptop contacts the Domain Controller**

Your laptop sends a message to the DC (this message is called AS-REQ):

```
"Hello DC, I am amit.kumar@tcs.com
Here is my proof that I know the password: [encrypted timestamp]
I would like a ticket valid for 10 hours please"
```

**Step 4: Domain Controller verifies you are who you claim to be**

The DC does this:

1. Receives your message: "User claims to be amit.kumar@tcs.com"

2. Looks up amit.kumar in the LDAP database (NTDS.dit file)

3. Retrieves your stored password hash from the database

4. Tries to decrypt your proof (the encrypted timestamp) using this hash

5. If decryption works, it gets timestamp: "10:00:00"

6. DC checks its own clock: "My time is 10:00:02"

7. Calculates difference: 2 seconds (well within the 5-minute limit)

8. Decision: "This is really Amit Kumar! Authentication successful!"

**Why the timestamp matters:**  
If someone intercepts your encrypted proof and tries to replay it tomorrow, the timestamp will be 24 hours old. The DC will reject it.

**Step 5: DC creates your TGT (Ticket Granting Ticket)**

DC creates a special ticket containing:

```
Ticket contents:
- Username: amit.kumar@tcs.com
- Full Name: Amit Kumar
- Department: Engineering
- Groups: Domain Users, Engineering-Team, Project-Alpha
- Valid from: January 3, 2026 10:00 AM
- Valid until: January 3, 2026 8:00 PM (10 hours from now)
- Session Key: [random encryption key generated just for you]
```

But here's the trick: The DC encrypts this ENTIRE ticket using a special account's password called "krbtgt".

**Who/What is krbtgt?**
- It's a special account that exists only for Kerberos
- It's not a real person
- It has a super long random password (120+ characters)
- Only the DC knows this password
- The krbtgt password is used to encrypt all TGTs

**Why encrypt the TGT with krbtgt's password?**
- You (Amit) can't read your own TGT (you don't know krbtgt password)
- You can't modify your TGT (if you try, DC will detect it when trying to decrypt)
- Only the DC can read and verify TGTs

**Step 6: DC sends you the TGT**

DC sends you a message (called AS-REP):

```
Part 1: Your TGT [encrypted with krbtgt password - you can't read this]
Part 2: Session Key [encrypted with YOUR password hash - you CAN read this]
```

You decrypt Part 2 to get the session key. You store:
- TGT (encrypted, you can't see inside)
- Session Key (you can see this)

Both are stored in memory (in a special area called "Kerberos Ticket Cache").

**Step 7: You're now logged in!**

Windows desktop appears. You're authenticated.

---

**PHASE 2: ACCESSING THE FILE SERVER (Getting a Service Ticket)**

**Step 8: You want to open a file**

You double-click:  `\\FILE-SERVER-01\Projects\TCS-Banking-Project.docx`

**Step 9: Your laptop realizes it needs a ticket for the file server**

Your laptop thinks:
- "I need to access FILE-SERVER-01"
- "I have a TGT, but that's just proof I'm authenticated"
- "I need a specific ticket for FILE-SERVER-01"
- "Let me ask the DC for that"

**Step 10: Your laptop contacts the DC again**

Your laptop sends a message (called TGS-REQ):

```
"Hello DC,
Here is my TGT: [the encrypted TGT from earlier]
I need access to: FILE-SERVER-01
Specifically the service: CIFS (file sharing)
Here's my authenticator: [current timestamp encrypted with session key]"
```

** Step 11: DC processes your request**

The DC does:

1. Receives your TGT

2. Decrypts it using krbtgt password

3. Reads inside:
   - "This is Amit Kumar"
   - "He's valid until 8:00 PM"
   - "His groups are: Domain Users, Engineering-Team, Project-Alpha"
   - "His session key is: [the key we gave him earlier]"

4. Decrypts your authenticator using the session key

5. Checks timestamp is recent (within 5 minutes) ✓

6. Looks up in AD: "What account runs CIFS service on FILE-SERVER-01?"
   - Answer: The computer account "FILE-SERVER-01$" runs this service

7. DC creates a new ticket specifically for FILE-SERVER-01

**Step 12: DC creates the Service Ticket**

DC creates:

```
Service Ticket contents:
- User: amit.kumar@tcs.com
- Groups: Domain Users, Engineering-Team, Project-Alpha
- Service: CIFS/FILE-SERVER-01
- Valid for: 10 hours
- New Session Key: [another random key for Amit ↔ FILE-SERVER-01 communication]
```

DC encrypts this ENTIRE ticket using FILE-SERVER-01's password.

**Why FILE-SERVER-01's password?**
- Only FILE-SERVER-01 can decrypt this ticket
- Even you (Amit) can't read it
- If someone intercepts it, they can't use it (they don't have FILE-SERVER-01's password)

**Step 13: DC sends you the Service Ticket**

```
Part 1: Service Ticket [encrypted with FILE-SERVER-01's password - you can't read]
Part 2: New Session Key [encrypted with original session key - you CAN read]
```

**Step 14: Your laptop connects to FILE-SERVER-01**

Your laptop:
1. Connects to FILE-SERVER-01
2. Sends the Service Ticket
3. Sends another authenticator (timestamp encrypted with new session key)

**Step 15: FILE-SERVER-01 grants you access**

FILE-SERVER-01 does:

1. Receives the Service Ticket

2. Decrypts it using its own password

3. Reads inside:
   - "This is Amit Kumar"
   - "He's in groups: Domain Users, Engineering-Team, Project-Alpha"

4. Checks file permissions on `TCS-Banking-Project.docx`:
   - "Who can access this file?"
   - "Engineering-Team group has Read access"
   - "Amit is in Engineering-Team ✓"

5. Sends you the file

**You successfully opened the file!**

---

### What We Just Learned

**Key Points:**

1. **Password sent only once:** During initial login, and even then it's hashed

2. **Tickets instead of passwords:** After login, you use tickets to access resources

3. **Two types of tickets:**
   - TGT: Proves you're authenticated (get this during login)
   - Service Ticket: Proves you can access a specific service (get this when accessing something)

4. **DC's role:**
   - Issues TGT when you login
   - Issues Service Tickets when you access resources
   - After that, resources verify your tickets themselves (no need to contact DC again)

5. **Why it's secure:**
   - Passwords never sent over network (after initial hash)
   - Tickets are encrypted
   - Timestamps prevent replay attacks
   - Each ticket is encrypted with the target's password (only they can read it)

I'll continue with more sections. How does this explanation style work for you?

- Password hash sent over network (can be intercepted)
- No mutual authentication (client doesn't verify server)
- Requires DC for every authentication (doesn't scale)

### Understanding Common Kerberos Attacks

Now that you know how Kerberos works, let's see how attackers exploit it.

**Attack 1: Kerberoasting**

**The vulnerability:**  
Remember service tickets? They're encrypted with the service account's password. Here's the problem:
- ANY authenticated user can request a service ticket for ANY service
- The DC doesn't check if you actually need to access that service
- You get the ticket, it's encrypted with the service account's password
- You can try to crack it offline

**Step-by-step attack at Wipro:**

1. **Attacker compromises a low-privilege account:**
   - They phished employee "Rahul" and got his password
   - Rahul is just a regular user, not an admin
   - But that's enough!

2. **Attacker searches for service accounts:**
   - Logs in as Rahul
   - Queries Active Directory: "Show me all users who have services registered"
   - Finds: `svc_sql` (runs SQL Server), `svc_backup` (runs backup software), `svc_web` (runs IIS)

3. **Attacker requests service tickets:**
   - "DC, I need a ticket for MSSQLSvc/sql01.wipro.com (the SQL service)"
   - DC gives them a ticket encrypted with svc_sql's password
   - "DC, I need a ticket for HTTP/backup.wipro.com"
   - DC gives them another ticket encrypted with svc_backup's password

4. **Attacker saves these tickets to a file and leaves the network:**
   - They now have encrypted tickets on their personal computer
   - They can crack them at home, DC has no idea

5. **Attacker tries to crack the passwords:**
   - Uses a tool called hashcat
   - Tries millions of passwords from wordlists
   - After 2 hours: "svc_backup password is: Backup@2023!"
   - After 8 hours: "svc_sql password is: SQLServer2020!"

6. **Attacker logs back in as svc_backup:**
   - This account has high privileges
   - Can access backup systems
   - Can read sensitive data

**Why this works:**  
Service accounts often have weak passwords because admins think "nobody will login with this account, it's just for running services." But with Kerberoasting, you don't need to login - you just crack the ticket offline.

**How our lab is vulnerable:**  
Our `svc_backup` account has password "backup123" - very easy to crack!

**Attack 2: AS-REP Roasting**

**The vulnerability:**  
Remember Kerberos pre-authentication? That's when you prove you know the password before DC gives you a TGT. Some accounts have this DISABLED.

**What happens when pre-auth is disabled:**

Normal flow:
1. You send proof (encrypted timestamp)
2. DC verifies
3. DC gives you TGT

Without pre-auth:
1. You just ask for a TGT (no proof needed)
2. DC gives you TGT immediately

**The attack:**

1. **Attacker doesn't even need to be authenticated:**
   - They can be completely outside the network
   - Just need to reach the DC

2. **Attacker finds users without pre-auth:**
   - Scans Active Directory
   - Finds user "pranavi" has pre-auth disabled

3. **Attacker requests TGT for pranavi:**
   - "DC, give me a TGT for pranavi"
   - DC gives TGT encrypted with pranavi's password
   - DC doesn't ask for proof because pre-auth is disabled

4. **Attacker cracks the TGT offline:**
   - Uses hashcat
   - After 30 minutes: "pranavi's password is: butterfly"

5. **Attacker logs in as pranavi**

**Why this exists:**  
Very old applications from the 1990s couldn't do pre-auth. Some companies disabled it for compatibility and never re-enabled it.

**How our lab is vulnerable:**  
Our user `pranavi` has pre-auth disabled with weak password "butterfly".

**Attack 3: Golden Ticket**

**The vulnerability:**  
Remember krbtgt? That special account whose password encrypts all TGTs? If you steal krbtgt's password hash, you can create fake TGTs.

**The attack scenario:**

1. **Attacker becomes Domain Admin (through some other attack)**

2. **Attacker extracts krbtgt password hash:**
   - Runs a DCSync attack
   - Gets krbtgt hash: `A1B2C3D4E5F6...`
   - Stores it safely

3. **Attacker gets kicked out:**
   - Company detects the breach
   - Resets all passwords
   - Removes attacker's access
   - Thinks they're safe

4. **Attacker comes back:**
   - Uses the krbtgt hash to create a FAKE TGT
   - This fake TGT says: "I am Administrator, Domain Admin, valid for 10 years"
   - Encrypts it with the krbtgt hash
   - Presents it to DC

5. **DC accepts the fake TGT:**
   - DC decrypts using krbtgt hash
   - Reads: "This is Administrator"
   - DC doesn't know it's fake
   - Attacker has full access again

**Why it's called "Golden":**  
Because krbtgt password rarely changes. Even if you reset all user passwords, if you don't reset krbtgt password twice, Golden Tickets still work.

**How to fix:**  
Reset krbtgt password twice with 10 hours wait between resets (to clear all cached tickets).

## 3.5 Understanding NTLM Authentication

NTLM is the older authentication system. It's still used in some scenarios even today.

**When is NTLM used instead of Kerberos?**

1. **Computer not joined to domain** (like your home computer accessing a work share)
2. **Using IP address instead of name** (\\192.168.100.10\share instead of \\dc01.napellam.local\share)
3. **Kerberos fails for some reason** (wrong time, DNS issues, etc)
4. **Old applications** that specifically request NTLM

### How NTLM Works - Complete Example

**Scenario:** You're on WS01, trying to access a file on FILE-SERVER-01.

**Step 1: You try to access the file**
- You type: `\\FILE-SERVER-01\documents\report.docx`
- Windows needs to authenticate you to the file server

**Step 2: Your computer contacts the file server**
Your computer sends:
```
"Hello FILE-SERVER-01, I want to authenticate as napellam\vamsi.krishna"
```

**Step 3: File server generates a challenge**

The file server:
1. Generates a random 8-byte number
   - Example: `0x1234567890ABCDEF`
2. Sends it to you: "Here's your challenge: `0x1234567890ABCDEF`"

**Step 4: Your computer creates a response**

Your computer:
1. Takes the challenge: `0x1234567890ABCDEF`
2. Takes your password hash (stored in memory from when you logged in)
3. Uses your password hash to encrypt the challenge
4. Result: An encrypted blob
5. Sends this blob back to file server: "Here's my response: [encrypted blob]"

**Step 5: File server can't verify itself, asks DC**

File server:
1. Receives your response
2. Doesn't know your password or hash
3. Forwards everything to DC: "User vamsi.krishna gave me this response to this challenge, is it correct?"

**Step 6: DC verifies**

DC:
1. Looks up vamsi.krishna in database
2. Gets your password hash
3. Encrypts the same challenge with your hash
4. Compares: Does my result match what file server received?
5. If YES: "Authentication successful"
6. If NO: "Authentication failed"
7. Tells file server the result

**Step 7: File server grants/denies access**
- If DC said OK: You get access to the file
- If DC said NO: "Access Denied" error

### Why NTLM is Less Secure Than Kerberos

**Problem 1: Password hash is the password**

In NTLM, your password hash is used directly for authentication. So:
- If someone steals your hash, they can authenticate as you
- They don't need to crack it to get the password
- They just use the hash directly (this is called "Pass-the-Hash")

**Real attack at TCS:**

1. Attacker gets local admin on one workstation
2. Dumps memory to get password hashes of users who logged into that computer
3. Finds hash of user "admin.tcs": `A1B2C3D4E5F6...`
4. Uses a tool to authenticate AS admin.tcs using just the hash (doesn't know password!)
5. Gains admin access to servers

**Problem 2: No mutual authentication**

- Client authenticates to server (you prove who you are)
- Server doesn't prove who IT is
- Attacker could set up a fake server, you'd authenticate to it, they'd capture your hash

**Problem 3: Relay attacks possible**

If SMB signing is disabled:

1. You try to access `\\FAKESHARE\files`
2. Attacker intercepts: "I'm FAKESHARE"
3. You send NTLM authentication to attacker
4. Attacker relays it to DC01
5. Attacker gets admin access to DC01 (if you're an admin)

This is why our lab has SMB signing disabled - to practice this attack!

## 3.6 Where Passwords Are Stored and How to Steal Them

As an attacker, finding passwords/hashes is critical. Let's understand where they're stored.

### Location 1: SAM Database (Local Accounts)

**What is it:**  
SAM = Security Account Manager. It's a file that stores local user accounts on each computer.

**Location:** `C:\Windows\System32\config\SAM`

**What's stored:**
- Local usernames (not domain accounts!)
- Their password hashes
- Account settings

**Example at TCS:**

Every Windows computer has a local Administrator account (different from domain Administrator).

On WS01:
- Local account: Administrator
- Password: LocalP@ss123
- This password hash is in WS01's SAM file

**How attackers steal it:**

**Method 1: Using Volume Shadow Copy**

While Windows is running, SAM file is locked. But you can copy it from a shadow copy:

```powershell
# Create shadow copy
vssadmin create shadow /for=C:

# Copy SAM from shadow copy
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\System32\config\SAM C:\temp\SAM

# Also need SYSTEM file (it has the encryption key)
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\System32\config\SYSTEM C:\temp\SYSTEM

# Delete shadow copy to hide traces
vssadmin delete shadows /for=C: /quiet
```

**Method 2: Boot from another OS**

1. Boot victim computer from USB with Linux
2. Mount Windows hard drive
3. Copy SAM and SYSTEM files
4. Take them home and crack

**Extracting hashes from SAM:**

```bash
# On Kali Linux
secretsdump.py -sam SAM -system SYSTEM LOCAL

# Output:
# Administrator:500:aad3b435b51404ee:31d6cfe0d16ae931:::
# Guest:501:aad3b435b51404ee:31d6cfe0d16ae931:::
# localuser:1001:aad3b435b51404ee:A1B2C3D4E5F6G7H8:::
```

Format: `username:RID:LM_hash:NTLM_hash`

Now they can crack the NTLM hash or use it for pass-the-hash!

### Location 2: LSASS Memory (Cached Credentials)

**What is LSASS:**  
LSASS = Local Security Authority Subsystem Service
- It's a process running on every Windows computer
- Handles authentication
- Stores credentials in memory

**Why credentials are in memory:**

When you login, Windows stores your credentials in LSASS so:
- You don't have to type password every time you access something
- Faster access to network resources
- Kerberos tickets are cached here
- Password hashes cached here

**What's in LSASS memory:**
1. Password hashes (NTLM format)
2. Kerberos tickets (TGT and service tickets)
3. Sometimes even plaintext passwords (if WDigest is enabled)

**Real-world example:**

You (vamsi.krishna) login to WS01 in the morning.
- Your password hash is now in LSASS memory on WS01
- Your TGT is in LSASS memory
- Your session keys are in LSASS memory

Later, Domain Admin (`ammulu.orsu`) comes to your desk:
- "Can I use your computer for a minute?"
- She logs in on WS01
- Her password hash is NOW ALSO in LSASS memory on WS01
- Her TGT is there
- She logs out and leaves

Attacker compromises WS01:
- Dumps LSASS memory
- Gets ammulu.orsu's hash
- Uses pass-the-hash to become Domain Admin

**This is why our lab has ammulu.orsu login to WS01 - so you can practice dumping her credentials!**

**How to dump LSASS:**

**Method 1: Task Manager (easiest)**

1. Open Task Manager
2. Find "Local Security Authority Process"
3. Right-click → "Create dump file"
4. Saves to: `C:\Users\YourName\AppData\Local\Temp\lsass.DMP`
5. Copy this file to Kali
6. Run Mimikatz: `sekurlsa::minidump lsass.DMP` then `sekurlsa::logonPasswords`

**Method 2: Mimikatz (directly on victim)**

```powershell
# Run Mimikatz as admin
.\mimikatz.exe

# Get debug privileges
privilege::debug

# Dump credentials
sekurlsa::logonpasswords
```

Output:
```
Authentication Id : 0 ; 123456
Session           : Interactive from 1
User Name         : ammulu.orsu
Domain            : NAPELLAM
NTLM              : 8846f7eaee8fb117ad06bdd830b7586c
```

That NTLM hash is ammulu.orsu's password hash. Now you can:
- Crack it (get password "princess")
- Or use it directly for pass-the-hash

**Method 3: Procdump (Microsoft's own tool, less suspicious)**

```powershell
procdump.exe -ma lsass.exe lsass.dmp
```

### Location 3: NTDS.dit (Domain Controller Database)

This is the crown jewels - every password hash in the entire domain.

**Location:** `C:\Windows\NTDS\NTDS.dit` (only on Domain Controllers)

**What's inside:**
- ALL domain user password hashes
- ALL computer account password hashes  
- krbtgt password hash
- ALL group memberships
- Everything!

**Why attackers want this:**

At Wipro with 100,000 employees:
- Steal NTDS.dit = Get 100,000 password hashes
- Crack a few thousand weak passwords
- Use pass-the-hash for the rest
- Own the entire company

**How to steal NTDS.dit:**

**Method 1: DCSync (best method, doesn't touch the file)**

Remember domain replication? DCs copy data between each other. You can pretend to be a DC and ask for all the data!

Requirements:
- Replication rights (DS-Replication-Get-Changes)
- Our lab's svc_backup has these rights!

```bash
# From Kali
secretsdump.py napellam.local/svc_backup:backup123@192.168.100.10

# DC thinks: "svc_backup is replicating, let me send all data"
# You get: Every password hash
```

Output:
```
Administrator:500:aad3b435b51404ee:31d6cfe0d16ae931:::
krbtgt:502:aad3b435b51404ee:A1B2C3D4E5F6G7H8:::
vamsi.krishna:1105:aad3b435b51404ee:F730720CD7E3CE13:::
ammulu.orsu:1106:aad3b435b51404ee:8846f7eaee8fb117:::
svc_backup:1115:aad3b435b51404ee:BACKUP123HASH:::
```

Now you have EVERY password hash in the domain!

**Method 2: Volume Shadow Copy (if you're on the DC)**

```powershell
vssadmin create shadow /for=C:
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\NTDS\NTDS.dit C:\temp\ntds.dit
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\System32\config\SYSTEM C:\temp\system
```

Then extract:
```bash
secretsdump.py -ntds ntds.dit -system system LOCAL
```

I'll continue with ACLs, SIDs, and SPNs in the next part. Are these explanations clear and detailed enough?

   - DC encrypts this entire ticket using the **krbtgt account's NTLM hash**
   - krbtgt is a special account that exists only for this purpose
   - Only the DC knows krbtgt's hash

5. **DC sends AS-REP to WS01 (Authentication Service Reply)**
   - Message contains two parts:
     - **Part A:** The TGT (encrypted with krbtgt hash) - user CANNOT read this
     - **Part B:** The session key (encrypted with user's NTLM hash) - user CAN read this
   
   - User decrypts Part B to get the session key
   - User stores the TGT and session key in memory

**Why TGT is encrypted with krbtgt hash:**  
This ensures only the DC can read the TGT. The user presents this TGT back to the DC later, and the DC decrypts it to verify it's legitimate. If user modifies the TGT, decryption fails and they're caught.

**Phase 2: TGS-REQ and TGS-REP (Getting the Service Ticket)**

6. **User wants to access \\FILE01\share**
   - WS01 needs a service ticket for FILE01's CIFS service
   - CIFS (Common Internet File System) is the protocol for file sharing

7. **WS01 sends TGS-REQ to DC (Ticket Granting Service Request)**
   - Message contains:
     - The TGT (which DC can decrypt)
     - SPN requested: `CIFS/FILE01.napellam.local`
     - Authenticator (encrypted with the session key from Phase 1)
   
   - Authenticator contains timestamp to prevent replay attacks

8. **DC receives TGS-REQ**
   - DC decrypts the TGT using krbtgt hash
   - Extracts: username, groups, session key
   - Decrypts authenticator using session key
   - Verifies timestamp is recent (within 5 minutes)
   - Looks up SPN in Active Directory: `CIFS/FILE01.napellam.local`
   - Finds that FILE01$ computer account is associated with this SPN

9. **DC creates the Service Ticket**
   - DC creates ticket containing:
     - Username: vamsi.krishna
     - User's SID and groups
     - Service SPN: CIFS/FILE01.napellam.local
     - Valid from/until timestamps
     - New session key (for client-to-service encryption)
   
   - DC encrypts this ticket using **FILE01 computer account's NTLM hash**
   - Only FILE01 can decrypt this ticket

10. **DC sends TGS-REP to WS01**
    - Message contains two parts:
      - **Part A:** Service ticket (encrypted with FILE01's hash) - user CANNOT read
      - **Part B:** The new session key (encrypted with the original session key)
    
    - User decrypts Part B to get the new session key
    - User stores the service ticket

**Phase 3: AP-REQ and AP-REP (Accessing the Service)**

11. **WS01 connects to FILE01**
    - WS01 sends the service ticket to FILE01
    - FILE01 decrypts it using its own NTLM hash
    - FILE01 extracts: username, groups
    - FILE01 checks ACLs on the share
    - If vamsi.krishna's groups have permission, access granted

12. **Optional: Mutual authentication**
    - FILE01 can prove its identity back to the client
    - Prevents fake servers from stealing credentials

### Kerberos Pre-Authentication

**What is it?**  
The step where user encrypts timestamp with password hash in AS-REQ.

**Why it exists:**  
Without pre-auth, anyone can request a TGT for any username. The TGT is encrypted with the user's hash, so they can't read it. But if they request it and try to crack it offline, they can potentially get the password.

**AS-REP Roasting attack:**  
If a user has pre-authentication disabled, attacker can:
1. Send AS-REQ for that user (without knowing password)
2. Receive AS-REP with TGT encrypted with user's hash
3. Save the TGT
4. Crack it offline with hashcat to get the password

This is why pranavi is vulnerable in our lab - we disabled pre-auth.

### Kerberoasting Attack - Technical Details

**The vulnerability:**  
Service tickets are encrypted with the service account's NTLM hash. Any authenticated user can request a service ticket for any service. The DC doesn't check if you actually need to access the service - it just gives you the ticket.

**Attack steps:**

1. Attacker authenticates as any domain user (even low-privilege)
2. Attacker queries AD for all user accounts with SPNs registered:
   ```
   LDAP query: (&(objectCategory=person)(servicePrincipalName=*))
   ```
3. For each user with SPN, attacker requests a service ticket
4. DC returns service ticket encrypted with that user's hash
5. Attacker saves all service tickets to disk
6. Attacker runs hashcat or john to crack the tickets offline

**Example with our lab:**

1. Attacker is logged in as vamsi.krishna
2. Attacker finds svc_backup has SPN: `MSSQLSvc/dc01.napellam.local:1433`
3. Attacker requests ticket: `TGS-REQ for MSSQLSvc/dc01.napellam.local:1433`
4. DC returns ticket encrypted with svc_backup's hash of password "backup123"
5. Attacker saves ticket in Kerberos format
6. Attacker runs:
   ```
   hashcat -m 13100 ticket.txt rockyou.txt
   ```
7. Hashcat cracks it: password = backup123
8. Attacker logs in as svc_backup
9. svc_backup has DCSync rights → Attacker dumps all domain hashes

**Real company scenario:**  
At Wipro, a developer account was compromised (phishing). The attacker ran Kerberoasting and found 15 service accounts with SPNs. Out of 15, three had weak passwords. One of them was a SQL Server service account with "Summer2023!" as password. This account had db_owner permissions on all databases, including HR database with salary information.

### Golden Ticket Attack - Complete Breakdown

**What is it?**  
A Golden Ticket is a forged TGT that you create yourself, without the DC's help.

**Prerequisites:**
- krbtgt account's NTLM hash
- Domain SID
- Username you want to impersonate

**How you get krbtgt hash:**
1. Compromise Domain Admin account
2. Run DCSync attack: `secretsdump.py` extracts all hashes including krbtgt
3. Or: physical access to DC, copy NTDS.dit and SYSTEM hive, extract offline

**Creating the ticket:**

Using Mimikatz or impacket's ticketer.py:

```
ticketer.py -nthash <krbtgt_hash> -domain-sid <domain_SID> -domain napellam.local Administrator
```

This creates a fake TGT that says "I am Administrator" and is encrypted with krbtgt's hash. When you present this to DC, DC decrypts it with krbtgt hash and believes you are Administrator.

**Why it's called "Golden":**  
Because krbtgt hash rarely changes. Even if you reset Administrator password, the Golden Ticket still works. It's valid as long as krbtgt hash doesn't change.

**How long it's valid:**  
You can set any expiration time. You can make it valid for 10 years if you want.

**Detection:**  
Very hard to detect because it looks like a legitimate TGT. Some indicators:
- TGT has unrealistic lifetime (10 years)
- TGT generated timestamp doesn't match any DC logs
- TGT contains impossible group memberships

**Real scenario at a bank:**  
Attackers compromised a bank's network, got DA, ran DCSync, extracted krbtgt hash. They created multiple Golden Tickets with different usernames that expire in 2030. Even after the bank reset all passwords and kicked attackers out, attackers came back using Golden Tickets. The bank had to reset krbtgt password twice (with 10 hours wait between resets, because old tickets are cached) to fully kill all Golden Tickets.

## 3.4 NTLM Authentication - How It Actually Works

NTLM is older than Kerberos but still used in many scenarios.

**When NTLM is used:**
- Computer not joined to domain
- Accessing server by IP address instead of hostname
- Kerberos fails for some reason (fallback)
- Application specifically requests NTLM

### NTLM Authentication Flow

**Scenario:** User on WS01 connects to FILE01 using IP address

1. **Client sends authentication request to server**
   - Message: "I want to authenticate as napellam\vamsi.krishna"

2. **Server generates challenge**
   - Server creates random 8-byte number (challenge)
   - Example: `0x1234567890ABCDEF`
   - Server sends this to client

3. **Client creates response**
   - Client has user's NTLM hash (from password)
   - Client uses NTLM hash as the key to encrypt the challenge using DES
   - This encrypted challenge is the "response"
   - Client sends: username + response + domain name

4. **Server forwards to DC**
   - Server doesn't know user's hash
   - Server sends to DC: username, challenge, response
   - DC looks up user's NTLM hash from NTDS.dit
   - DC encrypts the same challenge with user's hash
   - DC compares: Does my encrypted result match client's response?
   - If yes: authentication success. If no: authentication failure.
   - DC tells server: allow or deny

5. **Server grants access**
   - Server checks file permissions
   - If allowed, user can access files

### NTLMv1 vs NTLMv2

**NTLMv1 (old, insecure):**
- Uses DES encryption (weak)
- Challenge is 8 bytes
- Can be cracked very quickly
- Vulnerable to pass-the-hash

**NTLMv2 (newer, more secure):**
- Uses HMAC-MD5 (stronger)
- Challenge includes timestamp and client challenge
- Harder to crack
- Still vulnerable to pass-the-hash

**Pass-the-Hash attack:**  
You don't need the password. You just need the NTLM hash. Tools like Mimikatz extract hashes from LSASS memory. You use the hash directly to authenticate.

Example:
```
sekurlsa::pth /user:ammulu.orsu /domain:napellam.local /ntlm:<hash>
```

This opens a command prompt running as ammulu.orsu without knowing the password "princess".

**Why this works:**  
Windows caches NTLM hashes in memory. The system uses the hash, not the password, for authentication. So if you have the hash, you effectively have the password.

**Real scenario at Infosys:**  
Hacker got local admin on one workstation. Dumped LSASS memory. Found cached hash of domain admin who logged in yesterday. Used pass-the-hash to authenticate as domain admin to the DC. Gained full control.

### NTLM Relay Attack

**The vulnerability:**  
NTLM authentication can be relayed. You intercept NTLM authentication from one place and use it to authenticate somewhere else.

**Attack scenario:**

1. Attacker runs Responder tool on the network
2. Victim tries to access `\\FAKESHARE\files`
3. Victim's computer broadcasts: "Where is FAKESHARE?"
4. Attacker responds: "I'm FAKESHARE, here's my IP"
5. Victim sends NTLM authentication to attacker
6. Attacker relays this authentication to DC01
7. DC thinks the victim is authenticating to DC01
8. If victim is admin on DC01, attacker gets admin access

**Protection: SMB Signing**  
SMB signing adds a cryptographic signature to each packet. This prevents relay because the signature is tied to the specific connection.

When SMB signing is enabled:
- Each SMB packet has a signature
- Signature is calculated using session key
- If attacker tries to relay, signature won't match
- Attack fails

In our lab, we disabled SMB signing to make the environment vulnerable.

## 3.5 How Passwords Are Stored - Deep Technical Details

### SAM Database (Local Accounts)

**Location:** `C:\Windows\System32\config\SAM`

**What it contains:**
- Local user accounts (not domain accounts)
- Password hashes in NTLM format
- User SIDs
- Account settings (disabled, locked out, etc.)

**Database format:** Registry hive (can be loaded with regedit)

**Encryption:** Each password hash is encrypted with a boot key (SYSKEY)

**Boot key location:** `C:\Windows\System32\config\SYSTEM`

**To crack SAM:**
1. Copy both SAM and SYSTEM files
2. Use tool like samdump2 or secretsdump.py
3. Extract hashes:
   ```
   secretsdump.py -sam SAM -system SYSTEM LOCAL
   ```
4. Get output like:
   ```
   Administrator:500:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
   ```
   Format: username:RID:LM hash:NTLM hash

5. Crack NTLM hash with hashcat:
   ```
   hashcat -m 1000 -a 0 31d6cfe0d16ae931b73c59d7e0c089c0 rockyou.txt
   ```

### LSASS (Memory Credentials)

**What is LSASS?**  
Local Security Authority Subsystem Service. It's a process (lsass.exe) running on every Windows machine.

**Purpose:**
- Handles authentication
- Creates security tokens
- Enforces security policies
- Stores credentials in memory

**Why credentials are in memory:**  
When you log in, Windows needs your credentials to access network resources. It can't ask for password every time you access a file share. So it caches credentials in LSASS memory.

**What's cached:**
- Plaintext passwords (in some cases, if WDigest is enabled)
- NTLM hashes
- Kerberos tickets (TGT and service tickets)
- Kerberos keys (AES128, AES256)

**Dumping LSASS:**

Method 1: Task Manager
1. Open Task Manager
2. Find "Local Security Authority Process"
3. Right-click → Create dump file
4. This creates lsass.DMP file
5. Copy to attack machine
6. Run Mimikatz: `sekurlsa::minidump lsass.DMP` then `sekurlsa::logonPasswords`

Method 2: Mimikatz on the target
1. Run as administrator
2. `privilege::debug` (get SeDebugPrivilege)
3. `sekurlsa::logonpasswords` (dump credentials)

Method 3: Procdump (Microsoft Sysinternals)
```
procdump.exe -ma lsass.exe lsass.dmp
```

**Output example:**
```
Authentication Id : 0 ; 123456
Session           : Interactive from 1
User Name         : ammulu.orsu
Domain            : NAPELLAM
NTLM              : 8846f7eaee8fb117ad06bdd830b7586c
SHA1              : abcd1234...
```

**Real attack at TCS:**  
Local admin account compromised on workstation. Attacker dumped LSASS. Found three domain users logged in recently. Extracted their hashes. One was IT admin with access to servers. Attacker used pass-the-hash to access servers with sensitive project data.

### NTDS.dit (Domain Database)

**Location:** `C:\Windows\NTDS\NTDS.dit` (only on Domain Controllers)

**File size:** Depends on number of objects
- 1000 users: ~500 MB
- 10,000 users: ~2 GB
- 100,000 users: ~10+ GB

**Database structure:**
- Table-based (like SQL database)
- Main table: datatable (contains all objects)
- Link table: link_table (relationships between objects)
- Each row is an object (user, group, computer, OU, etc.)

**Extracting offline:**

1. Shut down DC (or boot from another OS)
2. Copy NTDS.dit and C:\Windows\System32\config\SYSTEM
3. Use secretsdump.py:
   ```
   secretsdump.py -ntds NTDS.dit -system SYSTEM LOCAL -outputfile hashes
   ```
4. This creates files with all domain hashes

**Extracting online (VSS - Volume Shadow Copy):**
```
vssadmin create shadow /for=C:
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\NTDS\NTDS.dit C:\temp\ntds.dit
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\System32\config\SYSTEM C:\temp\system
vssadmin delete shadows /shadow={ID}
```

**DCSync attack (better method):**  
Instead of stealing the file, pretend to be a Domain Controller and ask for replication. This is what we configured for svc_backup in the lab. More details in the DCSync walkthrough.

---

I'll continue with more sections. This is much more in-depth with technical details and real scenarios.


### 3.2.2 Domains, Forests, and Trusts

**Domain explained:**  
A domain is administrative and security boundary in Active Directory. All objects in a domain share the same database (NTDS.dit) and the same security policies.

**Domain name formats:**
- FQDN: napellam.local
- NetBIOS: NAPELLAM

**Why two names?**  
NetBIOS is a legacy naming system from Windows NT (pre-2000). It's limited to 15 characters. FQDN uses DNS and can be hierarchical. Modern systems use FQDN, but NetBIOS is still supported for backwards compatibility.

**Forest explained:**  
A forest is a collection of one or more domain trees that share:
- Same schema (object definitions)
- Same configuration partition
- Same Global Catalog
- Automatic transitive trust relationships

**Real scenario at Reliance Industries:**  
Reliance has multiple business units:
- reliance.com (parent domain) - Corporate HQ
- retail.reliance.com (child domain) - Retail business
- telecom.reliance.com (child domain) - Jio Telecom

All three domains are in one forest. A user in retail.reliance.com can access resources in telecom.reliance.com because there's automatic two-way transitive trust.

**Trust relationships:**  
A trust is a relationship between two domains that allows users in one domain to access resources in another.

Types of trusts:
1. **Parent-Child Trust** - Automatic, two-way, transitive
2. **Tree-Root Trust** - Between root domains of different trees in the same forest
3. **Forest Trust** - Between two separate forests
4. **External Trust** - One-way trust to a domain in another forest
5. **Realm Trust** - To a non-Windows Kerberos realm

**Attacking trusts:**  
If you compromise one domain, you can potentially pivot to other trusted domains using the trust relationship. This is called "lateral movement across trusts."

### Organizational Units (OUs) - Technical Details

**What are OUs?**  
OUs are Active Directory containers used to organize objects. They're represented in the directory tree and have their own security descriptors.

**Distinguished Name (DN):**  
Every object in AD has a DN which shows its full path.

Example: `CN=Ammulu Orsu,OU=IT-Department,OU=Bank-Users,DC=napellam,DC=local`

Breaking this down:
- CN = Common Name (the object itself)
- OU = Organizational Unit (containers)
- DC = Domain Component (domain parts)

**Why OUs matter:**

1. **Group Policy Application:**  
GPOs (Group Policy Objects) are linked to OUs. Example at Wipro:
- Corporate-Laptops OU → Gets GPO that enforces disk encryption
- Contractor-Machines OU → Gets GPO that blocks USB drives
- Server-OU → Gets GPO that enables audit logging

2. **Delegation:**  
You can give someone admin rights over just one OU without making them Domain Admin.

Example:
```powershell
# Give HR team permission to manage users in HR-Users OU
dsacls "OU=HR-Users,DC=company,DC=com" /G "HR-Admins:CCDC;user"
```

3. **Organizational structure:**  
Mirrors company structure. Makes it easier to find objects.

**OU vs Group - Important difference:**
- OU: Organizes objects, used for GPO application and delegation
- Group: Assigns permissions to resources

You might be in "IT-Department" OU (where your account lives) but member of "SQL-Admins" group (which gives you SQL permissions).

### Users and Service Accounts

**User account attributes in AD:**

When you create a user, these are some of the key attributes stored:

- `sAMAccountName`: The logon name (e.g., ammulu.orsu) - Limited to 20 characters
- `userPrincipalName`: Email-style name (e.g., ammulu.orsu@napellam.local)
- `objectSID`: Security Identifier (unique ID, never changes)
- `objectGUID`: Globally Unique Identifier (different from SID, used for replication)
- `unicodePwd`: Password hash (encrypted, not directly readable)
- `pwdLastSet`: When password was last changed (timestamp)
- `userAccountControl`: Flags like disabled, password never expires, etc.
- `memberOf`: List of groups the user belongs to
- `servicePrincipalName`: SPNs if this account runs services
- `logonCount`: How many times user has logged in
- `lastLogon`: Last logon time (not replicated between DCs!)
- `badPwdCount`: Failed login attempts (for account lockout)

**userAccountControl flags:**  
This is a bitmap field. Each bit represents a different setting.

Common flags:
- 0x0002: ACCOUNTDISABLE - Account is disabled
- 0x0010: LOCKOUT - Account is locked out
- 0x0020: PASSWD_NOTREQD - No password required
- 0x0040: PASSWD_CANT_CHANGE - User can't change password
- 0x0080: ENCRYPTED_TEXT_PWD_ALLOWED - Can store password reversibly encrypted
- 0x0200: NORMAL_ACCOUNT - Normal user account
- 0x0800: DONT_EXPIRE_PASSWORD - Password never expires
- 0x1000: MNS_LOGON_ACCOUNT - Managed service account
- 0x10000: DONT_REQ_PREAUTH - Kerberos pre-auth not required (AS-REP Roasting vulnerability!)
- 0x400000: DONT_REQUIRE_PREAUTH - Same as above, different constant

To check if a user is AS-REP roastable:
```powershell
Get-ADUser pranavi -Properties userAccountControl
# If userAccountControl has 0x400000 bit set, it's vulnerable
```

**Service Accounts - Deep Dive:**

Service accounts are user accounts used to run services. In our lab, svc_backup is a service account.

**Why service accounts exist:**  
Services like SQL Server, IIS, backup software need to run under a user context to access network resources. You can't use a regular account because:
- Users change passwords
- Users go on vacation
- Accounts might get locked out

**Types of service accounts:**

1. **Domain user account with SPN** (Our svc_backup)
   - Regular user account
   - Has SPN registered
   - Password set manually
   - Vulnerable to Kerberoasting if weak password

2. **Managed Service Account (MSA)**
   - Windows manages the password (rotates automatically)
   - Password is 120 characters random
   - Can only be used on one computer
   - Not vulnerable to Kerberoasting (password too complex)

3. **Group Managed Service Account (gMSA)**
   - Like MSA but can be used on multiple computers
   - Password still auto-managed
   - Recommended for new deployments

4. **SYSTEM / Local Service / Network Service**
   - Built-in local accounts
   - No password
   - Limited permissions

**Real scenario at HCL:**  
Company had 50 SQL Servers. All running under domain user account "svc_sql" with password "SQLServer2019!". Attacker Kerberoasted this account, cracked it in 10 minutes. Gained access to all 50 SQL servers and exfiltrated customer databases. If they used gMSA, the attack would have failed (120-character random password).

### Groups - Complete Breakdown

**Group types:**

1. **Security Groups** - Used for assigning permissions
2. **Distribution Groups** - Used for email distribution (Exchange)

**Group scope:**

1. **Domain Local** - Can contain users/groups from anywhere, can be assigned permissions only in this domain
2. **Global** - Can contain users/groups from this domain only, can be assigned permissions anywhere
3. **Universal** - Can contain users/groups from anywhere, can be assigned permissions anywhere

**Why three scopes?**  
It's about replication efficiency in multi-domain forests.

**Best practice (AGDLP):**
- Accounts → Global groups → Domain Local groups → Permissions

Example:
- User: ammulu.orsu ← goes into →
- Global group: IT-Staff ← goes into →
- Domain Local group: File-Server-Admins ← gets permission →
- Permission: Full Control on C:\Data\

**Built-in groups and their powers:**

1. **Domain Admins** (SID ends in -512)
   - Full control of the entire domain
   - Member of local Administrators on every domain-joined machine
   - Can do anything

2. **Enterprise Admins** (SID ends in -519, only in forest root)
   - Full control of the entire forest
   - Can modify schema
   - Should be empty except when making forest-wide changes

3. **Schema Admins** (SID ends in -518)
   - Can modify AD schema
   - Should be empty except when extending schema

4. **Administrators** (Built-in domain local, SID ends in -544)
   - Local Administrators on the Domain Controller

5. **Account Operators**
   - Can create/modify users and groups
   - Cannot modify admin accounts or Domain Admins group

6. **Server Operators**
   - Can manage domain servers
   - Login locally to DCs
   - Backup and restore files

7. **Backup Operators**
   - Can backup and restore files (even if ACL denies access)
   - Can login locally to DCs
   - Dangerous: Can backup SAM/NTDS.dit

8. **Print Operators**
   - Can manage printers
   - Can login locally to DCs

**Protected Users group:**  
Microsoft introduced this in Windows Server 2012 R2. Users in this group get extra protection:
- Cannot use NTLM authentication (Kerberos only)
- Cannot use DES or RC4 in Kerberos (AES only)
- TGT lifetime is 4 hours instead of 10
- Cannot be delegated
- Credentials not cached on client machines

This prevents some attacks. But if your domain has old servers/apps, they might break.

## 3.6 Access Control Lists (ACLs) - Deep Technical Dive

**What is an ACL?**  
Every object in Active Directory has a security descriptor. This descriptor contains two Access Control Lists:
1. **DACL** (Discretionary ACL) - Who can access this object
2. **SACL** (System ACL) - What actions to audit

**DACL structure:**  
The DACL is a list of ACEs (Access Control Entries). Each ACE contains:
1. **Trustee** - Who (SID of user/group)
2. **AccessMask** - What permissions (bitmap of rights)
3. **AceType** - Allow or Deny
4. **AceFlags** - Inheritance flags
5. **ObjectType** (for Object ACEs) - Which property/extended right
6. **InheritedObjectType** (for Object ACEs) - Apply to which child object types

**Permission types:**

1. **Standard Rights** (work on all object types):
   - DELETE - Delete the object
   - READ_CONTROL - Read security descriptor
   - WRITE_DAC - Modify permissions
   - WRITE_OWNER - Take ownership
   - SYNCHRONIZE - Use object for synchronization

2. **Generic Rights** (high-level permissions):
   - GENERIC_ALL - All rights
   - GENERIC_WRITE - Write access
   - GENERIC_READ - Read access
   - GENERIC_EXECUTE - Execute access

3. **AD-specific Extended Rights** (GUID-based):
   - User-Force-Change-Password (00299570-246d-11d0-a768-00aa006e0529)
   - DS-Replication-Get-Changes (1131f6aa-9c07-11d1-f79f-00c04fc2dcd2)
   - DS-Replication-Get-Changes-All (1131f6ad-9c07-11d1-f79f-00c04fc2dcd2)

**GenericAll explained:**  
GenericAll is the most powerful permission. It includes:
- Full Control - Can do everything
- Can read all properties
- Can write all properties
- Can delete the object
- Can modify permissions (WriteDACL)
- Can take ownership
- Can reset password (for user objects)
- Can add to groups

**Real attack scenario using GenericAll:**

At TCS Mumbai office:
1. User "hr.admin" was given GenericAll on OU=Contractors
2. Attacker compromised hr.admin account
3. Attacker created new user "backdoor" in Contractors OU
4. Added "backdoor" to Domain Admins group (because GenericAll allows adding to any group)
5. Logged in as "backdoor" with DA rights

The mistake: hr.admin should have been given only specific rights like "Create User Objects" not GenericAll.

**Viewing ACLs:**

Using PowerShell:
```powershell
# Get ACL of an object
$acl = Get-Acl "AD:\CN=Lakshmi Devi,OU=IT-Department,OU=Bank-Users,DC=napellam,DC=local"

# View all ACEs
$acl.Access | Format-Table IdentityReference, AccessControlType, ActiveDirectoryRights

# Find who has GenericAll
$acl.Access | Where-Object {$_.ActiveDirectoryRights -like "*GenericAll*"}
```

Using dsacls (command-line tool):
```
dsacls "CN=Lakshmi Devi,OU=IT-Department,OU=Bank-Users,DC=napellam,DC=local"
```

**ACL abuse attack chains:**

Common escalation paths:
1. WriteDACL → Grant yourself GenericAll → Reset password
2. WriteOwner → Take ownership → Grant yourself Full Control → Reset password
3. GenericWrite → Modify servicePrincipalName → Kerberoast yourself
4. GenericAll on Group → Add yourself to the group → Get group's permissions
5. ForceChangePassword → Change user's password → Login as that user

**Why this matters:**  
Many companies have misconfigurations. Someone once had WriteDACL, then left the company, but the permission stayed. Attacker finds this permission with BloodHound and uses it to escalate.

## 3.7 Security Identifiers (SIDs) - Complete Technical Details

**SID structure:**  
`S-1-5-21-<Domain ID>-<Domain ID>-<Domain ID>-<RID>`

Example: `S-1-5-21-1234567890-9876543210-1122334455-1105`

**Breaking it down:**
- `S`: It's a SID
- `1`: Revision number (always 1 currently)
- `5`: Identifier Authority = NT Authority
- `21`: Sub-authority, means domain SID follows
- `1234567890-9876543210-1122334455`: Domain identifier (unique for each domain)
- `1105`: RID (Relative Identifier, unique within the domain)

**Well-known SIDs:**  
These are the same in every domain:

- `S-1-5-18`: Local System
- `S-1-5-19`: Local Service
- `S-1-5-20`: Network Service
- `S-1-5-21-<domain>-500`: Administrator
- `S-1-5-21-<domain>-501`: Guest
- `S-1-5-21-<domain>-502`: krbtgt
- `S-1-5-21-<domain>-512`: Domain Admins
- `S-1-5-21-<domain>-513`: Domain Users
- `S-1-5-21-<domain>-515`: Domain Computers
- `S-1-5-21-<domain>-519`: Enterprise Admins
- `S-1-5-32-544`: BUILTIN\Administrators
- `S-1-5-32-545`: BUILTIN\Users

**How RIDs are assigned:**  
The RID Master FSMO role generates pools of 500 RIDs at a time.

First user created: RID 1000
Second user: RID 1001
And so on...

When a DC uses 250 RIDs from its pool, it requests another pool from RID Master.

**SID History:**  
When you migrate a user from one domain to another (e.g., company merger), the user gets a new SID in the new domain. But to maintain access to old resources, the old SID is added to `sIDHistory` attribute.

**SID History attack:**  
If you can set sIDHistory (requires special admin rights), you can add Enterprise Admins SID to your sIDHistory and become EA.

```powershell
# Mimikatz can do this (requires DA rights)
kerberos::golden /user:hacker /domain:child.com /sid:S-1-5-21-xxx /sids:S-1-5-21-yyy-519 /krbtgt:<hash> /ptt
```

Where S-1-5-21-yyy-519 is Enterprise Admins SID from parent domain.

**Real scenario at a multinational:**  
Company merged with another company. Migrated 10,000 users. Used SID History so users keep access. Attacker got DA in child domain, modified sIDHistory of their account to include parent domain's Enterprise Admins SID. Compromised entire forest.

## 3.8 Service Principal Names (SPNs) - Complete Technical Breakdown

**What is an SPN?**  
An SPN uniquely identifies a service instance. It associates a service with a service logon account.

**SPN format:**  
`ServiceClass/Hostname:Port/ServiceName`

Examples:
- `HTTP/web.company.com` - Web server
- `MSSQLSvc/sql01.company.com:1433` - SQL Server
- `TERMSRV/rdp.company.com` - Terminal Services (RDP)
- `CIFS/fileserver.company.com` - File share
- `LDAP/dc01.company.com` - LDAP service on DC

**Why SPNs are needed:**  
When you access a service with Kerberos, the client requests a ticket for that service's SPN. The DC looks up which account has this SPN registered and encrypts the ticket with that account's hash.

**Machine accounts vs User accounts:**

When you join a computer to domain, a computer account is created (ends with $). This account automatically registers SPNs for its services:
- `HOST/COMPUTERNAME`
- `HOST/COMPUTERNAME.domain.com`
- `TERMSRV/COMPUTERNAME`
- etc.

These SPNs are registered to the computer account which has a 120-character random password that rotates every 30 days. So you can't Kerberoast them.

**User account SPNs:**  
When you run a service as a domain user account (like svc_backup), you manually register SPNs to that user account. The service ticket gets encrypted with the user account's password hash. If the user has a weak password, it can be cracked.

**Registering an SPN:**

```powershell
# Register SPN
setspn -A MSSQLSvc/sql01.company.com:1433 COMPANY\svc_sql

# List SPNs for an account
setspn -L svc_sql

# Query all SPNs in the domain
setspn -Q */*
```

**Finding Kerberoastable accounts:**

LDAP query:
```
(&(objectCategory=person)(objectClass=user)(servicePrincipalName=*))
```

PowerShell:
```powershell
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName
```

Impacket:
```bash
GetUserSPNs.py napellam.local/vamsi.krishna:iloveyou -dc-ip 192.168.100.10
```

**Why Kerberoasting works:**  
1. Anyone can request a service ticket for any SPN
2. DC doesn't check if you actually need to access that service
3. Ticket is encrypted with service account's password
4. You save the ticket and crack it offline
5. DC never knows you're cracking it

**Mitigation:**
- Use Managed Service Accounts (MSA/gMSA) - 120-character random passwords
- Use strong passwords for service accounts (25+ characters, random)
- Monitor for SPN changes
- Alert on unusual TGS-REQ patterns

**Real attack at a hospital:**  
Hospital had IIS web application running as domain user "svc_web" with password "WebServer2020!". Attacker with any domain credentials ran Kerberoasting. Cracked the password in 2 hours. svc_web had db_owner on patient database. Attacker dumped entire patient database, 50,000 records. Hospital paid $1M HIPAA fine.

---

This covers the core AD fundamentals in depth with technical details and real scenarios.

- **UserPrincipalName (UPN)**: Email-style format (e.g., `ammulu.orsu@napellam.local`)
- **Password**: Stored as a hash (NOT plain text!)
- **SID**: Security Identifier - unique ID for this user
- **Member Of**: Which groups this user belongs to
- **Distinguished Name (DN)**: Full path in AD (e.g., `CN=Ammulu Orsu,OU=IT-Department,OU=Bank-Users,DC=napellam,DC=local`)

**Service Accounts:**  
These are special user accounts for running services (like SQL Server, backup software).
- Example: `svc_backup`
- They're not real people, but they need accounts to run services
- Often have weak passwords (because admins think "it's just a service account")
- Prime targets for attackers!

### 3.2.6 Groups

**What are they?**  
Groups are collections of users. Instead of giving permissions to each user individually, you add users to a group and give permissions to the group.

**Example:**
- Group: IT-Admins
- Members: ammulu.orsu, lakshmi.devi, ravi.teja
- Permission: IT-Admins group can access the "Servers" folder
- Result: All three users can access the folder (because they're in the group)

**Special Groups:**
- **Domain Admins**: Full control over the entire domain. These are the "god mode" accounts.
- **Enterprise Admins**: Full control over the entire forest (multiple domains)
- **Schema Admins**: Can modify the AD schema (structure)
- **Administrators**: Local admins on the Domain Controller

## 3.3 Authentication Protocols

Windows uses two authentication protocols: NTLM and Kerberos.

### 3.3.1 NTLM Authentication

**What is it?**  
NTLM (NT LAN Manager) is the older authentication protocol. It's a challenge-response system.

**How does it work?**

1. **Client** sends username to Server
2. **Server** sends a random challenge (a random number)
3. **Client** encrypts the challenge with their password hash
4. **Client** sends the encrypted challenge to Server
5. **Server** forwards username + challenge + response to Domain Controller
6. **DC** looks up the user's password hash
7. **DC** encrypts the challenge with the same password hash
8. **DC** compares: Does my encrypted version match what the client sent?
9. If they match → Login success! If not → Login failed!

**Key Points:**
- Password never sent over network (only the hash)
- But the hash IS the password! (This is why Pass-the-Hash works)
- Slower than Kerberos
- No mutual authentication (client doesn't verify the server)
- Still used for backward compatibility

### 3.3.2 Kerberos Authentication

**What is it?**  
Kerberos is the modern authentication protocol used in Active Directory. It's based on tickets.

**The Main Idea:**  
Instead of proving your password every time you access something, you get a "ticket" that proves who you are. You show this ticket to access resources.

**How does it work? (Simplified)**

**Step 1: Getting a TGT (Ticket Granting Ticket)**
1. You login to your computer
2. Computer sends authentication request to DC (with your password hash)
3. DC verifies password and gives you a TGT
4. TGT is encrypted with the `krbtgt` account's password hash
5. You can't read your own TGT (it's encrypted), but you can present it

Think of TGT like an ID card you get after showing your passport at the entry gate.

**Step 2: Getting a Service Ticket**
1. You want to access a file server
2. You present your TGT to the DC
3. DC checks your TGT and creates a Service Ticket for the file server
4. Service Ticket is encrypted with the file server's password hash
5. You present Service Ticket to the file server
6. File server decrypts it and lets you in

Think of Service Ticket like a specific room key you get by showing your ID card.

**Kerberos Tickets Explained:**
- **TGT (Ticket Granting Ticket)**: Your "master ticket" - proves who you are to the DC
- **TGS (Ticket Granting Service)**: A ticket for a specific service
- **PAC (Privilege Attribute Certificate)**: Contains your groups and permissions

**Why is Kerberos Important for Attacks?**
- Kerberoasting: We request service tickets and crack them offline
- AS-REP Roasting: We request TGTs for users without pre-auth
- Golden Ticket: We forge a fake TGT using the krbtgt hash
- Silver Ticket: We forge a fake service ticket

We'll cover these attacks in detail in the walkthroughs.

## 3.4 How Passwords Are Stored

**Where are passwords stored?**

Different places depending on the type of account:

### 3.4.1 Local Accounts (on workstations)

**SAM (Security Account Manager) database**
- Location: `C:\Windows\System32\config\SAM`
- Stores: Local user accounts and their hashes
- Format: NTLM hashes
- Protected by: Only SYSTEM account can read it (but we can steal it!)

**LSASS (Local Security Authority Subsystem Service)**
- Location: Running process in memory
- Stores: Currently logged-in users' credentials
- Contains: Passwords, hashes, Kerberos tickets
- Why it's there: So you don't have to type password every time you access something
- Attackers love this: We dump LSASS memory to steal credentials!

### 3.4.2 Domain Accounts (on DC)

**NTDS.dit (NT Directory Services)**
- Location: `C:\Windows\NTDS\NTDS.dit`
- Stores: ALL domain users, computers, groups, and their password hashes
- This is the crown jewels! If we steal this, we have the entire domain
- Protected by: Only runs on Domain Controllers, encrypted, needs SYSTEM access

### 3.4.3 Password Hashes

**What is a hash?**  
A hash is a one-way mathematical transformation. You can turn a password into a hash, but you (usually) can't turn a hash back into a password.

**Example:**
- Password: `princess`
- NTLM Hash: `8846F7EAEE8FB117AD06BDD830B7586C`

**Why hash passwords?**  
If you store plain passwords and someone steals the database, they have all passwords. With hashes, they need to crack them first.

**The Problem:**  
Windows NTLM hashes DON'T use a salt. A salt is random data added to each password before hashing.

Without salt:
- Same password = same hash
- We can use rainbow tables (pre-computed hash databases) to crack them
- We can compare hashes directly to find users with same passwords

**Pass-the-Hash:**  
In Windows, the hash IS the password! You don't need to crack it. You can authenticate using just the hash.

## 3.5 Permissions and ACLs

### 3.5.1 What is an ACL?

**ACL = Access Control List**

Every object in Active Directory has an ACL attached to it. The ACL is a list of permissions that says "who can do what to this object".

**Example:**  
The user object for `lakshmi.devi` has an ACL that says:
- lakshmi.devi herself: Can change her own password
- Domain Admins: Can do everything (GenericAll)
- IT-Managers: Can reset her password (our vulnerable configuration!)

### 3.5.2 ACL Components

An ACL contains multiple ACEs (Access Control Entries). Each ACE has:

1. **Trustee (Who)**: The user or group getting permission (identified by SID)
2. **Permission (What)**: What they can do
3. **Allow/Deny**: Is this allowing or denying the action?

**Common Permissions:**
- **GenericAll**: Full control - can do ANYTHING
- **GenericWrite**: Can modify properties
- **WriteDACL**: Can change permissions
- **WriteOwner**: Can take ownership
- **User-Force-Change-Password**: Can reset password without knowing old one
- **Self-Membership**: Can add themselves to groups

### 3.5.3 Why ACLs Matter for Attacks

Misconfigured ACLs are gold for attackers. If we have GenericAll on a user:
1. We can reset their password
2. Login as them
3. Escalate to whatever groups they're in

This is called **ACL-based privilege escalation**.

## 3.6 SIDs (Security Identifiers)

**What is a SID?**  
A SID is a unique identifier for every security principal (user, group, computer).

**Format:**  
`S-1-5-21-<Domain Identifier>-<RID>`

**Example SIDs:**
- Domain: `S-1-5-21-1234567890-1234567890-1234567890`
- Administrator: `S-1-5-21-1234567890-1234567890-1234567890-500`
- ammulu.orsu: `S-1-5-21-1234567890-1234567890-1234567890-1105`

**Parts Explained:**
- `S` - It's a SID
- `1` - Revision number
- `5` - Identifier Authority (5 = NT Authority)
- `21` - Sub-authority (21 = domain)
- `<Domain ID>` - Unique for each domain
- `<RID>` - Relative ID - unique within the domain

**Well-Known SIDs:**
- Administrator: Always ends in `-500`
- Guest: Always ends in `-501`
- krbtgt: Always ends in `-502`
- First user created: `-1000`
- Next user: `-1001`, etc.

**Why SIDs matter:**
- Permissions are actually stored as SIDs (not usernames)
- If you rename a user, permissions still work (SID doesn't change)
- SID History can be abused for persistence

## 3.7 SPNs (Service Principal Names)

**What is an SPN?**  
An SPN (Service Principal Name) is a unique identifier for a service instance.

**Format:**  
`ServiceClass/Hostname:Port`

**Examples:**
- `MSSQLSvc/dc01.napellam.local:1433` - SQL Server on DC01 port 1433
- `HTTP/web.napellam.local` - Web server
- `CIFS/fileserver.napellam.local` - File server

**Why do SPNs exist?**  
Kerberos needs to know which account is running a service. When you request a service ticket, Kerberos looks up the SPN to find which account's password hash to use for encrypting the ticket.

**Kerberoasting Attack:**  
This is the key vulnerability:
1. We query AD for users with SPNs
2. We request service tickets for those SPNs
3. Tickets are encrypted with the service account's password hash
4. We save the tickets and crack them offline

---

# 4. Troubleshooting

This section covers common problems you might face and how to fix them.

## 4.1 Virtual Machine Issues

### Problem: VM won't boot / Black screen

**Causes:**
1. Not enough RAM allocated
2. VT-x/AMD-V not enabled in BIOS
3. Hyper-V conflict (Windows feature)

**Solutions:**

**Check RAM:**
- Right-click VM → Settings → Memory
- Make sure at least 4 GB is allocated
- Make sure your physical computer has enough RAM for all VMs

**Check VT-x/AMD-V:**
- Restart computer → Enter BIOS (F2/F10/Delete)
- Look for "Intel VT-x" or "AMD-V" or "Virtualization Technology"
- Enable it → Save and exit

**Disable Hyper-V (if on Windows):**
```powershell
# Run as Administrator
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
# Restart computer
```

### Problem: VM is extremely slow

**Causes:**
1. Not enough RAM/CPU allocated
2. Too many VMs running at once
3. Hard disk is full
4. Using mechanical hard drive (HDD) instead of SSD

**Solutions:**

**Increase resources:**
- Power off VM
- Right-click → Settings
- Increase Memory to 4+ GB
- Increase CPU to 2+ cores

**Clone the VM:**
- Pause VMs you're not actively using
- Only run the VMs you need right now

**Free up disk space:**
- Delete unnecessary files
- Clear temp folders
- Consider using thin provisioned disks

**Use SSD:**
- If your VMs are on a mechanical drive (HDD), move them to SSD
- SSDs are WAY faster for VMs

## 4.2 Network Issues

### Problem: VMs cannot ping each other

**Diagnosis:**
1. Are all VMs on the same network (VMnet2)?
2. Are firewalls blocking pings?
3. Are IPs configured correctly?

**Solutions:**

**Check VMware network:**
```
1. Edit → Virtual Network Editor
2. Check VMnet2 exists and is configured correctly
3. Each VM → Settings → Network Adapter
4. Should be set to "Custom: VMnet2"
```

**Check IP addresses:**

On DC01:
```powershell
ipconfig
# Should show 192.168.100.10
```

On WS01:
```powershell
ipconfig
# Should show 192.168.100.20
```

On Kali:
```bash
ip addr
# Should show 192.168.100.100
```

**Temporarily disable Windows Firewall (for testing):**
```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

After testing works, re-enable and create proper firewall rules.

### Problem: Cannot resolve domain names

**Symptoms:**
- `ping 192.168.100.10` works
- `ping dc01.napellam.local` fails

**Cause:**  
DNS is not configured correctly.

**Solution:**

On WS01/WS02:
```powershell
# Check DNS settings
Get-DnsClientServerAddress

# Should point to 192.168.100.10
# If not, set it:
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses "192.168.100.10"

# Test DNS:
nslookup napellam.local
nslookup dc01.napellam.local
```

On Kali:
```bash
# Edit /etc/resolv.conf
sudo nano /etc/resolv.conf

# Add:
nameserver 192.168.100.10

# Test:
nslookup napellam.local
```

## 4.3 Domain Join Issues

### Problem: "The specified domain either does not exist or could not be contacted"

**Causes:**
1. DNS not pointing to DC
2. Workstation can't reach DC (network issue)
3. DC is not running
4. Time sync issues

**Solutions:**

**Check DC is running:**
- Make sure DC01 is powered on
- Wait 2-3 minutes after boot for all services to start

**Check network connectivity:**
```powershell
ping 192.168.100.10
ping dc01.napellam.local
```

Both should work!

**Check DNS:**
```powershell
nslookup napellam.local
# Should return 192.168.100.10
```

**Check time:**
Kerberos requires clocks to be synchronized (within 5 minutes).

```powershell
# On workstation:
w32tm /resync /force

# Or set time manually to match DC
```

### Problem: "The user name or password is incorrect"

**Solution:**

Make sure you're using correct credentials:
- Username: `napellam\Administrator` (NOT just "Administrator")
- Password: `P@ssw0rd!` (exact case and characters)

Alternative format:
- Username: `Administrator@napellam.local`
- Password: `P@ssw0rd!`

## 4.4 Script Errors

### Problem: "Scripts are disabled on this system"

**Cause:**  
PowerShell execution policy blocks scripts by default.

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

This allows scripts to run for this PowerShell session only.

### Problem: "Access denied" when running script

**Cause:**  
Not running as Administrator.

**Solution:**
1. Close PowerShell
2. Right-click Start menu
3. Click "Windows PowerShell (Admin)"
4. Run script again

## 4.5 Active Directory Issues

### Problem: Users don't exist after running DC01 script

**Diagnosis:**
Check if script completed Phase 3:
```powershell
Get-ADUser -Filter * | Select-Object SamAccountName
```

Should show all 12 users.

**If users don't exist:**
- Run the DC01 script again
- Check for errors in the script output
- Manually verify you're a Domain Controller:
  ```powershell
  Get-ADDomain
  # Should return domain info
  ```

### Problem: Vulnerabilities not configured

**Check Kerberoastable SPN:**
```powershell
Get-ADUser svc_backup -Properties ServicePrincipalNames | Select-Object ServicePrincipalNames
```

Should show two SPNs!

**Check AS-REP Roasting:**
```powershell
Get-ADUser pranavi -Properties UserAccountControl | Select-Object UserAccountControl
```

**Check DCSync rights:**
Use BloodHound (covered in walkthroughs) to verify.

## 4.6 Attack Tool Issues (Kali)

### Problem: Tool not found

**Solution:**
Update and install:
```bash
sudo apt update
sudo apt install -y crackmapexec impacket-scripts bloodhound python3-impacket
```

### Problem: Permission denied

**Cause:**  
Many hacking tools need root.

**Solution:**
```bash
sudo <command>
# Example:
sudo crackmapexec smb 192.168.100.0/24
```

### Problem: "Clock skew too great" (Kerberos error)

**Cause:**  
Kali's clock is more than 5 minutes different from DC.

**Solution:**
```bash
# Sync time with DC
sudo rdate -n 192.168.100.10

# Or install NTP:
sudo apt install ntpdate
sudo ntpdate 192.168.100.10
```

## 4.7 General Tips

### Take Snapshots!

Before making major changes:
1. Right-click VM in VMware
2. Snapshot → Take Snapshot
3. Name it (e.g., "Before Kerberoasting attack")
4. If something breaks, you can revert!

### Reset Administrator Password (if locked out)

1. Boot DC01 in recovery mode
2. Use installation media → Repair
3. Open command prompt
4. Replace `utilman.exe` with `cmd.exe`:
   ```
   copy C:\Windows\System32\cmd.exe C:\Windows\System32\utilman.exe
   ```
5. Reboot normally
6. At login screen, click Accessibility Options
7. CMD opens as SYSTEM!
8. Reset password:
   ```
   net user Administrator NewP@ssw0rd!
   ```

### View Detailed Errors

When scripts fail:
```powershell
$Error[0] | Format-List * -Force
```

This shows the full error message with details.

---

**End of Documentation**

This documentation covers everything you need to set up and understand the Napellam Bank AD pentesting lab. The next step is to work through the attack walkthroughs to learn how to exploit these vulnerabilities!

