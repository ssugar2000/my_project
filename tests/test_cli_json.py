import json
from my_project.main import main

def test_json_output_root(capsys):
    assert main(["--json", "--name", "minsoo"]) == 0
    out = capsys.readouterr().out.strip()
    obj = json.loads(out)
    assert obj["ok"] is True
    assert obj["message"] == "Hello, minsoo"

def test_json_output_greet(capsys):
    assert main(["--json", "greet", "--name", "minsoo"]) == 0
    out = capsys.readouterr().out.strip()
    obj = json.loads(out)
    assert obj["ok"] is True
    assert obj["message"] == "Hello, minsoo"
