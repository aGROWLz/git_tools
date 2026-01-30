#!/bin/bash

# ComfyUI Workflow Manager - Git 功能管理脚本
# 仓库地址: git@github.com:aGROWLz/Comfy-Workflow-Manager.git

set -e  # 遇到错误立即退出

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 获取父目录（外部项目目录）
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# 配置 - 使用项目内的 SSH 密钥
SSH_KEY="$SCRIPT_DIR/ssh_keys/id_ed25519_github"
REPO_URL="git@github.com:aGROWLz/Comfy-Workflow-Manager.git"

# 自动添加 git_function 到父目录的 .gitignore
auto_add_to_gitignore() {
    local parent_dir="$(dirname "$SCRIPT_DIR")"
    local gitignore_file="$parent_dir/.gitignore"
    local ignore_pattern="git_function/"
    
    # 如果 .gitignore 不存在，创建它
    if [ ! -f "$gitignore_file" ]; then
        echo "$ignore_pattern" > "$gitignore_file"
        return
    fi
    
    # 检查是否已经存在该规则
    if ! grep -qxF "$ignore_pattern" "$gitignore_file" && ! grep -qxF "git_function" "$gitignore_file"; then
        # 添加到 .gitignore
        echo "" >> "$gitignore_file"
        echo "# Git function 工具（自动添加）" >> "$gitignore_file"
        echo "$ignore_pattern" >> "$gitignore_file"
    fi
}

# 显示菜单
show_menu() {
    clear
    echo -e "${CYAN}=========================================="
    echo -e "  ComfyUI Workflow Manager"
    echo -e "  Git 功能管理"
    echo -e "==========================================${NC}"
    echo ""
    echo -e "${BLUE}【Git 操作】${NC}"
    echo -e "  ${GREEN}1${NC}. 推送到 GitHub (SSH)"
    echo -e "  ${GREEN}2${NC}. 从远程拉取并合并"
    echo -e "  ${GREEN}3${NC}. 从远程拉取但不合并 (fetch)"
    echo -e "  ${GREEN}4${NC}. 强制推送 (慎用)"
    echo -e "  ${GREEN}5${NC}. 强制拉取并覆盖本地 (慎用)"
    echo -e "  ${GREEN}6${NC}. 查看状态"
    echo -e "  ${GREEN}7${NC}. 查看提交历史"
    echo ""
    echo -e "${BLUE}【配置管理】${NC}"
    echo -e "  ${GREEN}8${NC}. 配置远程仓库地址"
    echo -e "  ${GREEN}9${NC}. 配置 Git 用户信息"
    echo -e "  ${GREEN}10${NC}. 生成 SSH 密钥"
    echo ""
    echo -e "${BLUE}【测试工具】${NC}"
    echo -e "  ${GREEN}t${NC}. 测试 SSH 连接"
    echo ""
    echo -e "  ${GREEN}0${NC}. 退出"
    echo ""
    echo -e "${CYAN}==========================================${NC}"
    echo -n -e "${YELLOW}请输入选项: ${NC}"
}

