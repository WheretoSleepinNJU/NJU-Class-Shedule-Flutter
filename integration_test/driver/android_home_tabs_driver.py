"""Drive real emulator touches, interrupted presses and screenshots for home tabs."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--flutter', required=True)
    parser.add_argument('--adb', required=True)
    parser.add_argument('--serial', default='emulator-5580')
    parser.add_argument('--screenshots', action='store_true')
    parser.add_argument('--target', default='integration_test/home_tabs_test.dart',
                        help='Integration entry point (may compose additional acceptance cases)')
    parser.add_argument('--binary', help='Prebuilt integration APK; avoids building while the emulator runs')
    parser.add_argument('--plain-name', help='Run only the matching integration case')
    args = parser.parse_args()
    if not args.serial.startswith('emulator-'):
        parser.error('Use an emulator; this driver never operates physical devices.')
    root = Path(__file__).resolve().parents[2]
    folder = root / 'build' / 'integration' / 'home-tabs'
    folder.mkdir(parents=True, exist_ok=True)
    log = folder / 'android.log'
    adb = [args.adb, '-s', args.serial]

    def device(*command):
        return subprocess.check_output(adb + list(command), timeout=30).decode().strip()

    def wait_for(predicate, message):
        for _ in range(50):
            if predicate():
                return
            time.sleep(.1)
        raise RuntimeError(message)

    if args.binary:
        command = [args.flutter, 'drive', '--no-pub',
                   '--driver=integration_test/driver.dart', f'--target={args.target}',
                   f'--use-application-binary={args.binary}', '-d', args.serial]
    else:
        command = [args.flutter, 'test', '--no-pub', '--dart-define=DRIVE_ANDROID_NAV=true',
                   args.target, '-d', args.serial]
        if args.screenshots:
            command[3:3] = ['--dart-define=CAPTURE_HOME_TABS=true',
                            '--dart-define=CAPTURE_ANDROID_PAGES=true']
        if args.plain_name:
            command.extend(['--plain-name', args.plain_name])
    with log.open('w') as stream:
        process = subprocess.Popen(command, cwd=root, env=os.environ.copy(),
                                   stdout=stream, stderr=subprocess.STDOUT)
        seen = 0
        try:
            while process.poll() is None:
                events = re.findall(r'(?:HOME|ANDROID)_(NAV_TAP|PAGE_READY|INTERRUPT_LOCK): ([^\r\n]+)', log.read_text())
                for kind, value in events[seen:]:
                    if kind == 'NAV_TAP':
                        x, y = value.split()
                        device('shell', 'input', 'tap', x, y)
                    elif kind == 'INTERRUPT_LOCK':
                        down_x, down_y, x, y = value.split()
                        device('shell', 'input', 'motionevent', 'DOWN', down_x, down_y)
                        device('shell', 'input', 'keyevent', 'KEYCODE_SLEEP')
                        wait_for(lambda: any(state in device('shell', 'dumpsys', 'power')
                                             for state in ('mWakefulness=Asleep', 'mWakefulness=Dozing')),
                                 'Emulator did not sleep')
                        # Release the interrupted finger while asleep before a
                        # fresh tap; keep Android's injected pointer stream valid.
                        device('shell', 'input', 'motionevent', 'UP', down_x, down_y)
                        time.sleep(.5)
                        device('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
                        device('shell', 'wm', 'dismiss-keyguard')
                        wait_for(lambda: 'mWakefulness=Awake' in device('shell', 'dumpsys', 'power'),
                                 'Emulator did not wake')
                        wait_for(lambda: any('mCurrentFocus=' in line and 'wheretosleepinnju' in line
                                             for line in device('shell', 'dumpsys', 'window').splitlines()),
                                 'App did not regain window focus')
                        time.sleep(1.5)  # Let Android finish its keyguard animation.
                        device('shell', 'input', 'tap', x, y)  # Exactly one tap.
                    elif args.screenshots:
                        time.sleep(.3)
                        with (folder / f'{value}.png').open('wb') as output:
                            subprocess.run(adb + ['exec-out', 'screencap', '-p'], stdout=output, check=True)
                    print(kind, value, flush=True)
                    seen += 1
                time.sleep(.15)
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=30)
    print(log.read_text()[-7000:])
    raise SystemExit(process.returncode)


if __name__ == '__main__':
    main()
