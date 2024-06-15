#!/bin/bash
# author: GitHub @Yuyuko1024

function patch_repo()
{

    local commit_url=$1

    # 核心应用代码
    commit_id=$(echo "$commit_url" | awk -F'/commit/' '{print $2}' | cut -d'?' -f1)
    wget "$commit_url.patch" && git am $commit_id.patch && rm $commit_id.patch

    if [ $? -ne 0 ]; then
        echo "命令执行出错，请检查提交链接或解决冲突。错误码: $?"
        echo "已删除残留的patch文件。"
        rm "$commit_id.patch"

    fi

}


# 检查当前目录是否为Git仓库
if [ ! -d ".git" ]; then
    echo "错误：您所处的目录非Git仓库，请检查您所处的工作目录。"
    exit 1
fi

# 获取当前分支名
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

RUN_FOREVER=false

# 检查是否有-r参数
if [ "$1" = "-r" ]; then
    RUN_FOREVER=true
    echo "持续运行模式已启动。您可以对仓库按提交顺序输入补丁提交对您本地仓库进行patch操作。"
else
    if [ "$#" -eq 0 ]; then
        echo "使用方法: $0 <GitHub提交链接> [-r]"
        echo "可单次对当前目录仓库进行打patch操作，也可以使用 -r 持续运行模式打入多个补丁。"
        echo "在持续运行模式中，请按照提交先后顺序依次输入Github提交补丁，可输入q退出循环模式。"
        exit 1
    fi
    # 检查URL是否以https://github.com开头，作为一个基础的校验
    if [[ ! "$1" =~ ^https://github.com ]]; then
        echo "错误：请输入有效的GitHub提交链接。"
        break
    fi
    patch_repo "$1"
    exit $?
fi

while true; do
    # 显示当前提交信息
    echo "当前HEAD提交信息：$(git log -1 --pretty=format:%s)"
    echo "当前工作目录：$(pwd)"
    echo "操作帮助：输入'q'退出，输入'a'回退上次修补，输入's'跳过上次的补丁，输入'l'展示当前仓库提交历史，输入'c'清屏。"

    # 获取并显示当前HEAD的commit hash的前9个字符，以及当前分支名称，然后等待用户输入
    read -p "当前分支: ${CURRENT_BRANCH}，最近提交哈希: $(git rev-parse HEAD | cut -c1-9)，请输入提交链接: " COMMIT_URL
    
    # 检查用户是否想要退出
    if [ "$COMMIT_URL" = "q" ]; then
        echo "退出脚本。"
        break
    fi

    # 清除屏幕输出
    if [ "$COMMIT_URL" = "c" ]; then
        clear
        continue
    fi

    # 展示当前仓库提交历史
    if [ "$COMMIT_URL" = "l" ]; then
        git log
        continue
    fi

    # 回退操作，回退上次修补时的出错。
    if [ "$COMMIT_URL" = "a" ]; then
        git am --abort
        if [ $? == 0 ]; then
            echo "您上次的修补已回退至$(git rev-parse HEAD | cut -c1-9)。"
        else
            echo "当前仓库可能无需回退！"
        fi
        continue
    fi

    # 跳过操作，跳过上次修补时的出错。
    if [ "$COMMIT_URL" = "s" ]; then
        git am --skip
        if [ $? == 0 ]; then
            echo "您上次的修补已跳过。"
        else
            echo "当前仓库可能无需回退！"
        fi
        continue
    fi

    # 检查URL是否以https://github.com开头，作为一个基础的校验
    if [[ ! "$COMMIT_URL" =~ ^https://github.com ]]; then
        echo "错误：请输入有效的GitHub提交链接。"
        continue
    fi

    patch_repo $COMMIT_URL

done
