import argparse, shutil, subprocess, time, re, xml.etree.ElementTree as E
from pathlib import Path
parser = argparse.ArgumentParser(description='Drive android_lifecycle_test.dart with real Android input')
parser.add_argument('--device', required=True, help='Dedicated emulator serial; never defaults to a physical device')
parser.add_argument('--log', type=Path, required=True, help='Redirected flutter test output')
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--adb', default=shutil.which('adb'))
args = parser.parse_args()
if not args.device.startswith('emulator-') or not args.adb:
 parser.error('A dedicated emulator and an adb executable are required')
adb=args.adb
output=args.output;output.mkdir(parents=True,exist_ok=True)
def run(*a):return subprocess.check_output([adb,'-s',args.device,*a],timeout=30)
def nodes():
 run('shell','uiautomator','dump','/sdcard/nju-lifecycle.xml')
 return list(E.fromstring(run('shell','cat','/sdcard/nju-lifecycle.xml')).iter('node'))
def text(n):return n.get('text') or n.get('content-desc') or ''
def center(n):
 a,b,c,d=map(int,re.findall(r'\d+',n.get('bounds')));return str((a+c)//2),str((b+d)//2)
def find(label):
 for _ in range(15):
  found=next((n for n in nodes() if n.get('package')=='com.lilystudio.wheretosleepinnju' and text(n)==label),None)
  if found is not None:return found
  time.sleep(.2)
 print([(text(n),n.get('enabled')) for n in nodes() if n.get('package')=='com.lilystudio.wheretosleepinnju'],flush=True)
 raise RuntimeError('Control not reached: '+label)
def tap(label):run('shell','input','tap',*center(find(label)))
def counts():
 for n in nodes():
  match=re.fullmatch(r'原生:(\d+) Flutter:(\d+)',text(n))
  if match:return tuple(map(int,match.groups()))
 raise RuntimeError('Counters not found')
def expect(count):
 value=counts()
 if min(value)<count:raise RuntimeError(f'Expected at least {count} accepted taps: {value}')
 print('Verified real Android touches:',count,value,flush=True)
def snap(name):(output/(name+'.png')).write_bytes(run('exec-out','screencap','-p'))
log=args.log
for _ in range(600):
 if log.exists() and 'ANDROID_LIFECYCLE_READY' in log.read_text():break
 time.sleep(.5)
else:raise RuntimeError('Test did not become ready')
tap('原生计数');tap('Flutter计数');expect(1)
run('shell','cmd','statusbar','expand-notifications');time.sleep(1)
run('shell','cmd','statusbar','collapse');time.sleep(.5)
tap('原生计数');tap('Flutter计数');expect(2)
for count,interrupted in [(3,'原生计数'),(4,'Flutter计数'),(5,None)]:
 if interrupted:
  find_before_lock=find(interrupted)
  run('shell','input','motionevent','DOWN',*center(find_before_lock))
 run('shell','input','keyevent','KEYCODE_SLEEP');time.sleep(1)
 if interrupted:run('shell','input','motionevent','UP',*center(find_before_lock))
 run('shell','input','keyevent','KEYCODE_WAKEUP');run('shell','wm','dismiss-keyguard');time.sleep(2)
 before=counts();tap('原生计数');tap('Flutter计数');after=counts()
 if after != (before[0]+1,before[1]+1):raise RuntimeError(f'First taps after unlock lost: {before} -> {after}')
 expect(count)
snap('android-after-three-unlocks')
# Return through the real Compose soft-glass back control.
back=next((n for n in nodes() if text(n) in ['Back','返回']),None)
if back is None:raise RuntimeError('Native back not found')
run('shell','input','tap',*center(back));print('Native back tapped',flush=True)

find('主页原生:0 Flutter:0')
embedded=find('嵌入计数')
run('shell','input','motionevent','DOWN',*center(embedded))
run('shell','input','keyevent','KEYCODE_SLEEP');time.sleep(1)
run('shell','input','motionevent','UP',*center(embedded))
run('shell','input','keyevent','KEYCODE_WAKEUP');run('shell','wm','dismiss-keyguard');time.sleep(2)
tap('嵌入计数');find('主页原生:1 Flutter:0');snap('android-home-after-unlock')
tap('主页Flutter计数')
print('Delivered real embedded Compose and Flutter home taps; awaiting Dart assertions',flush=True)
