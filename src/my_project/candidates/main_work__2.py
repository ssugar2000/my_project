import time
def main():
    time.sleep(1)
    print('main_work 실행됨')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())