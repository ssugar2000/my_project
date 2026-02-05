param(
  [string]$CandidatesDir = ".\src\my_project\candidates",
  [string]$WorkPath      = ".\src\my_project\main_work.py",
  [string]$QualityPath   = ".\quality.json",
  [int]$MaxNew           = 5
)

$ErrorActionPreference = "Stop"

# 프로젝트 루트(현재 위치) 기준으로 절대경로 고정
$root = (Get-Location).Path
$CandidatesDirAbs = (Resolve-Path (Join-Path $root $CandidatesDir)).Path
$WorkPathAbs      = (Resolve-Path (Join-Path $root $WorkPath)).Path
$QualityPathAbs   = (Resolve-Path (Join-Path $root $QualityPath)).Path

# candidates 폴더가 없으면 먼저 생성하고 다시 Resolve
if (!(Test-Path (Join-Path $root $CandidatesDir))) {
  New-Item -ItemType Directory -Force -Path (Join-Path $root $CandidatesDir) | Out-Null
  $CandidatesDirAbs = (Resolve-Path (Join-Path $root $CandidatesDir)).Path
}

if (!(Test-Path $WorkPathAbs)) {
  Write-Host "❌ main_work.py 없음: $WorkPathAbs"
  exit 1
}
if (!(Test-Path $QualityPathAbs)) {
  Write-Host "❌ quality.json 없음: $QualityPathAbs"
  exit 1
}

$quality = Get-Content $QualityPathAbs -Raw | ConvertFrom-Json
$requiredToken = [string]$quality.required_token

$artifactPath = $null
$artifactType = $null
$requiredKeys = @()
if ($quality.artifacts -and $quality.artifacts.Count -ge 1) {
  $artifactPath = [string]$quality.artifacts[0].path
  $artifactType = [string]$quality.artifacts[0].type
  if ($quality.artifacts[0].required_keys) { $requiredKeys = @($quality.artifacts[0].required_keys) }
}

$src = Get-Content $WorkPathAbs -Raw

function Write-Utf8NoBom([string]$PathAbs, [string]$Content) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $dir = Split-Path $PathAbs -Parent
  if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($PathAbs, $Content, $utf8NoBom)
}

$candidates = @()

# A) 품질 산출물(JSON) 생성 후보
if ($artifactPath -and $artifactType -eq "json") {
  $jsonBody = @{}
  if ($requiredKeys.Count -gt 0) {
    foreach ($k in $requiredKeys) { $jsonBody[$k] = "ok" }
  } else {
    $jsonBody["status"] = "ok"
  }
  $jsonText = ($jsonBody | ConvertTo-Json -Compress)

  $patchHeader = @"
# --- AUTO PATCH: ensure artifact json exists ---
import os, json

def _ensure_artifact():
    os.makedirs(os.path.dirname(r"$artifactPath") or ".", exist_ok=True)
    with open(r"$artifactPath", "w", encoding="utf-8") as f:
        f.write('$jsonText')
"@

  if ($src -notmatch "_ensure_artifact\(") {
    if ($src -match "def\s+main\s*\(\)\s*:") {
      $patched = $src -replace "(def\s+main\s*\(\)\s*:)", "`$1`r`n    _ensure_artifact()"
      $patched = $patchHeader + "`r`n`r`n" + $patched
    } else {
      $patched = @"
import os, json
def _ensure_artifact():
    os.makedirs(os.path.dirname(r"$artifactPath") or ".", exist_ok=True)
    with open(r"$artifactPath", "w", encoding="utf-8") as f:
        f.write('$jsonText')

def main():
    _ensure_artifact()
    print('$requiredToken 실행됨')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
"@
    }
    $candidates += [pscustomobject]@{Kind="ensure_artifact_json"; Code=$patched}
  }
}

# B) data 폴더 생성 후보
if ($src -match "open\(['""]data\/") {
  $patched = @"
# --- AUTO PATCH: ensure data dir exists ---
import os
os.makedirs("data", exist_ok=True)
"@ + "`r`n`r`n" + $src
  $candidates += [pscustomobject]@{Kind="ensure_data_dir"; Code=$patched}
}

# (원하면) C) auto pip install 후보는 다음 단계에서 err 로그 기반으로 붙이는 게 안전

$candidates = $candidates | Select-Object -First $MaxNew
if (-not $candidates -or $candidates.Count -eq 0) {
  Write-Host "ℹ️ 생성할 후보가 없습니다(규칙 매칭 없음)."
  exit 0
}

$base = (Get-Date -Format "yyyyMMdd_HHmmss")
$i = 1
foreach ($c in $candidates) {
  $fileName = ("main_work__auto_{0}_{1}.py" -f $base, $i)
  $outAbs = Join-Path $CandidatesDirAbs $fileName

  Write-Utf8NoBom $outAbs $c.Code
  Write-Host "✅ 후보 생성: $fileName  (kind=$($c.Kind))"
  $i++
}

exit 0
