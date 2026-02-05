$ErrorActionPreference = "Continue"

function Run-Work {
  & .\.venv\Scripts\python .\src\my_project\main_work.py *> .\error.log
  return $LASTEXITCODE
}

function Read-Error {
  if (Test-Path .\error.log) { return (Get-Content .\error.log -Raw) }
  return ""
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $dir = Split-Path $Path -Parent
  if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  try { $resolved = (Resolve-Path $Path -ErrorAction Stop).Path } catch { $resolved = $Path }
  [System.IO.File]::WriteAllText($resolved, $Content, $utf8NoBom)
}

# 0) 1차 실행
$code = Run-Work
if ($code -eq 0) {
  Write-Host "✅ 실행 성공, 수정 불필요"
  exit 0
}

Write-Host "❗ 실행 실패. error.log 상위 30줄:"
Get-Content .\error.log -TotalCount 30

$err = Read-Error

# 1) SyntaxError → 템플릿 복구
if ($err -match "SyntaxError") {
  Write-Host "🛠 SyntaxError 감지 → UTF-8 템플릿으로 복구"

  $fixed = @"
def main():
    print('main_work 실행됨')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
"@

  Write-Utf8NoBom ".\src\my_project\main_work.py" $fixed

  $code = Run-Work
  if ($code -eq 0) { Write-Host "✅ 자동 복구 성공"; exit 0 }

  Write-Host "❌ 복구 후에도 실패. error.log 상위 30줄:"
  Get-Content .\error.log -TotalCount 30
  exit 1
}

# 2) ModuleNotFoundError → pip install 자동 시도
if ($err -match "ModuleNotFoundError:\s+No module named '([^']+)'") {
  $missing = $Matches[1]
  Write-Host "🧩 모듈 없음 감지: $missing → pip 설치 시도"

  & .\.venv\Scripts\python -m pip install $missing *> .\pip_install.log
  if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ pip 설치 실패. pip_install.log 확인"
    exit 1
  }

  $code = Run-Work
  if ($code -eq 0) { Write-Host "✅ 설치 후 실행 성공"; exit 0 }

  Write-Host "❌ 설치 후에도 실행 실패. error.log 상위 30줄:"
  Get-Content .\error.log -TotalCount 30
  exit 1
}

# 3) FileNotFoundError → 경로/파일 자동 생성
# 예: FileNotFoundError: [Errno 2] No such file or directory: 'data/input.txt'
if ($err -match "FileNotFoundError:.*directory:\s*'([^']+)'") {
  $missingPath = $Matches[1]
  Write-Host "📁 경로 없음 감지: $missingPath → 자동 생성 시도"

  # python 실행 기준(프로젝트 루트)으로 절대경로로 변환
  $fullPath = Join-Path (Get-Location) $missingPath
  $dir = Split-Path $fullPath -Parent

  if ($dir -and !(Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Host "📂 디렉터리 생성: $dir"
  }

  if (!(Test-Path $fullPath)) {
    New-Item -ItemType File -Force -Path $fullPath | Out-Null
    Write-Host "📄 파일 생성: $fullPath"
  }

  $code = Run-Work
  if ($code -eq 0) { Write-Host "✅ 경로 생성 후 실행 성공"; exit 0 }

  Write-Host "❌ 경로 생성 후에도 실행 실패. error.log 상위 30줄:"
  Get-Content .\error.log -TotalCount 30
  exit 1
}

Write-Host "❌ 자동 수정 실패(지원하지 않는 에러 유형). error.log 확인"
exit 1
