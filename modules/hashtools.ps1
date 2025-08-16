<#
.SYNOPSIS
    Incident Response - Hash Calculation & Verification Module

.DESCRIPTION
    수집한 증거 파일에 대해 지정된 알고리즘(MD5, SHA256 등)으로 해시를 계산하고
    필요시 검증까지 수행한다.

.PARAMETER TargetDir
    해시를 계산할 대상 디렉토리 경로

.PARAMETER Algorithms
    사용할 해시 알고리즘 배열 (예: MD5, SHA256, SHA1 등)

.PARAMETER VerifyAfterCollection
    true일 경우, 동일 파일에 대해 해시를 재계산하여 검증한다
#>

function Invoke-HashTools {
    param(
        [Parameter(Mandatory=$true)][string]$TargetDir,
        [string[]]$Algorithms = @("MD5","SHA256"),
        [switch]$VerifyAfterCollection
    )

    Write-Host "[HashTools] 해시 계산을 시작합니다..."

    # 결과 저장 파일
    $hashFile = Join-Path $TargetDir "hashes.txt"

    foreach ($algo in $Algorithms) {
        Write-Host "[HashTools] 알고리즘: $algo"

        # 대상 디렉토리 내 모든 파일 해시 계산
        Get-ChildItem -Path $TargetDir -Recurse -File | ForEach-Object {
            try {
                $hash = Get-FileHash -Path $_.FullName -Algorithm $algo
                "$($hash.Path)`t$($hash.Algorithm)`t$($hash.Hash)" | Out-File -FilePath $hashFile -Append -Encoding UTF8
            } catch {
                Write-Warning "[HashTools] 해시 계산 실패: $($_.FullName)"
            }
        }
    }

    Write-Host "[HashTools] 해시 계산 완료. 결과는 $hashFile 에 저장되었습니다."

    # 검증 모드
    if ($VerifyAfterCollection) {
        Write-Host "[HashTools] 해시 검증 모드를 실행합니다..."
        foreach ($algo in $Algorithms) {
            $lines = Get-Content $hashFile | Where-Object {$_ -match "`t$algo`t"}
            foreach ($line in $lines) {
                $parts = $line -split "`t"
                $path = $parts[0]
                $origHash = $parts[2]
                if (Test-Path $path) {
                    $newHash = (Get-FileHash -Path $path -Algorithm $algo).Hash
                    if ($newHash -ne $origHash) {
                        Write-Warning "[HashTools] 해시 불일치 발견: $path ($algo)"
                    }
                } else {
                    Write-Warning "[HashTools] 파일 없음: $path"
                }
            }
        }
        Write-Host "[HashTools] 해시 검증 완료."
    }
}
