<#
.SYNOPSIS
    Windows Incident Response Main Script

.DESCRIPTION
    이 스크립트는 설정 파일(config/settings.json)을 불러와
    모듈(collect, hashtools, analyze, compress)을 실행하는
    메인 드라이버 역할을 한다.
#>

# -----------------------------
# 초기 설정
# -----------------------------
$ErrorActionPreference = "Stop"

# 스크립트 위치 기준 경로 설정
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptRoot

# 모듈 경로 로드
Import-Module "$ScriptRoot/modules/collect.ps1"   -Force
Import-Module "$ScriptRoot/modules/analyze.ps1"   -Force
Import-Module "$ScriptRoot/modules/utils.ps1"     -Force
Import-Module "$ScriptRoot/modules/hashtools.ps1" -Force
Import-Module "$ScriptRoot/modules/compress.ps1"  -Force

# -----------------------------
# 설정 파일 불러오기
# -----------------------------
$configPath = "$ScriptRoot/config/settings.json"
if (-Not (Test-Path $configPath)) {
    Write-Error "설정 파일(config/settings.json)을 찾을 수 없습니다."
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

# -----------------------------
# 결과 디렉토리 생성
# -----------------------------
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$resultDir = Join-Path $ScriptRoot $config.ResultDir
$resultDir = Join-Path $resultDir $timestamp

New-Item -ItemType Directory -Path $resultDir | Out-Null

Write-Host "[Main] 결과 저장 경로: $resultDir"

# -----------------------------
# 증거 수집 단계
# -----------------------------
if ($config.Collection.EnableVolatile -or $config.Collection.EnableNonVolatile) {
    Invoke-Collect -ResultDir $resultDir -ToolsPath $config.ToolsPath.Sysinternals
}

# -----------------------------
# 해시 계산 및 검증 단계
# -----------------------------
if ($config.Hash.Algorithms.Count -gt 0) {
    Invoke-HashTools -TargetDir $resultDir -Algorithms $config.Hash.Algorithms

    if ($config.Hash.VerifyAfterCollection) {
        Invoke-HashVerify -TargetDir $resultDir
    }
}

# -----------------------------
# 1차 분석 단계
# -----------------------------
Invoke-Analyze -ResultDir $resultDir

# -----------------------------
# 결과 압축 단계
# -----------------------------
if ($config.Compression.Enable -eq $true) {
    Invoke-Compress -TargetDir $resultDir -Format $config.Compression.Format
}

Write-Host "[Main] 작업이 완료되었습니다."

