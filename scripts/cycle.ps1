$ErrorActionPreference = "Continue"

Write-Host "=== 1) 후보 자동 생성 ==="
.\scripts\gen_candidates.ps1

Write-Host ""
Write-Host "=== 2) 후보 비교/채택 ==="
.\scripts\choose_best.ps1
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ choose_best 실패. err__*.log 확인"
  exit 1
}

Write-Host ""
Write-Host "=== 3) 승격 ==="
.\scripts\promote.ps1
exit $LASTEXITCODE
