<#
 [Collect-Persistence.ps1]
 - 지속성(Persistence) 아티팩트 수집 모듈
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
$logDir   = Join-Path -Path $OutputDir -ChildPath "logs"
$persistLog = Join-Path $logDir "persistence.txt"

Add-Content -Path $persistLog -Value "===== Persistence Artifacts Collection ====="
Add-Content -Path $persistLog -Value ("Timestamp: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $persistLog -Value ""

# Auto-run registry keys
Add-Content -Path $persistLog -Value "--- Registry Run Keys ---"
$runKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)
foreach ($rk in $runKeys) {
    Add-Content -Path $persistLog -Value ("Key: " + $rk)
    try {
        $vals = Get-ItemProperty -Path $rk -ErrorAction Stop
        foreach ($p in $vals.PSObject.Properties) {
            if ($p.Name -notmatch "^PS") {
                Add-Content -Path $persistLog -Value (" - " + $p.Name + " = " + $p.Value)
            }
        }
    } catch {
        Add-Content -Path $persistLog -Value " (not found)"
    }
    Add-Content -Path $persistLog -Value ""
}

# Scheduled tasks
Add-Content -Path $persistLog -Value "--- Scheduled Tasks ---"
try {
    $tasks = schtasks /query /fo LIST /v
    $tasks | ForEach-Object { Add-Content -Path $persistLog -Value $_ }
} catch {
    Add-Content -Path $persistLog -Value "[X] Failed to query scheduled tasks."
}
Add-Content -Path $persistLog -Value ""

# WMI Event Subscriptions
Add-Content -Path $persistLog -Value "--- WMI Event Subscriptions ---"
try {
    $filters = Get-WmiObject -Namespace root\subscription -Class __EventFilter -ErrorAction Stop
    foreach ($f in $filters) {
        Add-Content -Path $persistLog -Value ("Filter: " + $f.Name + " | Query=" + $f.Query)
    }
    $consumers = Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer -ErrorAction Stop
    foreach ($c in $consumers) {
        Add-Content -Path $persistLog -Value ("Consumer: " + $c.Name + " | Command=" + $c.CommandLineTemplate)
    }
    $bindings = Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding -ErrorAction Stop
    foreach ($b in $bindings) {
        Add-Content -Path $persistLog -Value ("Binding: " + $b.Filter + " -> " + $b.Consumer)
    }
} catch {
    Add-Content -Path $persistLog -Value "[X] Failed to query WMI persistence."
}
Add-Content -Path $persistLog -Value ""

Add-Content -Path $persistLog -Value "===== End of Persistence Collection ====="
