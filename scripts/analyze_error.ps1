$ErrorActionPreference='Stop'

if (!(Test-Path .\error.log)) {
  Write-Host 'error.log 없음'
  exit 0
}

$err = Get-Content .\error.log -Raw

if ($err -match 'SyntaxError') {
  Write-Host '❗ SyntaxError 감지'
} elseif ($err -match 'ModuleNotFoundError') {
  Write-Host '❗ ModuleNotFoundError 감지'
} elseif ($err -match 'FileNotFoundError') {
  Write-Host '❗ FileNotFoundError 감지'
} else {
  Write-Host '❗ 알 수 없는 에러'
}

Write-Host '--- 원문 ---'
Get-Content .\error.log -TotalCount 30
