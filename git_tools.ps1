﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿# ComfyUI Workflow Manager - Git 功能管理脚本 (PowerShell 版)
# 仓库地址: git@github.com:aGROWLz/Comfy-Workflow-Manager.git

$OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "ComfyUI Workflow Manager - Git Tool"

# 获取脚本所在目录
$scriptPath = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    $scriptPath = Join-Path $PSScriptRoot "git_tools.ps1"
}
$SCRIPT_DIR = Split-Path -Parent $scriptPath
$PARENT_DIR = Split-Path -Parent $SCRIPT_DIR

# 配置 - 使用项目内的 SSH 密钥
$SSH_KEY = Join-Path $SCRIPT_DIR "ssh_keys\id_ed25519_github"

# 获取远程仓库地址 - 优先使用父目录已配置的地址，否则使用默认地址
function Get-RemoteRepoUrl {
    Push-Location $PARENT_DIR
    if (Test-Path ".git") {
        $remotes = git remote
        if ($remotes -contains "origin") {
            $currentUrl = git remote get-url origin 2>$null
            if ($currentUrl) {
                Pop-Location
                return $currentUrl
            }
        }
    }
    Pop-Location
    return "https://github.com/aGROWLz/Butter-Auto-Unpack"  # 默认地址
}

$REPO_URL = Get-RemoteRepoUrl

