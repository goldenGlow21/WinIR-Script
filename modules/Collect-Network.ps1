<#
 [Collect-Network.ps1]
 - 네트워크 포렌식 아티팩트 수집 모듈
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
$logDir = Join-Path -Path $OutputDir -ChildPath "logs"
$logFile = Join-Path $logDir "network_info.txt"

Add-Content -Path $logFile -Value "===== Network Information Collection ====="
Add-Content -Path $logFile -Value ("Timestamp: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $logFile -Value ""

# Active TCP/UDP connections
Add-Content -Path $logFile -Value "--- Netstat Connections ---"
$netstat = netstat -ano
$netstat | ForEach-Object { Add-Content -Path $logFile -Value $_ }
Add-Content -Path $logFile -Value ""

# PowerShell-based TCP connections
Add-Content -Path $logFile -Value "--- Get-NetTCPConnection ---"
try {
    $tcpConns = Get-NetTCPConnection -ErrorAction Stop
    foreach ($c in $tcpConns) {
        $line = ("Local: " + $c.LocalAddress + ":" + $c.LocalPort + 
                 " | Remote: " + $c.RemoteAddress + ":" + $c.RemotePort + 
                 " | State: " + $c.State + 
                 " | PID: " + $c.OwningProcess)
        Add-Content -Path $logFile -Value $line
    }
} catch {
    Add-Content -Path $logFile -Value ("[X] Failed to run Get-NetTCPConnection: " + $_.Exception.Message)
}
Add-Content -Path $logFile -Value ""

# Firewall rules
Add-Content -Path $logFile -Value "--- Firewall Rules ---"
try {
    $fw = netsh advfirewall firewall show rule name=all
    $fw | ForEach-Object { Add-Content -Path $logFile -Value $_ }
} catch {
    Add-Content -Path $logFile -Value ("[X] Failed to query firewall rules: " + $_.Exception.Message)
}
Add-Content -Path $logFile -Value ""

# ARP table
Add-Content -Path $logFile -Value "--- ARP Table ---"
$arp = arp -a
$arp | ForEach-Object { Add-Content -Path $logFile -Value $_ }
Add-Content -Path $logFile -Value ""

# DNS cache
Add-Content -Path $logFile -Value "--- DNS Cache ---"
try {
    $dns = ipconfig /displaydns
    $dns | ForEach-Object { Add-Content -Path $logFile -Value $_ }
} catch {
    Add-Content -Path $logFile -Value "[X] Failed to query DNS cache."
}
Add-Content -Path $logFile -Value ""

# Network adapter configuration
Add-Content -Path $logFile -Value "--- IP Configuration ---"
$ipcfg = ipconfig /all
$ipcfg | ForEach-Object { Add-Content -Path $logFile -Value $_ }
Add-Content -Path $logFile -Value ""

Add-Content -Path $logFile -Value "===== End of Network Information ====="
