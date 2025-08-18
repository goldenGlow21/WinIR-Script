# Windows-IR-Toolkit  
Windows Incident Response (IR) Script 

Based on an administrator-privileged PowerShell script, it automatically collects key system forensic artifacts and provides the results in a compressed format.  

---

## Features  

### System Information Collection  
- OS, Hostname, Boot time, CPU, Memory, Network Interfaces, Hotfixes, Local Users  

### Event Logs Collection  
- System, Application, Security logs (EVTX export)  
- Security highlights (Event ID 4624, 4625, 7045)  

### Network Forensics Collection  
- Netstat, TCP connections, Firewall rules, ARP table, DNS cache, IP configuration  

### Processes & Services Collection  
- Running processes with path and signature  
- Installed services with status  

### Persistence Artifacts Collection  
- Auto-run registry keys, Scheduled tasks, WMI event subscriptions  

### Registry & User Artefacts Collection  
- RunMRU, RecentDocs, USBSTOR history, UserAssist, Shell folders  

### File Triage & Hashing  
- Recent files from Temp/AppData/Downloads  
- MD5 & SHA256 hash  
- Copy suspicious files into `artifacts/`  

---

## Project Structure  

```
Windows-IR-Toolkit/  
│  
├─ main.ps1                # Entry point (auto-run all modules)  
├─ README.md               # Documentation  
│  
├─ modules/                # Forensic collection modules  
│  ├─ Collect-SystemInfo.ps1  
│  ├─ Collect-EventLogs.ps1  
│  ├─ Collect-Network.ps1  
│  ├─ Collect-Processes.ps1  
│  ├─ Collect-Persistence.ps1  
│  ├─ Collect-Registry.ps1  
│  └─ Collect-Files.ps1  
│  
├─ utils/                  # Common functions  
│  └─ Write-Log.ps1  
│  
├─ output/                 # Raw collection results (per session)  
│  └─ session_YYYYMMDD_HHMMSS/  
│     ├─ logs/.txt  
│     ├─ logs/.evtx  
│     └─ artifacts/*  
│  
└─ result/                 # Compressed triage packages  
   └─ Triage_session_YYYYMMDD_HHMMSS.zip  
```

---

## Usage  

1. Run PowerShell in Administrator privilege.  
2. Temporarily relax the execution policy.

> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass  

3. Run `main.ps1`

> .\main.ps1  

---

## Workflow  

- When `main.ps1` is executed, a new session folder is created under `output/`.  
- All modules are executed sequentially, and the results are saved in `logs/` and `artifacts/`.  
- The `.txt` and `.evtx` files in `logs/` are compressed into `Triage_session_timestamp.zip` under `result/`.  

---

## Output Example  

```
output/  
└─ session_YYYYMMDD_HHMMSS/  
   ├─ logs/  
   │  ├─ systeminfo.txt  
   │  ├─ SecurityHighlights.txt  
   │  ├─ network_info.txt  
   │  ├─ processes.txt  
   │  ├─ services.txt  
   │  ├─ persistence.txt  
   │  ├─ registry_artifacts.txt  
   │  ├─ file_triage.txt  
   │  └─ SecurityEvents.evtx  
   └─ artifacts/  
      ├─ suspicious1.exe  
      └─ suspicious2.dll  
  
result/  
└─ Triage_session_20250818_153045.zip  
```

---

## Requirements  

- Windows PowerShell 5.1 or higher, or PowerShell 7 or higher  
- Must be run with administrator privileges  
- No internet connection required (all commands are executed locally)  
