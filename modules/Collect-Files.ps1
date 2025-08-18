<#
 [Collect-Files.ps1]
 - 파일 기반 아티팩트 수집 모듈
 - 관리자 권한 전제
 - param으로 OutputDir 전달받아, 그 하위 logs/ 와 artifacts/ 에 저장
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 출력 경로 준비
$logDir   = Join-Path -Path $OutputDir -ChildPath "logs"
$artDir   = Join-Path -Path $OutputDir -ChildPath "artifacts"
$fileLog  = Join-Path $logDir "file_triage.txt"

Add-Content -Path $fileLog -Value "===== File Triage & Hashing ====="
Add-Content -Path $fileLog -Value ("Timestamp: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Content -Path $fileLog -Value ""

# 조사 대상 경로
$targets = @(
    "$env:TEMP",
    "$env:WINDIR\Temp",
    "$env:USERPROFILE\Downloads",
    "$env:APPDATA",
    "$env:LOCALAPPDATA"
)

foreach ($t in $targets) {
    Add-Content -Path $fileLog -Value ("--- Scanning: " + $t)
    if (-not (Test-Path $t)) {
        Add-Content -Path $fileLog -Value " (path not found)"
        continue
    }

    try {
        $files = Get-ChildItem -Path $t -Recurse -File -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -First 20
        foreach ($f in $files) {
            try {
                $md5    = (Get-FileHash -Path $f.FullName -Algorithm MD5).Hash
                $sha256 = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
                $line = ("File=" + $f.FullName + " | Size=" + $f.Length + " | LastWrite=" + $f.LastWriteTime + " | MD5=" + $md5 + " | SHA256=" + $sha256)
                Add-Content -Path $fileLog -Value $line

                # 사본 저장 (artifacts/ 하위에 복사)
                $dest = Join-Path $artDir ($f.Name)
                Copy-Item -Path $f.FullName -Destination $dest -ErrorAction SilentlyContinue -Force
            } catch {
                Add-Content -Path $fileLog -Value ("[X] Failed hashing/copy: " + $f.FullName)
            }
        }
    } catch {
        Add-Content -Path $fileLog -Value ("[X] Failed to scan: " + $t + " | " + $_.Exception.Message)
    }
    Add-Content -Path $fileLog -Value ""
}

Add-Content -Path $fileLog -Value "===== End of File Triage ====="
