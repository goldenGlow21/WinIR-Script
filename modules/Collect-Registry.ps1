<#
 [Collect-Registry.ps1]
 - 사용자 및 시스템 레지스트리 아티팩트 수집 모듈
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
$regLog   = Join-Path $logDir "registry_artifacts.txt"

Add-Content -Path $regLog -Value "===== Registry & User Artefacts Collection ====="
Add-Content -Path $regLog -Value ("Timestamp: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $regLog -Value ""

# Recent Run (RunMRU)
Add-Content -Path $regLog -Value "--- RunMRU (Recent Run commands) ---"
try {
    $runMru = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
    foreach ($p in $runMru.PSObject.Properties) {
        if ($p.Name -notmatch "^PS") {
            Add-Content -Path $regLog -Value (" - " + $p.Name + " = " + $p.Value)
        }
    }
} catch {
    Add-Content -Path $regLog -Value " (not found)"
}
Add-Content -Path $regLog -Value ""

# Recent Documents
Add-Content -Path $regLog -Value "--- RecentDocs ---"
try {
    $recent = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    foreach ($p in $recent.PSObject.Properties) {
        if ($p.Name -notmatch "^PS") {
            Add-Content -Path $regLog -Value (" - " + $p.Name + " = " + $p.Value)
        }
    }
} catch {
    Add-Content -Path $regLog -Value " (not found)"
}
Add-Content -Path $regLog -Value ""

# USB Device History
Add-Content -Path $regLog -Value "--- USBSTOR (USB Device History) ---"
try {
    $usb = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    foreach ($u in $usb) {
        Add-Content -Path $regLog -Value ("Device: " + $u.PSChildName)
    }
} catch {
    Add-Content -Path $regLog -Value " (not found)"
}
Add-Content -Path $regLog -Value ""

# UserAssist Keys (Program execution history)
Add-Content -Path $regLog -Value "--- UserAssist (Program Execution History) ---"
try {
    $uaPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
    $guidKeys = Get-ChildItem $uaPath
    foreach ($g in $guidKeys) {
        $countSubKey = Join-Path $g.PSPath "Count"
        try {
            $vals = Get-ItemProperty $countSubKey
            foreach ($p in $vals.PSObject.Properties) {
                if ($p.Name -notmatch "^PS") {
                    Add-Content -Path $regLog -Value (" - " + $p.Name + " = " + $p.Value)
                }
            }
        } catch {}
    }
} catch {
    Add-Content -Path $regLog -Value " (not found)"
}
Add-Content -Path $regLog -Value ""

# Shell Folders (User paths)
Add-Content -Path $regLog -Value "--- Shell Folders ---"
try {
    $folders = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
    foreach ($p in $folders.PSObject.Properties) {
        if ($p.Name -notmatch "^PS") {
            Add-Content -Path $regLog -Value (" - " + $p.Name + " = " + $p.Value)
        }
    }
} catch {
    Add-Content -Path $regLog -Value " (not found)"
}
Add-Content -Path $regLog -Value ""

Add-Content -Path $regLog -Value "===== End of Registry Artefacts ====="
