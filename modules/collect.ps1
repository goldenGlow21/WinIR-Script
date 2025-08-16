<#
.SYNOPSIS
    Incident Response - Evidence Collection Module

.DESCRIPTION
    Windows 시스템에서 침해사고 대응을 위해
    - 휘발성 정보 (프로세스, 네트워크, 로그인 사용자 등)
    - 비휘발성 정보 (이벤트 로그, 계정, 자동 실행, 스케줄러 등)
    를 수집한다.

.PARAMETER ResultDir
    결과 저장 디렉토리 경로

.PARAMETER ToolsPath
    외부 툴(Sysinternals, NirSoft 등)의 최상위 경로
    (PATH에 등록된 경우 생략 가능)
#>

function Invoke-Collect {
    param(
        [Parameter(Mandatory=$true)][string]$ResultDir,
        [string]$ToolsPath = ""
    )

    Write-Host "[Collect] 증거 수집을 시작합니다..."

    # 결과 저장 디렉토리 준비
    $collectDir = Join-Path $ResultDir "collect"
    New-Item -ItemType Directory -Path $collectDir | Out-Null

    # 휘발성 / 비휘발성 로그 분리 저장
    $volatileLog   = Join-Path $collectDir "volatile.log"
    $nonVolatileLog = Join-Path $collectDir "nonvolatile.log"

    # -----------------------------
    # 휘발성 정보 수집
    # -----------------------------
    Write-Host "[Collect] 휘발성 정보 수집 중..."

    {
        Write-Output "==== [시스템 시간] ===="
        Get-Date

        Write-Output "`n==== [로그인 사용자] ===="
        query user
        whoami

        Write-Output "`n==== [네트워크 연결] ===="
        netstat -ano
        ipconfig /all
        arp -a

        Write-Output "`n==== [프로세스 목록] ===="
        tasklist /V

        Write-Output "`n==== [실행 중 서비스] ===="
        sc query
    } | Out-File $volatileLog -Encoding UTF8

    # Sysinternals 도구 사용 (있을 경우)
    if ($ToolsPath -ne "") {
        $sysinternalsDir = Join-Path $ToolsPath "Sysinternals"

        $handle = Join-Path $sysinternalsDir "handle.exe"
        $listdlls = Join-Path $sysinternalsDir "listdlls.exe"

        if (Test-Path $handle) {
            & $handle /accepteula > (Join-Path $collectDir "handles.txt")
        }
        if (Test-Path $listdlls) {
            & $listdlls > (Join-Path $collectDir "dlls.txt")
        }
    }

    # -----------------------------
    # 비휘발성 정보 수집
    # -----------------------------
    Write-Host "[Collect] 비휘발성 정보 수집 중..."

    {
        Write-Output "==== [계정 정보] ===="
        net user
        net localgroup administrators

        Write-Output "`n==== [자동 실행 프로그램] ===="
        reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run"

        Write-Output "`n==== [스케줄러 작업] ===="
        schtasks /query /fo LIST /v
    } | Out-File $nonVolatileLog -Encoding UTF8

    # 이벤트 로그 백업
    $logDir = Join-Path $collectDir "logs"
    New-Item -ItemType Directory -Path $logDir | Out-Null
    wevtutil epl Security (Join-Path $logDir "Security.evtx")
    wevtutil epl System   (Join-Path $logDir "System.evtx")

    # 레지스트리 Hive 백업
    $regDir = Join-Path $collectDir "registry"
    New-Item -ItemType Directory -Path $regDir | Out-Null
    reg save HKLM\SAM     (Join-Path $regDir "sam.hiv")     /y
    reg save HKLM\SYSTEM  (Join-Path $regDir "system.hiv")  /y
    reg save HKLM\SECURITY (Join-Path $regDir "security.hiv") /y
    reg save HKLM\SOFTWARE (Join-Path $regDir "software.hiv") /y

    Write-Host "[Collect] 증거 수집 완료. 결과는 $collectDir 에 저장되었습니다."
}

