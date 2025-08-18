<#
 [main.ps1]
 - Windows-IR-Toolkit 자동 실행 런처
 - 관리자 권한 전제
 - 실행 시 모든 모듈 자동 수행
 - 모든 .txt / .evtx 결과 수집 후 ZIP 생성
#>

param(
    [string]$OutputRoot = (Join-Path -Path $PSScriptRoot -ChildPath "output")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────── 공통 로깅 불러오기 ───────────
. "$PSScriptRoot\utils\Write-Log.ps1"

function Test-Admin {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        throw "Administrator privileges are required."
    }
}

# 세션 단위로만 logs, artifacts 생성
function New-SessionFolder {
    param([string]$Root)
    $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $session = Join-Path $Root "session_$stamp"

    if (-not (Test-Path $session)) { [void](New-Item -Path $session -ItemType Directory) }
    [void](New-Item -Path (Join-Path $session "logs") -ItemType Directory)
    [void](New-Item -Path (Join-Path $session "artifacts") -ItemType Directory)

    return $session
}

function Invoke-Module {
    param(
        [Parameter(Mandatory)] [string]$ScriptName,
        [Parameter(Mandatory)] [string]$SessionDir
    )
    $modulePath = Join-Path -Path (Join-Path $PSScriptRoot "modules") -ChildPath $ScriptName
    $logFile = Join-Path $SessionDir "logs\main.log"

    if (-not (Test-Path $modulePath)) {
        Write-Log -Message "Module not found: $ScriptName" -Level ERROR -LogFile $logFile
        return
    }
    Write-Log -Message "Running $ScriptName ..." -Level INFO -LogFile $logFile
    try {
        & $modulePath -OutputDir $SessionDir
        Write-Log -Message "Completed: $ScriptName" -Level INFO -LogFile $logFile
    } catch {
        Write-Log -Message ("Failed: $ScriptName | " + $_.Exception.Message) -Level ERROR -LogFile $logFile
    }
}

# ─────────── Entry ───────────
try {
    Test-Admin
    if (-not (Test-Path $OutputRoot)) { [void](New-Item -Path $OutputRoot -ItemType Directory) }
    $sessionDir = New-SessionFolder -Root $OutputRoot
    Write-Host "[*] Output session: $sessionDir" -ForegroundColor Cyan
} catch {
    Write-Host "[X] Startup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ─────────── 모든 모듈 실행 ───────────
$modules = @(
    "Collect-SystemInfo.ps1",
    "Collect-EventLogs.ps1",
    "Collect-Network.ps1",
    "Collect-Processes.ps1",
    "Collect-Persistence.ps1",
    "Collect-Registry.ps1",
    "Collect-Files.ps1"
)

foreach ($m in $modules) {
    Invoke-Module -ScriptName $m -SessionDir $sessionDir
}

# ─────────── ZIP 압축 ───────────
try {
    $timestamp = Split-Path $sessionDir -Leaf
    $resultDir = Join-Path $PSScriptRoot "result"
    if (-not (Test-Path $resultDir)) { [void](New-Item -Path $resultDir -ItemType Directory) }

    $zipName = "Triage_$timestamp.zip"
    $zipPath = Join-Path $resultDir $zipName

    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    # logs/ 폴더 안의 모든 txt, evtx 파일 압축 (Filter 방식)
    $files  = @(Get-ChildItem -Path (Join-Path $sessionDir "logs") -Filter *.txt -File)
    $files += @(Get-ChildItem -Path (Join-Path $sessionDir "logs") -Filter *.evtx -File)

    if ($files.Count -gt 0) {
        Compress-Archive -Path $files.FullName -DestinationPath $zipPath -Force
        Write-Host "[+] Results archived: $zipPath" -ForegroundColor Green
    } else {
        Write-Host "[!] No .txt or .evtx files found to archive." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[X] Failed to create archive: $($_.Exception.Message)" -ForegroundColor Red
}