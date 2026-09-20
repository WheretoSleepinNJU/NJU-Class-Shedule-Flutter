"""
南大验证码识别模型 —— 训练脚本（备用，暂不运行）。

跟现成的 nju_captcha.onnx 保持同样的输入/输出规格，训出来的模型可以
直接替换掉那个文件，不需要改 Flutter 侧代码：
  - 输入：80x30 RGB 图片，按 (像素/255 - MEAN) / STD 归一化，[1,3,30,80]
  - 输出：4 个字符位置 x 35 个类别（字符集 1-9 + a-z，不含 0）

使用前提（现在不用装，等真的要训练的时候再装）：
    pip install torch pillow

数据准备：
    在 --data 指定的目录下放训练图片，文件名格式为 "<四位标签>_<任意编号>.jpg"，
    例如 "a3x9_00001.jpg"，标签就是文件名下划线前面那部分（4 个字符，小写）。
    这份脚本不包含"采集"和"标注"，那两步分别用 collect_captcha.py 和人工/LLM 辅助完成。

运行：
    python train_captcha_model.py --data captcha_samples --epochs 30 --out nju_captcha_new.onnx
"""
import argparse
import glob
import os

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader
from PIL import Image

RESIZE_WIDTH = 80
RESIZE_HEIGHT = 30
MEAN = [0.7336, 0.745, 0.778]
STD = [0.3062, 0.31, 0.3177]
CHARACTERS = list("123456789abcdefghijklmnopqrstuvwxyz")  # 35 个类别，不含 '0'
CAPTCHA_LENGTH = 4
NUM_CLASSES = len(CHARACTERS)
CHAR_TO_IDX = {c: i for i, c in enumerate(CHARACTERS)}


class CaptchaDataset(Dataset):
    """文件名形如 <标签>_<编号>.jpg，标签是 4 个字符（对应 CHARACTERS 里的字符）。"""

    def __init__(self, data_dir: str):
        self.paths = sorted(glob.glob(os.path.join(data_dir, "*.jpg")) +
                             glob.glob(os.path.join(data_dir, "*.png")))
        if not self.paths:
            raise RuntimeError(f"在 {data_dir} 里没找到任何图片，检查路径和文件名格式。")

    def __len__(self):
        return len(self.paths)

    def __getitem__(self, idx):
        path = self.paths[idx]
        filename = os.path.basename(path)
        label_str = filename.split("_")[0].lower()
        if len(label_str) != CAPTCHA_LENGTH:
            raise ValueError(
                f"文件名 {filename} 解析出的标签 '{label_str}' 长度不是 {CAPTCHA_LENGTH}，"
                "请检查命名是否是 <四位标签>_<编号>.jpg 的格式。"
            )
        label = torch.tensor([CHAR_TO_IDX[c] for c in label_str], dtype=torch.long)

        img = Image.open(path).convert("RGB").resize((RESIZE_WIDTH, RESIZE_HEIGHT))
        tensor = torch.tensor(list(img.getdata()), dtype=torch.float32).view(
            RESIZE_HEIGHT, RESIZE_WIDTH, 3
        ) / 255.0
        for c in range(3):
            tensor[:, :, c] = (tensor[:, :, c] - MEAN[c]) / STD[c]
        tensor = tensor.permute(2, 0, 1)  # HWC -> CHW

        return tensor, label


class TinyCaptchaNet(nn.Module):
    """跟参考项目一个量级的小模型（几万参数），够用不追求花哨。"""

    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(3, 16, 3, padding=1)
        self.conv2 = nn.Conv2d(16, 32, 3, padding=1)
        self.pool = nn.MaxPool2d(2, 2)
        # 80x30 经过两次 /2 池化 -> 20x7
        self.fc = nn.Linear(32 * 20 * 7, CAPTCHA_LENGTH * NUM_CLASSES)

    def forward(self, x):
        x = self.pool(F.relu(self.conv1(x)))
        x = self.pool(F.relu(self.conv2(x)))
        x = x.flatten(1)
        x = self.fc(x)
        return x.view(-1, CAPTCHA_LENGTH, NUM_CLASSES)


def train(data_dir: str, epochs: int, batch_size: int, out_path: str):
    dataset = CaptchaDataset(data_dir)
    val_size = max(1, len(dataset) // 10)
    train_size = len(dataset) - val_size
    train_set, val_set = torch.utils.data.random_split(dataset, [train_size, val_size])

    train_loader = DataLoader(train_set, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_set, batch_size=batch_size)

    model = TinyCaptchaNet()
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)

    for epoch in range(epochs):
        model.train()
        total_loss = 0.0
        for images, labels in train_loader:
            optimizer.zero_grad()
            outputs = model(images)  # [B, 4, 35]
            loss = sum(
                F.cross_entropy(outputs[:, i, :], labels[:, i])
                for i in range(CAPTCHA_LENGTH)
            )
            loss.backward()
            optimizer.step()
            total_loss += loss.item()

        model.eval()
        correct_chars, total_chars = 0, 0
        correct_full, total_full = 0, 0
        with torch.no_grad():
            for images, labels in val_loader:
                outputs = model(images)
                preds = outputs.argmax(dim=2)  # [B, 4]
                correct_chars += (preds == labels).sum().item()
                total_chars += labels.numel()
                correct_full += (preds == labels).all(dim=1).sum().item()
                total_full += labels.size(0)

        char_acc = correct_chars / max(1, total_chars)
        full_acc = correct_full / max(1, total_full)
        print(
            f"Epoch {epoch + 1}/{epochs}  loss={total_loss:.4f}  "
            f"单字符准确率={char_acc:.2%}  整体4字符全对准确率={full_acc:.2%}"
        )

    dummy_input = torch.randn(1, 3, RESIZE_HEIGHT, RESIZE_WIDTH)
    torch.onnx.export(
        model,
        dummy_input,
        out_path,
        input_names=["input"],
        output_names=["output"],
        opset_version=17,
    )
    print(f"已导出模型到 {out_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=str, required=True, help="训练图片目录")
    parser.add_argument("--epochs", type=int, default=30)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--out", type=str, default="nju_captcha_new.onnx")
    args = parser.parse_args()

    train(args.data, args.epochs, args.batch_size, args.out)