# 检查 SSH 密钥（仅当使用 SSH 地址时）
check_ssh_key() {
    # 如果使用 HTTPS，不需要检查 SSH 密钥
    if [[ "$REPO_URL" =~ ^https?:// ]]; then
        return 0
    fi
    
    if [ ! -f "$SSH_KEY" ]; then
        echo -e "${RED}✗ SSH 密钥不存在: $SSH_KEY${NC}"
        echo -e "${YELLOW}请先使用选项 10 生成 SSH 密钥${NC}"
        return 1
    fi
    return 0
}

# 配置 Git SSH 命令（如果使用 SSH 地址）
setup_git_ssh() {
    if [[ "$REPO_URL" =~ ^git@ ]]; then
        export GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes"
    fi
}

# 初始化 Git 仓库（在父目录）
init_git_repo() {
    cd "$PARENT_DIR"
    if [ ! -d .git ]; then
        echo -e "${YELLOW}初始化 Git 仓库...${NC}"
        git init
        echo -e "${GREEN}✓ Git 仓库初始化完成${NC}"
    fi
}

# 配置远程仓库（在父目录）
setup_remote() {
    cd "$PARENT_DIR"
    if git remote | grep -q "^origin$"; then
        CURRENT_URL=$(git remote get-url origin)
        if [ "$CURRENT_URL" != "$REPO_URL" ]; then
            echo -e "${YELLOW}更新远程仓库地址...${NC}"
            git remote set-url origin "$REPO_URL"
        fi
    else
        echo -e "${YELLOW}添加远程仓库...${NC}"
        git remote add origin "$REPO_URL"
    fi
    echo -e "${GREEN}✓ 远程仓库: $REPO_URL${NC}"
}

# 功能 1: 推送到 GitHub
push_to_github() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  推送到 GitHub"
    echo -e "==========================================${NC}"
    echo ""
    
    check_ssh_key || return 1
    setup_git_ssh
    init_git_repo
    setup_remote
    
    cd "$PARENT_DIR"
    echo ""
    echo -e "${BLUE}添加文件到暂存区...${NC}"
    git add .
    echo -e "${GREEN}✓ 文件已添加${NC}"
    
    echo ""
    echo -e "${BLUE}将要提交的文件:${NC}"
    git status --short | head -20
    FILE_COUNT=$(git status --short | wc -l)
    if [ "$FILE_COUNT" -gt 20 ]; then
        echo -e "${YELLOW}... 还有 $((FILE_COUNT - 20)) 个文件${NC}"
    fi
    
    echo ""
    echo -n -e "${YELLOW}是否继续提交？(y/n): ${NC}"
    read -r confirm
    if [ "$confirm" != "y" ]; then
        echo -e "${YELLOW}已取消${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}提交代码...${NC}"
    if git diff --cached --quiet; then
        echo -e "${YELLOW}没有需要提交的更改${NC}"
    else
        git commit -m "feat: ComfyUI Workflow Manager 更新

- 更新项目代码
- 完善功能和文档"
        echo -e "${GREEN}✓ 代码已提交${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}推送到 GitHub...${NC}"
    
    # 确保在 main 分支
    if ! git show-ref --verify --quiet refs/heads/main; then
        git branch -M main
    fi
    
    # 根据仓库类型选择命令
    if [[ "$REPO_URL" =~ ^git@ ]]; then
        if GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" git push -u origin main; then
            echo ""
            echo -e "${GREEN}✓ 推送成功！${NC}"
            echo -e "${BLUE}仓库地址: ${REPO_URL/git@github.com:/https://github.com/}${NC}"
        else
            echo ""
            echo -e "${RED}✗ 推送失败${NC}"
            echo -e "${YELLOW}提示：如果远程有更新，请先选择选项 2 拉取并合并${NC}"
        fi
    else
        if git push -u origin main; then
            echo ""
            echo -e "${GREEN}✓ 推送成功！${NC}"
            echo -e "${BLUE}仓库地址: $REPO_URL${NC}"
        else
            echo ""
            echo -e "${RED}✗ 推送失败${NC}"
            echo -e "${YELLOW}提示：如果远程有更新，请先选择选项 2 拉取并合并${NC}"
        fi
    fi
}

# 功能 2: 从远程拉取并合并
pull_and_merge() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  从远程拉取并合并"
    echo -e "==========================================${NC}"
    echo ""
    
    check_ssh_key || return 1
    setup_git_ssh
    init_git_repo
    setup_remote
    
    cd "$PARENT_DIR"
    echo ""
    echo -e "${BLUE}从远程拉取代码...${NC}"
    
    # 根据仓库类型选择命令
    if [[ "$REPO_URL" =~ ^git@ ]]; then
        if GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" git pull origin main --allow-unrelated-histories; then
            echo ""
            echo -e "${GREEN}✓ 拉取并合并成功${NC}"
        else
            echo ""
            echo -e "${RED}✗ 拉取失败${NC}"
            echo -e "${YELLOW}可能存在冲突，请手动解决或使用选项 5 强制拉取${NC}"
        fi
    else
        if git pull origin main --allow-unrelated-histories; then
            echo ""
            echo -e "${GREEN}✓ 拉取并合并成功${NC}"
        else
            echo ""
            echo -e "${RED}✗ 拉取失败${NC}"
            echo -e "${YELLOW}可能存在冲突，请手动解决或使用选项 5 强制拉取${NC}"
        fi
    fi
}

