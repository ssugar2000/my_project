import argparse
import json
import sys

VERSION = "0.0.1"


def build_parser():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--version",
        action="version",
        version=VERSION,
    )

    parser.add_argument(
        "--json",
        action="store_true",
        help="output as json",
    )

    subparsers = parser.add_subparsers(dest="command")

    # root command
    parser.add_argument("--name", required=False)

    # greet subcommand
    greet = subparsers.add_parser("greet")
    greet.add_argument("--name", required=True)

    return parser


def _print(message: str, as_json: bool):
    if as_json:
        print(json.dumps({"ok": True, "message": message}))
    else:
        print(message)


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)

    name = args.name
    if not name:
        return 2

    message = f"Hello, {name}"
    _print(message, args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
