param(
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$Content
)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 상대경로면 현재 작업폴더 기준으로 절대경로화
if ([System.IO.Path]::IsPathRooted($Path)) {
  $fullPath = $Path
} else {
  $fullPath = Join-Path (Get-Location) $Path
}

# 디렉터리 보장
$dir = Split-Path $fullPath -Parent
if ($dir -and !(Test-Path $dir)) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

[System.IO.File]::WriteAllText($fullPath, $Content, $utf8NoBom)
