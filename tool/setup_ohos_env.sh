#!/bin/bash
# 鸿蒙 Flutter 环境配置脚本
# 用法: source tool/setup_ohos_env.sh

# 检查操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS 环境
    if [ -d "/Applications/DevEco-Studio.app/Contents" ]; then
        export TOOL_HOME=/Applications/DevEco-Studio.app/Contents
    elif [ -d "$HOME/Applications/DevEco-Studio.app/Contents" ]; then
        export TOOL_HOME=$HOME/Applications/DevEco-Studio.app/Contents
    else
        echo "⚠️  未找到 DevEco Studio，请确保已安装"
        echo "   下载地址: https://developer.harmonyos.com/cn/develop/deveco-studio"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux 环境 - 需要用户自行设置 TOOL_HOME
    if [ -z "$TOOL_HOME" ]; then
        echo "⚠️  请手动设置 TOOL_HOME 环境变量指向 command-line-tools 目录"
    fi
fi

# 配置鸿蒙 SDK 环境变量（如果 TOOL_HOME 已设置）
if [ -n "$TOOL_HOME" ]; then
    export DEVECO_SDK_HOME=$TOOL_HOME/sdk
    export PATH=$TOOL_HOME/tools/ohpm/bin:$PATH
    export PATH=$TOOL_HOME/tools/hvigor/bin:$PATH
    export PATH=$TOOL_HOME/tools/node/bin:$PATH
    echo "✅ 鸿蒙 SDK 环境变量已配置"
    echo "   DEVECO_SDK_HOME: $DEVECO_SDK_HOME"
else
    echo "⚠️  跳过鸿蒙 SDK 配置"
fi

# 配置 Flutter 下载源
# 默认官方源；中国大陆网络可启用 `USE_CN_FLUTTER_MIRROR=1`。
if [ "${USE_CN_FLUTTER_MIRROR:-0}" = "1" ]; then
    export PUB_HOSTED_URL=https://pub.flutter-io.cn
    export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
    echo "✅ 使用国内 Flutter 镜像源"
else
    export PUB_HOSTED_URL=https://pub.dev
    export FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
    echo "✅ 使用官方 Flutter 下载源"
fi

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 配置 FVM Flutter 路径
if [ -d "$PROJECT_ROOT/.fvm/flutter_sdk" ]; then
    export PATH="$PROJECT_ROOT/.fvm/flutter_sdk/bin:$PATH"
    echo "✅ FVM Flutter 路径已配置"
else
    echo "⚠️  未找到 FVM Flutter SDK，请先运行: fvm install"
fi

# 配置 PUB_CACHE（可选，避免与系统 Flutter 冲突）
export PUB_CACHE="$PROJECT_ROOT/.fvm/.pub_cache"

echo ""
echo "📝 环境变量摘要:"
echo "   PUB_HOSTED_URL: $PUB_HOSTED_URL"
echo "   FLUTTER_STORAGE_BASE_URL: $FLUTTER_STORAGE_BASE_URL"
echo "   PUB_CACHE: $PUB_CACHE"
echo ""
echo "👉 接下来请运行:"
echo "   1. fvm install        # 安装鸿蒙 Flutter"
echo "   2. fvm flutter doctor -v  # 验证环境"
