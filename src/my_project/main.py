import argparse

def build_parser():
    p = argparse.ArgumentParser()
    p.add_argument("--name", required=True)
    return p

def main(argv=None):
    args = build_parser().parse_args(argv)
    return 0 if args.name else 1

if __name__ == "__main__":
    raise SystemExit(main())