# 功能 3: 从远程拉取但不合并
fetch_only() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  从远程拉取但不合并"
    echo -e "==========================================${NC}"
    echo ""
    
    check_ssh_key || return 1
    setup_git_ssh
    init_git_repo
    setup_remote
    
    cd "$PARENT_DIR"
    echo ""
    echo -e "${BLUE}从远程获取代码...${NC}"
    
    # 根据仓库类型选择命令
    if [[ "$REPO_URL" =~ ^git@ ]]; then
        if GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" git fetch origin; then
            echo ""
            echo -e "${GREEN}✓ 获取成功${NC}"
            echo ""
            echo -e "${BLUE}远程分支：${NC}"
            git branch -r
            echo ""
            echo -e "${YELLOW}提示：代码已获取但未合并，使用以下命令查看差异：${NC}"
            echo "  git diff main origin/main"
            echo ""
            echo -e "${YELLOW}如需合并，使用以下命令：${NC}"
            echo "  git merge origin/main"
        else
            echo ""
            echo -e "${RED}✗ 获取失败${NC}"
        fi
    else
        if git fetch origin; then
            echo ""
            echo -e "${GREEN}✓ 获取成功${NC}"
            echo ""
            echo -e "${BLUE}远程分支：${NC}"
            git branch -r
            echo ""
            echo -e "${YELLOW}提示：代码已获取但未合并，使用以下命令查看差异：${NC}"
            echo "  git diff main origin/main"
            echo ""
            echo -e "${YELLOW}如需合并，使用以下命令：${NC}"
            echo "  git merge origin/main"
        else
            echo ""
            echo -e "${RED}✗ 获取失败${NC}"
        fi
    fi
}

# 功能 4: 强制推送
force_push() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  强制推送"
    echo -e "==========================================${NC}"
    echo ""
    echo -e "${RED}⚠️  警告：强制推送会覆盖远程仓库的内容！${NC}"
    echo -e "${RED}⚠️  这可能会导致其他人的代码丢失！${NC}"
    echo ""
    echo -n -e "${YELLOW}确定要强制推送吗？(输入 YES 确认): ${NC}"
    read -r confirm
    
    if [ "$confirm" != "YES" ]; then
        echo -e "${YELLOW}已取消${NC}"
        return
    fi
    
    check_ssh_key || return 1
    setup_git_ssh
    init_git_repo
    setup_remote
    
    cd "$PARENT_DIR"
    echo ""
    echo -e "${BLUE}添加文件...${NC}"
    git add .
    
    if ! git diff --cached --quiet; then
        git commit -m "feat: 强制更新"
    fi
    
    echo ""
    echo -e "${BLUE}强制推送到 GitHub...${NC}"
    
    if ! git show-ref --verify --quiet refs/heads/main; then
        git branch -M main
    fi
    
    # 根据仓库类型选择命令
    if [[ "$REPO_URL" =~ ^git@ ]]; then
        if GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" git push -f origin main; then
            echo ""
            echo -e "${GREEN}✓ 强制推送成功${NC}"
        else
            echo ""
            echo -e "${RED}✗ 强制推送失败${NC}"
        fi
    else
        if git push -f origin main; then
            echo ""
            echo -e "${GREEN}✓ 强制推送成功${NC}"
        else
            echo ""
            echo -e "${RED}✗ 强制推送失败${NC}"
        fi
    fi
}

# 功能 5: 强制拉取并覆盖本地
force_pull() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  强制拉取并覆盖本地"
    echo -e "==========================================${NC}"
    echo ""
    echo -e "${RED}⚠️  警告：强制拉取会覆盖本地的所有更改！${NC}"
    echo -e "${RED}⚠️  所有未提交的本地修改都会丢失！${NC}"
    echo ""
    echo -n -e "${YELLOW}确定要强制拉取吗？(输入 YES 确认): ${NC}"
    read -r confirm
    
    if [ "$confirm" != "YES" ]; then
        echo -e "${YELLOW}已取消${NC}"
        return
    fi
    
    check_ssh_key || return 1
    setup_git_ssh
    init_git_repo
    setup_remote
    
    cd "$PARENT_DIR"
    echo ""
    echo -e "${BLUE}获取远程代码...${NC}"
    
    # 根据仓库类型选择命令
    if [[ "$REPO_URL" =~ ^git@ ]]; then
        GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" git fetch origin
    else
        git fetch origin
    fi
    
    echo ""
    echo -e "${BLUE}重置本地分支到远程状态...${NC}"
    
    # 确保在 main 分支
    git checkout main 2>/dev/null || git checkout -b main
    
    # 强制重置到远程分支
    git reset --hard origin/main
    
    # 清理未跟踪的文件
    git clean -fd
    
    echo ""
    echo -e "${GREEN}✓ 强制拉取成功${NC}"
    echo -e "${YELLOW}本地代码已完全同步到远程状态${NC}"
}

