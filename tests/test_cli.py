import pytest
from my_project.main import main

def test_cli_name_ok():
    assert main(["--name", "minsoo"]) == 0

def test_cli_greet_ok():
    assert main(["greet", "--name", "minsoo"]) == 0

def test_cli_version_exits_ok():
    # argparse --version은 내부적으로 SystemExit(0) 발생
    with pytest.raises(SystemExit) as e:
        main(["--version"])
    assert e.value.code == 0
