<#
.SYNOPSIS
    Incident Response - Initial Analysis Module

.DESCRIPTION
    증거 수집 결과(collect.ps1)를 기반으로 1차 분석을 수행한다.
    - 네트워크 연결 분석 (외부 IP, 비정상 포트)
    - 프로세스/서비스 분석 (의심 프로세스 탐지)
    - 계정/권한 분석 (신규 관리자 계정 여부)
    - 자동 실행 항목 분석
    - 이벤트 로그 주요 이벤트 추출

.PARAMETER ResultDir
    결과 저장 디렉토리 경로

.PARAMETER ToolsPath
    외부 툴(Sysinternals, NirSoft 등)의 최상위 경로
#>

function Invoke-Analyze {
    param(
        [Parameter(Mandatory=$true)][string]$ResultDir,
        [string]$ToolsPath = ""
    )

    Write-Host "[Analyze] 1차 분석을 시작합니다..."

    $collectDir = Join-Path $ResultDir "collect"
    $reportPath = Join-Path $ResultDir "analyze_report.txt"

    # -----------------------------
    # 보고서 헤더
    # -----------------------------
    "==== Incident Response 1차 분석 보고서 ====" | Out-File $reportPath -Encoding UTF8
    "분석 시각: $(Get-Date)" | Out-File $reportPath -Append
    "결과 디렉토리: $collectDir" | Out-File $reportPath -Append
    "`n" | Out-File $reportPath -Append

    # -----------------------------
    # 네트워크 연결 분석
    # -----------------------------
    $volatileLog = Join-Path $collectDir "volatile.log"
    if (Test-Path $volatileLog) {
        "==== 네트워크 연결 분석 ====" | Out-File $reportPath -Append
        $netstatLines = Select-String -Path $volatileLog -Pattern "TCP|UDP"
        foreach ($line in $netstatLines) {
            if ($line.ToString() -match ":\d{4,}") {
                $parts = $line.ToString().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
                $proto = $parts[0]
                $local = $parts[1]
                $remote = $parts[2]
                $state = $parts[3]
                $pid   = $parts[-1]
                if ($remote -notmatch "^(127\.|0\.0\.0\.0|::1)") {
                    "$proto $local -> $remote [$state] (PID=$pid)" | Out-File $reportPath -Append
                }
            }
        }
        "`n" | Out-File $reportPath -Append
    }

    # -----------------------------
    # 프로세스 분석
    # -----------------------------
    if (Test-Path $volatileLog) {
        "==== 프로세스 분석 ====" | Out-File $reportPath -Append
        $procLines = Select-String -Path $volatileLog -Pattern "exe"
        foreach ($line in $procLines) {
            if ($line.ToString() -match "cmd.exe|powershell.exe|wscript.exe|cscript.exe|wmic.exe|bitsadmin.exe") {
                "[의심] $($line.ToString())" | Out-File $reportPath -Append
            }
        }
        "`n" | Out-File $reportPath -Append
    }

    # -----------------------------
    # 계정/권한 분석
    # -----------------------------
    $nonVolatileLog = Join-Path $collectDir "nonvolatile.log"
    if (Test-Path $nonVolatileLog) {
        "==== 계정 및 권한 분석 ====" | Out-File $reportPath -Append
        $adminLines = Select-String -Path $nonVolatileLog -Pattern "Administrators"
        foreach ($line in $adminLines) {
            if ($line.ToString() -match "Guest|Temp|Test") {
                "[의심] 관리자 그룹에 비정상 계정 포함: $($line.ToString())" | Out-File $reportPath -Append
            }
        }
        "`n" | Out-File $reportPath -Append
    }

    # -----------------------------
    # 자동 실행 항목 분석
    # -----------------------------
    if (Test-Path $nonVolatileLog) {
        "==== 자동 실행 프로그램 분석 ====" | Out-File $reportPath -Append
        $autorunLines = Select-String -Path $nonVolatileLog -Pattern "Run"
        foreach ($line in $autorunLines) {
            if ($line.ToString() -match "AppData|Temp|\.vbs|\.js|\.bat") {
                "[의심] 비정상 자동 실행 항목: $($line.ToString())" | Out-File $reportPath -Append
            }
        }
        "`n" | Out-File $reportPath -Append
    }

    # -----------------------------
    # 이벤트 로그 분석 (간단)
    # -----------------------------
    $logDir = Join-Path $collectDir "logs"
    if (Test-Path (Join-Path $logDir "Security.evtx")) {
        "==== 이벤트 로그 분석 ====" | Out-File $reportPath -Append
        # 최근 보안 이벤트 20개 출력 (간단 요약)
        wevtutil qe Security /c:20 /rd:true /f:text | Out-File $reportPath -Append
        "`n" | Out-File $reportPath -Append
    }

    Write-Host "[Analyze] 1차 분석 완료. 보고서 경로: $reportPath"
}

