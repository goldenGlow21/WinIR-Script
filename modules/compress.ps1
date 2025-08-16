<#
.SYNOPSIS
    Incident Response - Result Compression Module

.DESCRIPTION
    수집 및 분석된 결과 디렉토리를 지정된 압축 형식으로 묶는다.
    기본적으로 ZIP 포맷을 사용한다.

.PARAMETER TargetDir
    압축할 대상 디렉토리

.PARAMETER Format
    압축 형식 (현재 zip만 지원)
#>

function Invoke-Compress {
    param(
        [Parameter(Mandatory=$true)][string]$TargetDir,
        [ValidateSet("zip")]
        [string]$Format = "zip"
    )

    Write-Host "[Compress] 결과 압축을 시작합니다..."

    # 압축 파일 이름
    $parentDir = Split-Path $TargetDir -Parent
    $folderName = Split-Path $TargetDir -Leaf
    $zipPath = Join-Path $parentDir "$folderName.$Format"

    try {
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }

        # Windows 기본 cmdlet 사용
        if ($Format -eq "zip") {
            Compress-Archive -Path $TargetDir -DestinationPath $zipPath -Force
        }

        Write-Host "[Compress] 압축 완료: $zipPath"
    } catch {
        Write-Error "[Compress] 압축 실패: $_"
    }
}
