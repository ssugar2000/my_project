import argparse
import json

__version__ = "0.1.0"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="my_project")
    p.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    p.add_argument("--json", action="store_true", help="Output as JSON")

    sub = p.add_subparsers(dest="cmd")

    # 루트 모드
    p.add_argument("--name", help="Name to greet")

    # greet 서브커맨드
    greet = sub.add_parser("greet", help="Greet someone")
    greet.add_argument("--name", required=True, help="Name to greet")

    return p

def _emit(args, message: str) -> None:
    if getattr(args, "json", False):
        print(json.dumps({"ok": True, "message": message}, ensure_ascii=False))
    else:
        print(message)

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)

    if args.cmd == "greet":
        _emit(args, f"Hello, {args.name}")
        return 0

    if args.name:
        _emit(args, f"Hello, {args.name}")
        return 0

    return 1

if __name__ == "__main__":
    raise SystemExit(main())
