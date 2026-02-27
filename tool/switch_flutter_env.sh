#!/bin/bash
# Flutter 构建环境快速切换脚本
# 用法（必须 source 执行，才能影响当前终端环境）:
#   source tool/switch_flutter_env.sh ohos
#   source tool/switch_flutter_env.sh official

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "⚠️  请使用 source 执行此脚本:"
    echo "   source tool/switch_flutter_env.sh <ohos|official>"
    exit 1
fi

MODE="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

path_remove() {
    local remove_path="$1"
    if [ -z "$remove_path" ]; then
        return
    fi

    local old_path="$PATH"
    local new_path=""
    IFS=':' read -ra path_items <<< "$old_path"
    for item in "${path_items[@]}"; do
        if [ "$item" != "$remove_path" ] && [ -n "$item" ]; then
            if [ -z "$new_path" ]; then
                new_path="$item"
            else
                new_path="$new_path:$item"
            fi
        fi
    done
    export PATH="$new_path"
}

path_add_front() {
    local add_path="$1"
    if [ -z "$add_path" ] || [ ! -d "$add_path" ]; then
        return
    fi

    path_remove "$add_path"
    export PATH="$add_path:$PATH"
}

switch_to_ohos() {
    source "$PROJECT_ROOT/tool/setup_ohos_env.sh"

    if [ -x "$PROJECT_ROOT/.fvm/flutter_sdk/bin/flutter" ]; then
        path_add_front "$PROJECT_ROOT/.fvm/flutter_sdk/bin"
    fi

    echo "✅ 已切换到 OHOS 构建环境"
    echo "   可运行: fvm flutter doctor -v"
}

switch_to_official() {
    local old_tool_home="$TOOL_HOME"

    path_remove "$PROJECT_ROOT/.fvm/flutter_sdk/bin"
    path_remove "$PROJECT_ROOT/.fvm/default/bin"

    if [ -n "$old_tool_home" ]; then
        path_remove "$old_tool_home/tools/ohpm/bin"
        path_remove "$old_tool_home/tools/hvigor/bin"
        path_remove "$old_tool_home/tools/node/bin"
    fi

    unset TOOL_HOME
    unset DEVECO_SDK_HOME
    unset PUB_CACHE
    unset FLUTTER_SDK

    export PUB_HOSTED_URL=https://pub.dev
    export FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com

    echo "✅ 已切换到官方 Flutter 构建环境"
    echo "   可运行: flutter doctor -v"
}

case "$MODE" in
    ohos)
        switch_to_ohos
        ;;
    official)
        switch_to_official
        ;;
    *)
        echo "用法: source tool/switch_flutter_env.sh <ohos|official>"
        ;;
esac
