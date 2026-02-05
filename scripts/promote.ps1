$ErrorActionPreference = "Stop"

# choose_best 성공 증거 파일(스탬프)을 사용
$stampPath = ".\scripts\.last_choose_best_ok"

if (!(Test-Path $stampPath)) {
  Write-Host "❌ choose_best 성공 기록이 없습니다. cycle.ps1로 먼저 실행하세요."
  exit 1
}

# main_work 실행 검사
$runLog = ".\run_main_work.log"
$errLog = ".\error.log"
Remove-Item $runLog,$errLog -Force -ErrorAction SilentlyContinue

& .\.venv\Scripts\python .\src\my_project\main_work.py 1> $runLog 2> $errLog
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ main_work 실행 실패. error.log 확인"
  exit 1
}

# (선택) 테스트 있으면 실행
$hasTests = Get-ChildItem .\tests -Recurse -Include test*.py -ErrorAction SilentlyContinue
if ($hasTests) {
  & .\.venv\Scripts\python -m pytest -q 1>> $runLog 2>> $errLog
  if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 테스트 실패. error.log 확인"
    exit 1
  }
} else {
  Write-Host "ℹ️ 테스트 없음 → 정상 통과"
}

# 승격
Copy-Item .\src\my_project\main_work.py .\src\my_project\main_active.py -Force
Write-Host "✅ 승격 완료: main_work → main_active"

# 승격 후 스탬프 제거(다음 cycle에서 다시 생성하도록)
Remove-Item $stampPath -Force -ErrorAction SilentlyContinue
exit 0
