from my_project.main import main

def test_root_prints_greeting(capsys):
    assert main(["--name", "minsoo"]) == 0
    out = capsys.readouterr().out
    assert "Hello, minsoo" in out

def test_greet_prints_greeting(capsys):
    assert main(["greet", "--name", "minsoo"]) == 0
    out = capsys.readouterr().out
    assert "Hello, minsoo" in out
