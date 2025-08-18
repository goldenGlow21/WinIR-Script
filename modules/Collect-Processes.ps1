<#
 [Collect-Processes.ps1]
 - 프로세스 및 서비스 정보 수집 모듈
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
$logDir  = Join-Path -Path $OutputDir -ChildPath "logs"
$procLog = Join-Path $logDir "processes.txt"
$svcLog  = Join-Path $logDir "services.txt"

# 프로세스 정보 수집
Add-Content -Path $procLog -Value "===== Process List ====="
Add-Content -Path $procLog -Value ("Timestamp: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $procLog -Value ""

$procs = Get-Process | Sort-Object ProcessName
foreach ($p in $procs) {
    try {
        $path = $null
        try {
            $path = (Get-Process -Id $p.Id -ErrorAction Stop).Path
        } catch {}
        $line = ("PID=" + $p.Id + " | Name=" + $p.ProcessName + " | CPU=" + $p.CPU + " | Path=" + $path)
        Add-Content -Path $procLog -Value $line

        if ($path -and (Test-Path $path)) {
            try {
                $sig = Get-AuthenticodeSignature -FilePath $path
                $sigInfo = ("   Signature: " + $sig.SignerCertificate.Subject + " | Status=" + $sig.Status)
                Add-Content -Path $procLog -Value $sigInfo
            } catch {
                Add-Content -Path $procLog -Value "   [X] Failed to get signature."
            }
        }
    } catch {
        Add-Content -Path $procLog -Value ("[X] Failed process: " + $p.Id)
    }
}
Add-Content -Path $procLog -Value ""
Add-Content -Path $procLog -Value "===== End of Process List ====="

# 서비스 정보 수집
Add-Content -Path $svcLog -Value "===== Service List ====="
Add-Content -Path $svcLog -Value ("Timestamp: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $svcLog -Value ""

$svcs = Get-Service | Sort-Object DisplayName
foreach ($s in $svcs) {
    $line = ("Name=" + $s.Name + " | DisplayName=" + $s.DisplayName + " | Status=" + $s.Status + " | StartType=" + $s.StartType)
    Add-Content -Path $svcLog -Value $line
}
Add-Content -Path $svcLog -Value ""
Add-Content -Path $svcLog -Value "===== End of Service List ====="
