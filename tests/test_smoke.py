from my_project.main import main

def test_smoke():
    assert main(["--name", "minsoo"]) == 0