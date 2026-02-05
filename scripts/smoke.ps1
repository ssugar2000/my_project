$ErrorActionPreference = "Stop"

Write-Host "== E2E smoke =="
python -m my_project.main --name minsoo
if ($LASTEXITCODE -ne 0) { throw "E2E failed: root mode exitcode=$LASTEXITCODE" }

python -m my_project.main greet --name minsoo
if ($LASTEXITCODE -ne 0) { throw "E2E failed: greet exitcode=$LASTEXITCODE" }

python -m my_project.main --json --name minsoo
if ($LASTEXITCODE -ne 0) { throw "E2E failed: json root exitcode=$LASTEXITCODE" }

python -m my_project.main --json greet --name minsoo
if ($LASTEXITCODE -ne 0) { throw "E2E failed: json greet exitcode=$LASTEXITCODE" }

Write-Host "OK"
