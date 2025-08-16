<#
.SYNOPSIS
    Incident Response - Utility Functions

.DESCRIPTION
    공통적으로 사용되는 유틸리티 함수 모음.
    - 로그 기록
    - 디렉토리/파일 경로 처리
    - 오류 핸들링
#>

# --------------------------------------------------------------------
# 로그 기록 함수
# --------------------------------------------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [string]$LogFile = ""
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"

    # 콘솔 출력
    Write-Host $line

    # 로그 파일 기록
    if ($LogFile -ne "") {
        Add-Content -Path $LogFile -Value $line
    }
}

# --------------------------------------------------------------------
# 디렉토리 보장 생성 함수
# --------------------------------------------------------------------
function Ensure-Directory {
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    if (-not (Test-Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        catch {
            Write-Host "[!] 디렉토리 생성 실패: $Path"
            throw
        }
    }
    return $Path
}

# --------------------------------------------------------------------
# 안전한 파일 실행 함수
# --------------------------------------------------------------------
function Invoke-ExternalTool {
    param(
        [Parameter(Mandatory=$true)][string]$CommandPath,
        [string[]]$Arguments,
        [string]$OutputFile = ""
    )

    if (Test-Path $CommandPath) {
        try {
            if ($OutputFile -ne "") {
                & $CommandPath @Arguments 2>&1 | Out-File $OutputFile -Encoding UTF8
            } else {
                & $CommandPath @Arguments
            }
        }
        catch {
            Write-Host "[!] 실행 중 오류 발생: $CommandPath"
        }
    } else {
        Write-Host "[!] 외부 툴을 찾을 수 없음: $CommandPath"
    }
}

# --------------------------------------------------------------------
# JSON 설정 파일 로드 함수
# --------------------------------------------------------------------
function Load-Settings {
    param(
        [string]$ConfigFile = ""
    )

    if ($ConfigFile -eq "") {
        $ConfigFile = Join-Path $PSScriptRoot "..\config\settings.json"
    }

    if (Test-Path $ConfigFile) {
        try {
            $json = Get-Content $ConfigFile -Raw | ConvertFrom-Json
            return $json
        }
        catch {
            Write-Host "[!] 설정 파일 로드 실패: $ConfigFile"
            return $null
        }
    } else {
        Write-Host "[!] 설정 파일을 찾을 수 없음: $ConfigFile"
        return $null
    }
}

