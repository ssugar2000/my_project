param(
  [string]$CandidatesDir = ".\src\my_project\candidates",
  [string]$TargetPath    = ".\src\my_project\main_work.py",
  [string]$QualityPath   = ".\quality.json",
  [int]$TimeoutSec       = 15
)

$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
$py   = Join-Path $root ".\.venv\Scripts\python.exe"

if (!(Test-Path $QualityPath)) {
  Write-Host "❌ quality.json 없음: $QualityPath"
  exit 1
}

$quality = Get-Content $QualityPath -Raw | ConvertFrom-Json
$requiredToken = [string]$quality.required_token

function Reset-Artifacts {
  foreach ($a in $quality.artifacts) {
    $p = Join-Path $root ([string]$a.path)
    if (Test-Path $p) { Remove-Item $p -Force -ErrorAction SilentlyContinue }
  }
}

function Validate-Artifacts {
  $ok = $true
  $notes = @()

  foreach ($a in $quality.artifacts) {
    $rel = [string]$a.path
    $p = Join-Path $root $rel

    if (!(Test-Path $p)) {
      $ok = $false
      $notes += ("MISSING:{0}" -f $rel)
      continue
    }

    if ([string]$a.type -eq "json") {
      try {
        $obj = Get-Content $p -Raw | ConvertFrom-Json
      } catch {
        $ok = $false
        $notes += ("BAD_JSON:{0}" -f $rel)
        continue
      }

      if ($a.required_keys) {
        foreach ($k in $a.required_keys) {
          if (-not ($obj.PSObject.Properties.Name -contains [string]$k)) {
            $ok = $false
            $notes += ("MISSING_KEY:{0}:{1}" -f $rel, $k)
          }
        }
      }
    }
  }

  return @{ Ok=$ok; Notes=($notes -join ",") }
}

function Run-One([string]$path) {
  $name   = Split-Path $path -Leaf
  $runLog = Join-Path $root ("run__{0}.log" -f $name)
  $errLog = Join-Path $root ("err__{0}.log" -f $name)

  Remove-Item $runLog,$errLog -Force -ErrorAction SilentlyContinue
  Reset-Artifacts

  $sw = [System.Diagnostics.Stopwatch]::StartNew()

  # ✅ cmd.exe로 격리 실행(PS가 Traceback을 NativeCommandError로 못 끌어올림)
  $cmd = 'cd /d "{0}" && "{1}" "{2}" 1> "{3}" 2> "{4}"' -f $root, $py, $path, $runLog, $errLog
  $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -NoNewWindow -PassThru

  $okWait = $p.WaitForExit($TimeoutSec * 1000)
  if (-not $okWait) {
    try { $p.Kill() } catch {}
    $exit = 124
  } else {
    $exit = $p.ExitCode
  }

  $sw.Stop()

  $out = ""
  if (Test-Path $runLog) { $out = Get-Content $runLog -Raw }

  $hasToken = ($out -match [regex]::Escape($requiredToken))
  $errSize = 0
if (Test-Path $errLog) { $errSize = (Get-Item $errLog).Length }

  $val = Validate-Artifacts

  return [pscustomobject]@{
    Name=$name
    Path=$path
    Exit=[int]$exit
    TimeMs=[int]$sw.ElapsedMilliseconds
    HasToken=[bool]$hasToken
    ErrSize=[int]$errSize
    QualityOk=[bool]$val.Ok
    QualityNotes=[string]$val.Notes
  }
}

$cands = Get-ChildItem $CandidatesDir -Filter "main_work__*.py" -File -ErrorAction SilentlyContinue
if (-not $cands) {
  Write-Host "❌ 후보 없음: $CandidatesDir\main_work__*.py"
  exit 1
}

$results = foreach ($c in $cands) {
  Write-Host "▶ 실행: $($c.Name)"
  Run-One $c.FullName
}

# 점수 계산
foreach ($r in $results) {
  $score = 0
  if ($r.Exit -eq 0) { $score += 1000 }
  if ($r.HasToken)   { $score += 200 }
  if ($r.QualityOk)  { $score += 500 }
  if ($r.ErrSize -eq 0) { $score += 100 }
  $score -= [Math]::Min(200, [int]($r.TimeMs / 50))
  $r | Add-Member -NotePropertyName Score -NotePropertyValue ([int]$score) -Force
}

Write-Host ""
Write-Host "=== 후보 결과(품질 포함) ==="
$results | Sort-Object @{Expression={ [int]$_.Score };Descending=$true}, @{Expression={ [int]$_.TimeMs };Descending=$false} | ForEach-Object {
  $note = if ($_.QualityOk) { "" } else { "[" + $_.QualityNotes + "]" }
  Write-Host ("{0,-22} Exit={1,-3} Token={2,-5} Quality={3,-5} TimeMs={4,-5} ErrSize={5,-6} Score={6} {7}" -f `
    $_.Name, $_.Exit, $_.HasToken, $_.QualityOk, $_.TimeMs, $_.ErrSize, $_.Score, $note)
}

# 채택: Exit=0 AND QualityOk=true
$best = $results | Where-Object { $_.Exit -eq 0 -and $_.QualityOk } |
        Sort-Object @{Expression={ [int]$_.Score };Descending=$true}, @{Expression={ [int]$_.TimeMs };Descending=$false} |
        Select-Object -First 1

if (-not $best) {
  Write-Host ""
  Write-Host "❌ 품질 통과 후보 없음. err__*.log 확인"
  exit 1
}

Write-Host ""
Write-Host "🏆 선택됨: $($best.Name) (Score=$($best.Score))"
Copy-Item $best.Path $TargetPath -Force
Write-Host "✅ 채택 완료 → $TargetPath"

# ✅ choose_best 성공 스탬프(승격 게이트)
Set-Content -Encoding ASCII ".\scripts\.last_choose_best_ok" -Value "ok"
exit 0