# 功能 6: 查看状态
show_status() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  Git 状态"
    echo -e "==========================================${NC}"
    echo ""
    
    cd "$PARENT_DIR"
    if [ ! -d .git ]; then
        echo -e "${YELLOW}还未初始化 Git 仓库${NC}"
        return
    fi
    
    echo -e "${BLUE}当前分支：${NC}"
    git branch
    
    echo ""
    echo -e "${BLUE}文件状态：${NC}"
    git status
    
    echo ""
    echo -e "${BLUE}远程仓库：${NC}"
    git remote -v
}

# 功能 6: 查看提交历史
show_history() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  提交历史"
    echo -e "==========================================${NC}"
    echo ""
    
    cd "$PARENT_DIR"
    if [ ! -d .git ]; then
        echo -e "${YELLOW}还未初始化 Git 仓库${NC}"
        return
    fi
    
    echo -e "${BLUE}最近 10 次提交：${NC}"
    git log --oneline -10 --graph --decorate
}

# 功能 7: 测试 SSH 连接
test_ssh() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  测试 SSH 连接"
    echo -e "==========================================${NC}"
    echo ""
    
    check_ssh_key || return 1
    
    echo -e "${BLUE}测试 GitHub SSH 连接...${NC}"
    echo -e "${YELLOW}使用密钥: $SSH_KEY${NC}"
    echo ""
    
    if ssh -i "$SSH_KEY" -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✓ SSH 连接成功${NC}"
        echo ""
        echo -e "${BLUE}你的 SSH 密钥已正确配置${NC}"
    else
        echo -e "${RED}✗ SSH 连接失败${NC}"
        echo ""
        echo -e "${YELLOW}你的 SSH 公钥：${NC}"
        cat "${SSH_KEY}.pub"
        echo ""
        echo -e "${YELLOW}请将上面的公钥添加到 GitHub：${NC}"
        echo "1. 访问: https://github.com/settings/keys"
        echo "2. 点击 'New SSH key'"
        echo "3. 粘贴上面的公钥"
        echo "4. 等待 1-2 分钟让 GitHub 同步"
    fi
}

