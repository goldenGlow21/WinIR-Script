<# 
 [Collect-SystemInfo.ps1]
 - 시스템 기본 정보 수집 모듈
 - 관리자 권한 전제
 - param으로 OutputDir 전달받아, 그 하위 logs/ 에 저장
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 출력 경로 준비
$logFile = Join-Path -Path (Join-Path $OutputDir "logs") -ChildPath "systeminfo.txt"

# 수집 시작
Add-Content -Path $logFile -Value "===== System Information Collection ====="
Add-Content -Path $logFile -Value ("Timestamp: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $logFile -Value ""

# OS, Host, Uptime
$os = Get-CimInstance Win32_OperatingSystem
Add-Content -Path $logFile -Value ("OS: " + $os.Caption + " " + $os.Version)
Add-Content -Path $logFile -Value ("Build: " + $os.BuildNumber)
Add-Content -Path $logFile -Value ("Hostname: " + $env:COMPUTERNAME)
Add-Content -Path $logFile -Value ("User: " + $env:USERNAME)
Add-Content -Path $logFile -Value ("BootTime: " + $os.LastBootUpTime)
Add-Content -Path $logFile -Value ""

# Hardware Info
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$mem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
Add-Content -Path $logFile -Value ("CPU: " + $cpu.Name)
Add-Content -Path $logFile -Value ("Cores: " + $cpu.NumberOfCores + " | Logical: " + $cpu.NumberOfLogicalProcessors)
Add-Content -Path $logFile -Value ("Memory(GB): " + $mem)
Add-Content -Path $logFile -Value ""

# Network Config
$nets = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -notmatch '^169\.254\.'}
if ($nets) {
    Add-Content -Path $logFile -Value "Network Interfaces:"
    foreach ($n in $nets) {
        Add-Content -Path $logFile -Value (" - " + $n.InterfaceAlias + " : " + $n.IPAddress)
    }
    Add-Content -Path $logFile -Value ""
}

# Installed Hotfixes
$hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending
Add-Content -Path $logFile -Value "Installed Hotfixes (Top 10):"
$hotfixes | Select-Object -First 10 | ForEach-Object {
    Add-Content -Path $logFile -Value (" - " + $_.HotFixID + " | " + $_.InstalledOn)
}
Add-Content -Path $logFile -Value ""

# Local Users
$users = Get-LocalUser
Add-Content -Path $logFile -Value "Local Users:"
foreach ($u in $users) {
    Add-Content -Path $logFile -Value (" - " + $u.Name + " | Enabled=" + $u.Enabled)
}
Add-Content -Path $logFile -Value ""

Add-Content -Path $logFile -Value "===== End of System Information ====="
