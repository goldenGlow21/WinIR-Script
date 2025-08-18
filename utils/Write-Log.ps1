<#
 [Write-Log.ps1]
 - 공통 로깅 함수 모듈
 - 모든 수집 모듈에서 dot-source 또는 Import-Module 방식으로 불러 사용
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
    <#
     .SYNOPSIS
      Write log message to console and file

     .PARAMETER Message
      Message to be logged

     .PARAMETER Level
      Log level (INFO, WARN, ERROR)

     .PARAMETER LogFile
      Target log file path
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO","WARN","ERROR")][string]$Level = "INFO",
        [Parameter(Mandatory = $true)][string]$LogFile
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] [$Level] $Message"

    # Console 출력 색상
    switch ($Level) {
        "INFO"  { Write-Host $line -ForegroundColor Cyan }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
    }

    # 파일에 기록
    try {
        Add-Content -Path $LogFile -Value $line
    } catch {
        Write-Host "[X] Failed to write log file: $LogFile" -ForegroundColor Red
    }
}