# 功能 7: 配置远程仓库地址
config_remote_url() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  配置远程仓库地址"
    echo -e "==========================================${NC}"
    echo ""
    
    echo -e "${BLUE}当前配置：${NC}"
    echo "仓库地址: $REPO_URL"
    echo ""
    
    cd "$PARENT_DIR"
    if [ -d .git ] && git remote | grep -q "^origin$"; then
        CURRENT_URL=$(git remote get-url origin 2>/dev/null || echo "未设置")
        echo "Git 远程地址: $CURRENT_URL"
        echo ""
    fi
    
    echo -e "${YELLOW}请输入新的仓库地址${NC}"
    echo -e "${CYAN}SSH 格式: git@github.com:用户名/仓库名.git${NC}"
    echo -e "${CYAN}HTTP 格式: https://github.com/用户名/仓库名.git${NC}"
    echo ""
    echo -n -e "${YELLOW}新地址: ${NC}"
    read -r new_url
    
    if [ -z "$new_url" ]; then
        echo -e "${YELLOW}已取消${NC}"
        return
    fi
    
    # 验证格式（支持 SSH 和 HTTP/HTTPS）
    if [[ ! "$new_url" =~ ^(git@.*\.git|https?://.*\.git)$ ]]; then
        echo ""
        echo -e "${RED}✗ 格式错误${NC}"
        echo -e "${YELLOW}支持的格式：${NC}"
        echo "  SSH:   git@github.com:用户名/仓库名.git"
        echo "  HTTPS: https://github.com/用户名/仓库名.git"
        return
    fi
    
    # 更新脚本中的 REPO_URL
    sed -i "s|^REPO_URL=.*|REPO_URL=\"$new_url\"|" "$SCRIPT_DIR/git_function.sh"
    REPO_URL="$new_url"
    
    # 如果已经初始化了 Git，也更新远程地址
    cd "$PARENT_DIR"
    if [ -d .git ]; then
        if git remote | grep -q "^origin$"; then
            git remote set-url origin "$new_url"
        else
            git remote add origin "$new_url"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}✓ 远程仓库地址已更新${NC}"
    echo "新地址: $new_url"
    
    # 提示使用方式
    if [[ "$new_url" =~ ^https?:// ]]; then
        echo ""
        echo -e "${YELLOW}提示：使用 HTTPS 地址时，推送需要输入用户名和密码${NC}"
        echo -e "${YELLOW}或者配置 Git credential helper 来保存凭据${NC}"
    fi
}

# 功能 8: 配置 Git 用户信息
config_git_user() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  配置 Git 用户信息"
    echo -e "==========================================${NC}"
    echo ""
    
    init_git_repo
    cd "$PARENT_DIR"
    
    echo -e "${BLUE}当前配置：${NC}"
    echo "用户名: $(git config user.name || echo '未设置')"
    echo "邮箱: $(git config user.email || echo '未设置')"
    echo ""
    
    echo -n -e "${YELLOW}是否要修改配置？(y/n): ${NC}"
    read -r confirm
    
    if [ "$confirm" != "y" ]; then
        return
    fi
    
    echo ""
    echo -n -e "${YELLOW}请输入 GitHub 用户名: ${NC}"
    read -r username
    git config user.name "$username"
    
    echo -n -e "${YELLOW}请输入 GitHub 邮箱: ${NC}"
    read -r email
    git config user.email "$email"
    
    echo ""
    echo -e "${GREEN}✓ 配置已更新${NC}"
    echo "用户名: $(git config user.name)"
    echo "邮箱: $(git config user.email)"
}

# 功能 9: 生成 SSH 密钥
generate_ssh_key() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  生成 SSH 密钥"
    echo -e "==========================================${NC}"
    echo ""
    
    # 创建 ssh_keys 目录
    mkdir -p "$SCRIPT_DIR/ssh_keys"
    
    if [ -f "$SSH_KEY" ]; then
        echo -e "${YELLOW}SSH 密钥已存在: $SSH_KEY${NC}"
        echo ""
        echo -n -e "${YELLOW}是否要重新生成？(y/n): ${NC}"
        read -r confirm
        if [ "$confirm" != "y" ]; then
            echo -e "${YELLOW}已取消${NC}"
            return
        fi
    fi
    
    echo ""
    echo -n -e "${YELLOW}请输入 GitHub 邮箱: ${NC}"
    read -r email
    
    echo ""
    echo -e "${BLUE}生成 SSH 密钥...${NC}"
    ssh-keygen -t ed25519 -C "$email" -f "$SSH_KEY" -N ""
    
    # 设置正确的权限
    chmod 600 "$SSH_KEY"
    chmod 644 "${SSH_KEY}.pub"
    
    echo ""
    echo -e "${GREEN}✓ SSH 密钥生成成功${NC}"
    echo ""
    echo -e "${BLUE}密钥位置：${NC}"
    echo "  私钥: $SSH_KEY"
    echo "  公钥: ${SSH_KEY}.pub"
    echo ""
    echo -e "${YELLOW}你的 SSH 公钥：${NC}"
    echo -e "${CYAN}=========================================${NC}"
    cat "${SSH_KEY}.pub"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    echo -e "${YELLOW}请将上面的公钥添加到 GitHub：${NC}"
    echo "1. 访问: https://github.com/settings/keys"
    echo "2. 点击 'New SSH key'"
    echo "3. 粘贴上面的公钥"
    echo "4. 保存后使用选项 7 测试连接"
}

# 主循环
main() {
    # 启动时自动添加到 .gitignore
    auto_add_to_gitignore
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                push_to_github
                ;;
            2)
                pull_and_merge
                ;;
            3)
                fetch_only
                ;;
            4)
                force_push
                ;;
            5)
                force_pull
                ;;
            6)
                show_status
                ;;
            7)
                show_history
                ;;
            8)
                config_remote_url
                ;;
            9)
                config_git_user
                ;;
            10)
                generate_ssh_key
                ;;
            t|T)
                test_ssh
                ;;
            0)
                echo ""
                echo -e "${GREEN}再见！${NC}"
                exit 0
                ;;
            *)
                echo ""
                echo -e "${RED}无效的选项，请重新选择${NC}"
                ;;
        esac
        
        echo ""
        echo -n -e "${YELLOW}按 Enter 键继续...${NC}"
        read -r
    done
}

# 运行主程序
main
