# my_project

[![CI](https://github.com/ssugar2000/my_project/actions/workflows/ci.yml/badge.svg)](https://github.com/ssugar2000/my_project/actions/workflows/ci.yml)

Python CLI project with pytest + GitHub Actions CI.

## Quickstart

python -m pip install -e .
python -m pytest -v

## Run

python -m my_project.main --name minsoo
python -m my_project.main greet --name minsoo
python -m my_project.main --json --name minsoo

## CI

- Runs on push / pull_request
- Executes pytest and scripts/smoke.ps1
