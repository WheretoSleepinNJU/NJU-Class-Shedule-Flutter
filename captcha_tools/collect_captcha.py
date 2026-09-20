"""
南京大学统一认证登录页"动态码"（图片验证码）采集脚本。

用法：
    pip install requests
    python collect_captcha.py --count 500 --out captcha_samples

采集到的图片会存到 --out 指定的文件夹里，文件名是自增编号，
方便后面标注时按顺序处理。这个接口不需要登录、不需要账号密码。
"""
import argparse
import time
import os
import requests

CAPTCHA_URL = "https://authserver.nju.edu.cn/authserver/getCaptcha.htl"


def collect(count: int, out_dir: str, delay_seconds: float):
    os.makedirs(out_dir, exist_ok=True)
    existing = len([f for f in os.listdir(out_dir) if f.endswith(".jpg")])
    session = requests.Session()

    saved = 0
    attempt = 0
    while saved < count:
        attempt += 1
        timestamp = int(time.time() * 1000)
        try:
            resp = session.get(
                CAPTCHA_URL,
                params={"1": timestamp},
                timeout=10,
                verify=False,
            )
            if resp.status_code == 200 and len(resp.content) > 100:
                index = existing + saved
                path = os.path.join(out_dir, f"{index:05d}.jpg")
                with open(path, "wb") as f:
                    f.write(resp.content)
                saved += 1
                if saved % 20 == 0:
                    print(f"已保存 {saved}/{count} 张")
            else:
                print(f"第 {attempt} 次请求返回异常，状态码 {resp.status_code}")
        except Exception as e:
            print(f"第 {attempt} 次请求失败：{e}")

        time.sleep(delay_seconds)

    print(f"完成，共保存 {saved} 张到 {out_dir}/")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--count", type=int, default=500, help="要采集的图片数量")
    parser.add_argument("--out", type=str, default="captcha_samples", help="保存目录")
    parser.add_argument("--delay", type=float, default=0.4, help="每次请求间隔秒数")
    args = parser.parse_args()

    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    collect(args.count, args.out, args.delay)
