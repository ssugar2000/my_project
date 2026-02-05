import pytest
from my_project.main import main

def test_greet_missing_name_exits_2():
    with pytest.raises(SystemExit) as e:
        main(["greet"])
    assert e.value.code == 2

def test_unknown_option_exits_2():
    with pytest.raises(SystemExit) as e:
        main(["--no-such-option"])
    assert e.value.code == 2

def test_unknown_command_exits_2():
    with pytest.raises(SystemExit) as e:
        main(["nope"])
    assert e.value.code == 2
