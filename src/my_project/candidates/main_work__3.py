def main():
    print('main_work 실행됨')
    x = 1 / 0
    return 0

if __name__ == '__main__':
    raise SystemExit(main())