# 颜色定义
function Write-Color {
    param([string]$Message, [ConsoleColor]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# 自动添加 git_tools 到父目录的 .gitignore
function Auto-AddToGitignore {
    $gitignoreFile = Join-Path $PARENT_DIR ".gitignore"
    $ignorePattern = "git_tools/"
    
    if (-not (Test-Path $gitignoreFile)) {
        $ignorePattern | Out-File -FilePath $gitignoreFile -Encoding utf8
        return
    }
    
    $content = Get-Content $gitignoreFile
    if ($content -notcontains $ignorePattern -and $content -notcontains "git_tools") {
        Add-Content $gitignoreFile "`n# Git tools 工具（自动添加）`n$ignorePattern"
    }
}

# 检查 SSH 密钥
function Check-SSHKey {
    if ($REPO_URL -like "http*") { return $true }
    
    if (-not (Test-Path $SSH_KEY)) {
        Write-Color "✗ SSH 密钥不存在: $SSH_KEY" "Red"
        Write-Color "请先使用选项 10 生成 SSH 密钥" "Yellow"
        return $false
    }
    return $true
}

# 配置 Git SSH 命令
function Setup-GitSSH {
    if ($REPO_URL -like "git@*") {
        $env:GIT_SSH_COMMAND = "ssh -i `"$($SSH_KEY.Replace('\','/'))`" -o IdentitiesOnly=yes"
    }
}

# 初始化 Git 仓库
function Init-GitRepo {
    Push-Location $PARENT_DIR
    if (-not (Test-Path ".git")) {
        Write-Color "初始化 Git 仓库..." "Yellow"
        git init
        Write-Color "✓ Git 仓库初始化完成" "Green"
    }
    Pop-Location
}

# 自动配置 Git 用户信息（如果未配置）
function Auto-ConfigGitUser {
    Push-Location $PARENT_DIR
    $userName = git config user.name 2>$null
    $userEmail = git config user.email 2>$null
    
    if ([string]::IsNullOrWhiteSpace($userName) -or [string]::IsNullOrWhiteSpace($userEmail)) {
        $pubKeyPath = "$SSH_KEY.pub"
        if (Test-Path $pubKeyPath) {
            $pubKeyContent = Get-Content $pubKeyPath -Raw
            $emailMatch = [regex]::Match($pubKeyContent, '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
            if ($emailMatch.Success) {
                $sshEmail = $emailMatch.Value
                Write-Color "检测到 Git 用户信息未配置，自动使用 SSH 密钥中的邮箱设置..." "Yellow"
                if ([string]::IsNullOrWhiteSpace($userName)) {
                    git config user.name "SSH User"
                }
                git config user.email $sshEmail
                Write-Color "✓ 已自动配置 Git 用户信息" "Green"
                Write-Host "  用户名: $(git config user.name)"
                Write-Host "  邮箱: $(git config user.email)"
            }
        }
    }
    Pop-Location
}

# 配置远程仓库
function Setup-Remote {
    Push-Location $PARENT_DIR
    $remotes = git remote
    if ($remotes -contains "origin") {
        $currentUrl = git remote get-url origin
        if ($currentUrl -ne $REPO_URL) {
            Write-Color "更新远程仓库地址..." "Yellow"
            git remote set-url origin $REPO_URL
        }
    } else {
        Write-Color "添加远程仓库..." "Yellow"
        git remote add origin $REPO_URL
    }
    Write-Color "✓ 远程仓库: $REPO_URL" "Green"
    Pop-Location
}

# 辅助函数：设置远程仓库地址
function Setup-RemoteWithUrl {
    param([string]$Url)
    Push-Location $PARENT_DIR
    $remotes = git remote
    if ($remotes -contains "origin") {
        $currentUrl = git remote get-url origin
        if ($currentUrl -ne $Url) {
            git remote set-url origin $Url
        }
    } else {
        git remote add origin $Url
    }
    Pop-Location
}

# 功能 1: 推送到 GitHub
function Push-ToGitHub {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  推送到 GitHub" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    Init-GitRepo
    Auto-ConfigGitUser
    
    Push-Location $PARENT_DIR
    Write-Color "`n添加文件到暂存区..." "Blue"
    git add .
    Write-Color "✓ 文件已添加" "Green"
    
    Write-Color "`n将要提交的文件:" "Blue"
    git status --short
    
    $confirm = Read-Host "`n是否继续提交？(y/n)"
    if ($confirm -ne "y") {
        Write-Color "已取消" "Yellow"
        Pop-Location
        return
    }
    
    if (git diff --cached --quiet) {
        Write-Color "没有需要提交的更改" "Yellow"
    } else {
        $commitMsg = Read-Host "`n请输入提交信息"
        if ([string]::IsNullOrWhiteSpace($commitMsg)) {
            Write-Color "提交信息不能为空，已取消" "Yellow"
            Pop-Location
            return
        }
        git commit -m "$commitMsg"
        Write-Color "✓ 代码已提交" "Green"
    }
    
    # 确保在 main 分支
    $branches = git branch
    if ($branches -notmatch "main") {
        git branch -M main
    }
    
    # 检查是否有 SSH 密钥
    $useSSH = $false
    if (Test-Path $SSH_KEY) {
        $useSSH = $true
        Write-Color "`n检测到 SSH 密钥，尝试使用 SSH 推送..." "Blue"
    } else {
        Write-Color "`n未检测到 SSH 密钥，将使用 HTTPS 推送" "Yellow"
    }
    
    # 尝试 SSH 推送
    $pushSuccess = $false
    if ($useSSH) {
        # 从 REPO_URL 提取 SSH 地址
        $sshUrl = $REPO_URL
        if ($sshUrl -notlike "git@*") {
            # 如果 REPO_URL 是 HTTPS，转换为 SSH
            if ($sshUrl -match "https?://github\.com/([^/]+)/(.+?)(\.git)?$") {
                $username = $matches[1]
                $reponame = $matches[2] -replace "\.git$", ""
                $sshUrl = "git@github.com:${username}/${reponame}.git"
            }
        }
        
        Setup-RemoteWithUrl $sshUrl
        Setup-GitSSH
        
        Write-Color "`n推送到 GitHub (SSH)..." "Blue"
        git push -u origin main 2>$null
        if ($LASTEXITCODE -eq 0) {
            $pushSuccess = $true
            Write-Color "`n✓ SSH 推送成功！" "Green"
            $httpsUrl = $sshUrl -replace "git@github\.com:", "https://github.com/" -replace "\.git$", ""
            Write-Color "仓库地址: $httpsUrl" "Blue"
        } else {
            Write-Color "`nSSH 推送失败，转为 HTTPS 推送..." "Yellow"
        }
    }
    
    # 如果 SSH 推送失败或没有 SSH 密钥，使用 HTTPS
    if (-not $pushSuccess) {
        # 从 REPO_URL 提取 HTTPS 地址
        $httpsUrl = $REPO_URL
        if ($httpsUrl -like "git@*") {
            # 如果 REPO_URL 是 SSH，转换为 HTTPS
            if ($httpsUrl -match "git@github\.com:([^/]+)/(.+)\.git$") {
                $username = $matches[1]
                $reponame = $matches[2]
                $httpsUrl = "https://github.com/${username}/${reponame}.git"
            }
        } elseif ($httpsUrl -notlike "*.git") {
            $httpsUrl = "${httpsUrl}.git"
        }
        
        Setup-RemoteWithUrl $httpsUrl
        $env:GIT_SSH_COMMAND = $null
        
        Write-Color "`n推送到 GitHub (HTTPS)..." "Blue"
        Write-Color "请输入 GitHub 用户名和密码（或 Personal Access Token）" "Yellow"
        
        git push -u origin main
        if ($LASTEXITCODE -eq 0) {
            Write-Color "`n✓ HTTPS 推送成功！" "Green"
            Write-Color "仓库地址: $httpsUrl" "Blue"
        } else {
            Write-Color "`n✗ 推送失败" "Red"
            Write-Color "提示：" "Yellow"
            Write-Host "  - 如果远程有更新，请先选择选项 2 拉取并合并"
            Write-Host "  - 如果使用密码失败，请使用 Personal Access Token"
            Write-Host "  - 生成 Token: https://github.com/settings/tokens"
        }
    }
    Pop-Location
}

# 功能 2: 从远程拉取并合并
function Pull-AndMerge {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  从远程拉取并合并" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    Init-GitRepo
    
    # 检查是否有 SSH 密钥
    $useSSH = $false
    if (Test-Path $SSH_KEY) {
        $useSSH = $true
        Write-Color "`n检测到 SSH 密钥，尝试使用 SSH 拉取..." "Blue"
    } else {
        Write-Color "`n未检测到 SSH 密钥，将使用 HTTPS 拉取" "Yellow"
    }
    
    # 尝试 SSH 拉取
    $pullSuccess = $false
    if ($useSSH) {
        # 从 REPO_URL 提取 SSH 地址
        $sshUrl = $REPO_URL
        if ($sshUrl -notlike "git@*") {
            # 如果 REPO_URL 是 HTTPS，转换为 SSH
            if ($sshUrl -match "https?://github\.com/([^/]+)/(.+?)(\.git)?$") {
                $username = $matches[1]
                $reponame = $matches[2] -replace "\.git$", ""
                $sshUrl = "git@github.com:${username}/${reponame}.git"
            }
        }
        
        Setup-RemoteWithUrl $sshUrl
        Setup-GitSSH
        
        Push-Location $PARENT_DIR
        Write-Color "`n从远程拉取代码 (SSH)..." "Blue"
        git pull origin main --allow-unrelated-histories 2>$null
        if ($LASTEXITCODE -eq 0) {
            $pullSuccess = $true
            Write-Color "`n✓ SSH 拉取并合并成功" "Green"
        } else {
            Write-Color "`nSSH 拉取失败，转为 HTTPS 拉取..." "Yellow"
        }
        Pop-Location
    }
    
    # 如果 SSH 拉取失败或没有 SSH 密钥，使用 HTTPS
    if (-not $pullSuccess) {
        # 从 REPO_URL 提取 HTTPS 地址
        $httpsUrl = $REPO_URL
        if ($httpsUrl -like "git@*") {
            # 如果 REPO_URL 是 SSH，转换为 HTTPS
            if ($httpsUrl -match "git@github\.com:([^/]+)/(.+)\.git$") {
                $username = $matches[1]
                $reponame = $matches[2]
                $httpsUrl = "https://github.com/${username}/${reponame}.git"
            }
        } elseif ($httpsUrl -notlike "*.git") {
            $httpsUrl = "${httpsUrl}.git"
        }
        
        Setup-RemoteWithUrl $httpsUrl
        $env:GIT_SSH_COMMAND = $null
        
        Push-Location $PARENT_DIR
        Write-Color "`n从远程拉取代码 (HTTPS)..." "Blue"
        git pull origin main --allow-unrelated-histories
        if ($LASTEXITCODE -eq 0) {
            Write-Color "`n✓ HTTPS 拉取并合并成功" "Green"
        } else {
            Write-Color "`n✗ 拉取失败" "Red"
            Write-Color "可能存在冲突，请手动解决或使用选项 5 强制拉取" "Yellow"
        }
        Pop-Location
    }
}

# 功能 3: 从远程拉取但不合并
function Fetch-Only {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  从远程拉取但不合并" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    Init-GitRepo
    
    # 检查是否有 SSH 密钥
    $useSSH = $false
    if (Test-Path $SSH_KEY) {
        $useSSH = $true
        Write-Color "`n检测到 SSH 密钥，尝试使用 SSH 获取..." "Blue"
    } else {
        Write-Color "`n未检测到 SSH 密钥，将使用 HTTPS 获取" "Yellow"
    }
    
    # 尝试 SSH 获取
    $fetchSuccess = $false
    if ($useSSH) {
        # 从 REPO_URL 提取 SSH 地址
        $sshUrl = $REPO_URL
        if ($sshUrl -notlike "git@*") {
            # 如果 REPO_URL 是 HTTPS，转换为 SSH
            if ($sshUrl -match "https?://github\.com/([^/]+)/(.+?)(\.git)?$") {
                $username = $matches[1]
                $reponame = $matches[2] -replace "\.git$", ""
                $sshUrl = "git@github.com:${username}/${reponame}.git"
            }
        }
        
        Setup-RemoteWithUrl $sshUrl
        Setup-GitSSH
        
        Push-Location $PARENT_DIR
        Write-Color "`n从远程获取代码 (SSH)..." "Blue"
        git fetch origin 2>$null
        if ($LASTEXITCODE -eq 0) {
            $fetchSuccess = $true
            Write-Color "`n✓ SSH 获取成功" "Green"
        } else {
            Write-Color "`nSSH 获取失败，转为 HTTPS 获取..." "Yellow"
        }
        Pop-Location
    }
    
    # 如果 SSH 获取失败或没有 SSH 密钥，使用 HTTPS
    if (-not $fetchSuccess) {
        # 从 REPO_URL 提取 HTTPS 地址
        $httpsUrl = $REPO_URL
        if ($httpsUrl -like "git@*") {
            # 如果 REPO_URL 是 SSH，转换为 HTTPS
            if ($httpsUrl -match "git@github\.com:([^/]+)/(.+)\.git$") {
                $username = $matches[1]
                $reponame = $matches[2]
                $httpsUrl = "https://github.com/${username}/${reponame}.git"
            }
        } elseif ($httpsUrl -notlike "*.git") {
            $httpsUrl = "${httpsUrl}.git"
        }
        
        Setup-RemoteWithUrl $httpsUrl
        $env:GIT_SSH_COMMAND = $null
        
        Push-Location $PARENT_DIR
        Write-Color "`n从远程获取代码 (HTTPS)..." "Blue"
        git fetch origin
        if ($LASTEXITCODE -eq 0) {
            Write-Color "`n✓ HTTPS 获取成功" "Green"
        } else {
            Write-Color "`n✗ 获取失败" "Red"
        }
        Pop-Location
    }
    
    # 显示远程分支信息
    if ($LASTEXITCODE -eq 0) {
        Push-Location $PARENT_DIR
        Write-Color "`n远程分支：" "Blue"
        git branch -r
        Write-Color "`n提示：代码已获取但未合并，使用以下命令查看差异：" "Yellow"
        Write-Host "  git diff main origin/main"
        Pop-Location
    }
}

# 功能 4: 强制推送
function Force-Push {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  强制推送" "Cyan"
    Write-Color "==========================================" "Cyan"
    Write-Color "⚠️  警告：强制推送会覆盖远程仓库的内容！" "Red"
    Write-Color "⚠️  这可能会导致其他人的代码丢失！" "Red"
    
    $confirm = Read-Host "`n确定要强制推送吗？(输入 YES 确认)"
    if ($confirm -ne "YES") {
        Write-Color "已取消" "Yellow"
        return
    }
    
    Init-GitRepo
    
    Push-Location $PARENT_DIR
    Write-Color "`n添加文件..." "Blue"
    git add .
    if (-not (git diff --cached --quiet)) {
        $commitMsg = Read-Host "`n请输入提交信息"
        if ([string]::IsNullOrWhiteSpace($commitMsg)) {
            Write-Color "提交信息不能为空，已取消" "Yellow"
            Pop-Location
            return
        }
        git commit -m "$commitMsg"
    }
    
    # 确保在 main 分支
    $branches = git branch
    if ($branches -notmatch "main") {
        git branch -M main
    }
    
    # 检查是否有 SSH 密钥
    $useSSH = $false
    if (Test-Path $SSH_KEY) {
        $useSSH = $true
        Write-Color "`n检测到 SSH 密钥，尝试使用 SSH 强制推送..." "Blue"
    } else {
        Write-Color "`n未检测到 SSH 密钥，将使用 HTTPS 强制推送" "Yellow"
    }
    
    # 尝试 SSH 推送
    $pushSuccess = $false
    if ($useSSH) {
        # 从 REPO_URL 提取 SSH 地址
        $sshUrl = $REPO_URL
        if ($sshUrl -notlike "git@*") {
            if ($sshUrl -match "https?://github\.com/([^/]+)/(.+?)(\.git)?$") {
                $username = $matches[1]
                $reponame = $matches[2] -replace "\.git$", ""
                $sshUrl = "git@github.com:${username}/${reponame}.git"
            }
        }
        
        Setup-RemoteWithUrl $sshUrl
        Setup-GitSSH
        
        git push -f origin main 2>$null
        if ($LASTEXITCODE -eq 0) {
            $pushSuccess = $true
            Write-Color "`n✓ SSH 强制推送成功" "Green"
        } else {
            Write-Color "`nSSH 强制推送失败，转为 HTTPS 推送..." "Yellow"
        }
    }
    
    # 如果 SSH 推送失败或没有 SSH 密钥，使用 HTTPS
    if (-not $pushSuccess) {
        # 从 REPO_URL 提取 HTTPS 地址
        $httpsUrl = $REPO_URL
        if ($httpsUrl -like "git@*") {
            if ($httpsUrl -match "git@github\.com:([^/]+)/(.+)\.git$") {
                $username = $matches[1]
                $reponame = $matches[2]
                $httpsUrl = "https://github.com/${username}/${reponame}.git"
            }
        } elseif ($httpsUrl -notlike "*.git") {
            $httpsUrl = "${httpsUrl}.git"
        }
        
        Setup-RemoteWithUrl $httpsUrl
        $env:GIT_SSH_COMMAND = $null
        
        Write-Color "`n强制推送到 GitHub (HTTPS)..." "Blue"
        Write-Color "请输入 GitHub 用户名和密码（或 Personal Access Token）" "Yellow"
        
        git push -f origin main
        if ($LASTEXITCODE -eq 0) {
            Write-Color "`n✓ HTTPS 强制推送成功" "Green"
        } else {
            Write-Color "`n✗ 强制推送失败" "Red"
        }
    }
    Pop-Location
}

# 功能 5: 强制拉取并覆盖本地
function Force-Pull {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  强制拉取并覆盖本地" "Cyan"
    Write-Color "==========================================" "Cyan"
    Write-Color "⚠️  警告：强制拉取会覆盖本地的所有更改！" "Red"
    Write-Color "⚠️  所有未提交的本地修改都会丢失！" "Red"
    
    $confirm = Read-Host "`n确定要强制拉取吗？(输入 YES 确认)"
    if ($confirm -ne "YES") {
        Write-Color "已取消" "Yellow"
        return
    }
    
    Init-GitRepo
    
    # 检查是否有 SSH 密钥
    $useSSH = $false
    if (Test-Path $SSH_KEY) {
        $useSSH = $true
        Write-Color "`n检测到 SSH 密钥，尝试使用 SSH 强制拉取..." "Blue"
    } else {
        Write-Color "`n未检测到 SSH 密钥，将使用 HTTPS 强制拉取" "Yellow"
    }
    
    # 尝试 SSH 强制拉取
    $pullSuccess = $false
    if ($useSSH) {
        # 从 REPO_URL 提取 SSH 地址
        $sshUrl = $REPO_URL
        if ($sshUrl -notlike "git@*") {
            # 如果 REPO_URL 是 HTTPS，转换为 SSH
            if ($sshUrl -match "https?://github\.com/([^/]+)/(.+?)(\.git)?$") {
                $username = $matches[1]
                $reponame = $matches[2] -replace "\.git$", ""
                $sshUrl = "git@github.com:${username}/${reponame}.git"
            }
        }
        
        Setup-RemoteWithUrl $sshUrl
        Setup-GitSSH
        
        Push-Location $PARENT_DIR
        Write-Color "`n获取远程代码 (SSH)..." "Blue"
        git fetch origin 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Color "`n重置本地分支到远程状态..." "Blue"
            git checkout main 2>$null
            if ($LASTEXITCODE -ne 0) {
                git checkout -b main
            }
            git reset --hard origin/main
            git clean -fd
            $pullSuccess = $true
            Write-Color "`n✓ SSH 强制拉取成功" "Green"
        } else {
            Write-Color "`nSSH 获取失败，转为 HTTPS 强制拉取..." "Yellow"
        }
        Pop-Location
    }
    
    # 如果 SSH 强制拉取失败或没有 SSH 密钥，使用 HTTPS
    if (-not $pullSuccess) {
        # 从 REPO_URL 提取 HTTPS 地址
        $httpsUrl = $REPO_URL
        if ($httpsUrl -like "git@*") {
            # 如果 REPO_URL 是 SSH，转换为 HTTPS
            if ($httpsUrl -match "git@github\.com:([^/]+)/(.+)\.git$") {
                $username = $matches[1]
                $reponame = $matches[2]
                $httpsUrl = "https://github.com/${username}/${reponame}.git"
            }
        } elseif ($httpsUrl -notlike "*.git") {
            $httpsUrl = "${httpsUrl}.git"
        }
        
        Setup-RemoteWithUrl $httpsUrl
        $env:GIT_SSH_COMMAND = $null
        
        Push-Location $PARENT_DIR
        Write-Color "`n获取远程代码 (HTTPS)..." "Blue"
        git fetch origin
        if ($LASTEXITCODE -eq 0) {
            Write-Color "`n重置本地分支到远程状态..." "Blue"
            git checkout main 2>$null
            if ($LASTEXITCODE -ne 0) {
                git checkout -b main
            }
            git reset --hard origin/main
            git clean -fd
            Write-Color "`n✓ HTTPS 强制拉取成功" "Green"
        } else {
            Write-Color "`n✗ 强制拉取失败" "Red"
        }
        Pop-Location
    }
}

# 功能 7: 查看提交历史
function Show-History {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  提交历史" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    Push-Location $PARENT_DIR
    if (-not (Test-Path ".git")) {
        Write-Color "还未初始化 Git 仓库" "Yellow"
    } else {
        Write-Color "`n最近 10 次提交：" "Blue"
        git log --oneline -10 --graph --decorate
    }
    Pop-Location
}

# 功能 8: 配置远程仓库地址
function Config-RemoteUrl {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  配置远程仓库地址" "Cyan"
    Write-Color "==========================================" "Cyan"
    Write-Color "当前配置：" "Blue"
    Write-Host "仓库地址: $REPO_URL"
    
    $newUrl = Read-Host "`n请输入新的仓库地址 (SSH 或 HTTPS)"
    if ([string]::IsNullOrWhiteSpace($newUrl)) {
        Write-Color "已取消" "Yellow"
        return
    }
    
    # 更新内存中的变量
    $script:REPO_URL = $newUrl
    
    # 更新脚本文件内容
    if (Test-Path $scriptPath) {
        $content = Get-Content $scriptPath -Raw
        $regex = '(?m)^\$REPO_URL = ".*"'
        $newLine = '$REPO_URL = "' + $newUrl + '"'
        $newContent = [regex]::Replace($content, $regex, $newLine.Replace('$', '$$'))
        $newContent | Out-File -FilePath $scriptPath -Encoding utf8 -NoNewline
        
        # 重新应用 BOM 以确保 PowerShell 识别
        python -c "import os; path = r'$scriptPath'; content = open(path, 'r', encoding='utf-8').read(); open(path, 'w', encoding='utf-8-sig').write(content)" 2>$null
    }
    
    # 同步到 git 配置
    Push-Location $PARENT_DIR
    if (Test-Path ".git") {
        $remotes = git remote
        if ($remotes -contains "origin") {
            git remote set-url origin $newUrl
        } else {
            git remote add origin $newUrl
        }
    }
    Pop-Location
    
    Write-Color "✓ 远程仓库地址已更新" "Green"
}

# 功能 9: 配置 Git 用户信息
function Config-GitUser {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  配置 Git 用户信息" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    Init-GitRepo
    Push-Location $PARENT_DIR
    
    $currentName = git config user.name
    $currentEmail = git config user.email
    Write-Color "当前配置：" "Blue"
    Write-Host "用户名: $currentName"
    Write-Host "邮箱: $currentEmail"
    
    $confirm = Read-Host "`n是否要修改配置？(y/n)"
    if ($confirm -ne "y") {
        Pop-Location
        return
    }
    
    $newName = Read-Host "请输入 GitHub 用户名"
    git config user.name $newName
    $newEmail = Read-Host "请输入 GitHub 邮箱"
    git config user.email $newEmail
    
    Write-Color "✓ 配置已更新" "Green"
    Pop-Location
}

# 功能 10: 生成 SSH 密钥
function Generate-SSHKey {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  生成 SSH 密钥" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    $keyDir = Join-Path $SCRIPT_DIR "ssh_keys"
    if (-not (Test-Path $keyDir)) { New-Item -ItemType Directory -Path $keyDir | Out-Null }
    
    if (Test-Path $SSH_KEY) {
        Write-Color "SSH 密钥已存在: $SSH_KEY" "Yellow"
        $confirm = Read-Host "是否要重新生成？(y/n)"
        if ($confirm -ne "y") { return }
    }
    
    $email = Read-Host "请输入 GitHub 邮箱"
    Write-Color "`n生成 SSH 密钥..." "Blue"
    
    # 确保使用正确的路径格式
    $sshKeyPath = $SSH_KEY.Replace('\', '/')
    ssh-keygen -t ed25519 -C "$email" -f "$sshKeyPath" -N '""'
    
    # 等待文件生成完成
    Start-Sleep -Milliseconds 500
    
    $pubKeyPath = "$SSH_KEY.pub"
    
    if (Test-Path $pubKeyPath) {
        Write-Color "`n✓ SSH 密钥生成成功" "Green"
        Write-Color "密钥位置：" "Blue"
        Write-Host "  私钥: $SSH_KEY"
        Write-Host "  公钥: $pubKeyPath"
        Write-Color "`n你的 SSH 公钥：" "Yellow"
        Write-Host "========================================="
        Get-Content $pubKeyPath
        Write-Host "========================================="
        Write-Color "`n请将上面的公钥添加到 GitHub:" "Yellow"
        Write-Host "  https://github.com/settings/keys"
    } else {
        Write-Color "`n✗ SSH 密钥生成失败或公钥文件未找到" "Red"
        Write-Color "预期路径: $pubKeyPath" "Yellow"
    }
}

# 功能：更新工具自身
function Update-Self {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  更新工具自身 (git_tools)" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    Push-Location $SCRIPT_DIR
    if (-not (Test-Path ".git")) {
        Write-Color "工具目录未关联 Git 仓库" "Yellow"
    } else {
        Write-Color "`n正在从工具仓库拉取更新..." "Blue"
        git pull
        Write-Color "✓ 更新尝试完成" "Green"
    }
    Pop-Location
}

# 功能：推送工具自身
function Push-Self {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  推送工具自身 (git_tools)" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    Push-Location $SCRIPT_DIR
    if (-not (Test-Path ".git")) {
        Write-Color "工具目录未关联 Git 仓库" "Yellow"
    } else {
        Write-Color "`n添加更改..." "Blue"
        git add .
        
        $commitMsg = Read-Host "请输入提交信息 (默认为: update: git_tools tools)"
        if ([string]::IsNullOrWhiteSpace($commitMsg)) {
            $commitMsg = "update: git_tools tools"
        }
        
        git commit -m $commitMsg
        
        Write-Color "`n推送到工具仓库..." "Blue"
        git push
        Write-Color "✓ 推送完成" "Green"
    }
    Pop-Location
}

# 功能：强制推送工具自身
function Force-Push-Self {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  强制推送工具自身 (git_tools)" "Cyan"
    Write-Color "==========================================" "Cyan"
    Write-Color "⚠️  警告：这会覆盖远程工具仓库！" "Red"
    
    $confirm = Read-Host "`n确定要强制推送吗？(输入 YES 确认)"
    if ($confirm -ne "YES") {
        Write-Color "已取消" "Yellow"
        return
    }
    
    Push-Location $SCRIPT_DIR
    if (-not (Test-Path ".git")) {
        Write-Color "工具目录未关联 Git 仓库" "Yellow"
    } else {
        Write-Color "`n添加更改..." "Blue"
        git add .
        git commit -m "force update: git_tools tools (PS)"
        
        Write-Color "`n强制推送到工具仓库..." "Blue"
        git push -f
        Write-Color "✓ 强制推送完成" "Green"
    }
    Pop-Location
}

# 功能 t: 测试 SSH 连接
function Test-SSHConnection {
    Write-Color "`n==========================================" "Cyan"
    Write-Color "  测试 SSH 连接" "Cyan"
    Write-Color "==========================================" "Cyan"
    
    if (-not (Check-SSHKey)) { return }
    
    Write-Color "测试 GitHub SSH 连接..." "Blue"
    Write-Color "使用密钥: $SSH_KEY" "Yellow"
    
    # 临时设置环境变量进行测试
    $oldSsh = $env:GIT_SSH_COMMAND
    $env:GIT_SSH_COMMAND = "ssh -i `"$($SSH_KEY.Replace('\','/'))`" -o IdentitiesOnly=yes"
    
    ssh -i $SSH_KEY -T git@github.com 2>&1 | ForEach-Object {
        if ($_ -match "successfully authenticated") {
            Write-Color "✓ SSH 连接成功" "Green"
        } elseif ($_ -match "Permission denied") {
            Write-Color "✗ SSH 连接失败" "Red"
            Write-Color "`n你的 SSH 公钥：" "Yellow"
            Get-Content "$($SSH_KEY).pub"
        } else {
            Write-Host $_
        }
    }
    
    $env:GIT_SSH_COMMAND = $oldSsh
}

function Show-Menu {
    Clear-Host
    Write-Color "==========================================" "Cyan"
    Write-Color "  ComfyUI Workflow Manager (PowerShell)" "Cyan"
    Write-Color "  Git 功能管理" "Cyan"
    Write-Color "==========================================" "Cyan"
    Write-Host ""
    Write-Color "【Git 操作】" "Blue"
    Write-Color "  1. 推送到 GitHub (SSH/HTTPS 自动)" "Green"
    Write-Color "  2. 从远程拉取并合并" "Green"
    Write-Color "  3. 从远程拉取但不合并 (fetch)" "Green"
    Write-Color "  4. 强制推送 (慎用)" "Green"
    Write-Color "  5. 强制拉取并覆盖本地 (慎用)" "Green"
    Write-Color "  6. 查看状态" "Green"
    Write-Color "  7. 查看提交历史" "Green"
    Write-Host ""
    Write-Color "【工具自身 Git 操作】" "Blue"
    Write-Color "  u. 更新工具自身 (Pull)" "Green"
    Write-Color "  p. 推送工具自身 (Push)" "Green"
    Write-Color "  fp. 强制推送工具自身 (Force Push)" "Green"
    Write-Host ""
    Write-Color "【配置管理】" "Blue"
    Write-Color "  8. 配置远程仓库地址" "Green"
    Write-Color "  9. 配置 Git 用户信息" "Green"
    Write-Color "  10. 生成 SSH 密钥" "Green"
    Write-Host ""
    Write-Color "【测试工具】" "Blue"
    Write-Color "  t. 测试 SSH 连接" "Green"
    Write-Host ""
    Write-Color "  0. 退出" "Green"
    Write-Host ""
    Write-Color "==========================================" "Cyan"
}

# 主循环
Auto-AddToGitignore
while ($true) {
    Show-Menu
    $choice = Read-Host "请输入选项"
    
    switch ($choice) {
        "1" { Push-ToGitHub }
        "2" { Pull-AndMerge }
        "3" { Fetch-Only }
        "4" { Force-Push }
        "5" { Force-Pull }
        "6" { 
            Push-Location $PARENT_DIR
            git status
            Pop-Location
        }
        "7" { Show-History }
        "u" { Update-Self }
        "p" { Push-Self }
        "fp" { Force-Push-Self }
        "8" { Config-RemoteUrl }
        "9" { Config-GitUser }
        "10" { Generate-SSHKey }
        "t" { Test-SSHConnection }
        "0" { Write-Color "`n再见！" "Green"; return }
        default { Write-Color "`n无效选项" "Red" }
    }
    
    Read-Host "`n按 Enter 键继续..."
}
