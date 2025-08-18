<# 
 [Collect-EventLogs.ps1]
 - 주요 이벤트 로그 수집 모듈
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
$sysLogFile   = Join-Path $logDir "SystemEvents.evtx"
$appLogFile   = Join-Path $logDir "ApplicationEvents.evtx"
$secLogFile   = Join-Path $logDir "SecurityEvents.evtx"
$parsedFile   = Join-Path $logDir "SecurityHighlights.txt"

# 전체 로그 내보내기
wevtutil epl System      $sysLogFile   /ow:true
wevtutil epl Application $appLogFile   /ow:true
wevtutil epl Security    $secLogFile   /ow:true

# 특정 이벤트 ID 필터링 (4624=로그온 성공, 4625=로그온 실패, 7045=서비스 설치)
$eventIds = 4624, 4625, 7045
$maxEvents = 200

Add-Content -Path $parsedFile -Value "===== Security Event Highlights ====="
Add-Content -Path $parsedFile -Value ("Timestamp: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $parsedFile -Value ""

foreach ($id in $eventIds) {
    Add-Content -Path $parsedFile -Value ("--- Event ID " + $id + " ---")
    try {
        $events = Get-WinEvent -LogName Security -FilterHashtable @{Id=$id} -MaxEvents $maxEvents -ErrorAction Stop
        foreach ($e in $events) {
            $line = ("[" + $e.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss") + "] " + $e.Id + " | " + $e.ProviderName + " | " + $e.LevelDisplayName)
            Add-Content -Path $parsedFile -Value $line
        }
    } catch {
        Add-Content -Path $parsedFile -Value ("[X] Failed to query Event ID " + $id + " : " + $_.Exception.Message)
    }
    Add-Content -Path $parsedFile -Value ""
}

Add-Content -Path $parsedFile -Value "===== End of Security Highlights ====="
