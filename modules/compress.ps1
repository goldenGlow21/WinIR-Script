<#
.SYNOPSIS
    Incident Response - Compression Module

.DESCRIPTION
    결과 디렉토리를 ZIP 파일로 압축하는 기능을 제공한다.
    이후 무결성 보장을 위해 hashtools.ps1 모듈과 함께 사용될 수 있다.
#>

# --------------------------------------------------------------------
# ZIP 파일로 압축하기
# --------------------------------------------------------------------
function Compress-Results {
    param(
        [Parameter(Mandatory=$true)][string]$SourceDir,
        [Parameter(Mandatory=$true)][string]$OutputFile
    )

    if (-not (Test-Path $SourceDir)) {
        Write-Host "[!] 압축할 디렉토리가 존재하지 않습니다: $SourceDir"
        return $null
    }

    try {
        # 기존 파일이 있다면 삭제
        if (Test-Path $OutputFile) {
            Remove-Item -Path $OutputFile -Force
        }

        # ZIP으로 압축
        Compress-Archive -Path $SourceDir -DestinationPath $OutputFile -Force
        Write-Host "[OK] 압축 완료: $OutputFile"

        return $OutputFile
    }
    catch {
        Write-Host "[!] 압축 중 오류 발생: $SourceDir"
        return $null
    }
}

