<#
.SYNOPSIS
    Incident Response - Hash Utility Module

.DESCRIPTION
    파일의 무결성을 보장하기 위해 SHA256 해시를 계산하고 검증하는 기능을 제공한다.
#>

# --------------------------------------------------------------------
# SHA256 해시 계산
# --------------------------------------------------------------------
function Get-FileHash-SHA256 {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "[!] 파일을 찾을 수 없습니다: $FilePath"
        return $null
    }

    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        return $hash.Hash
    }
    catch {
        Write-Host "[!] 해시 계산 중 오류 발생: $FilePath"
        return $null
    }
}

# --------------------------------------------------------------------
# SHA256 해시 검증
# --------------------------------------------------------------------
function Verify-FileHash-SHA256 {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string]$ExpectedHash
    )

    $actualHash = Get-FileHash-SHA256 -FilePath $FilePath

    if ($actualHash -eq $null) {
        return $false
    }

    if ($actualHash.ToLower() -eq $ExpectedHash.ToLower()) {
        Write-Host "[OK] 해시 검증 성공: $FilePath"
        return $true
    } else {
        Write-Host "[X] 해시 불일치: $FilePath"
        Write-Host "    기대값: $ExpectedHash"
        Write-Host "    실제값: $actualHash"
        return $false
    }
}

