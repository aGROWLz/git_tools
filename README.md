# Git Tools - 独立 Git 管理工具

这是一个独立的 Git 管理工具，使用项目内的 SSH 密钥进行 Git 操作，无需依赖系统的 `~/.ssh` 目录。

## 特点

- ✅ 使用项目内的 SSH 密钥，不依赖系统 SSH 配置
- ✅ 支持 SSH 和 HTTPS 两种仓库地址格式
- ✅ **智能地址转换**：输入 HTTPS 自动生成对应的 SSH 地址
- ✅ 无需账号密码（SSH 模式），或使用账号密码（HTTPS 模式）
- ✅ 密钥存储在项目的 `ssh_keys` 目录中
- ✅ 完整的 Git 操作菜单界面
- ✅ 支持生成、测试和使用 SSH 密钥
- ✅ 自动添加到父项目的 `.gitignore`，保护敏感信息
- ✅ 支持自定义远程仓库地址
- ✅ 支持强制拉取，解决冲突问题

## 目录结构

```
git_tools/
├── git_tools.sh       # 主脚本
├── ssh_keys/             # SSH 密钥目录（自动创建）
│   ├── id_ed25519_github      # 私钥
│   └── id_ed25519_github.pub  # 公钥
└── README.md             # 说明文档
```

## 使用方法

### 1. 首次使用

```bash
cd git_function
chmod +x git_function.sh
./git_function.sh
```

### 2. 生成 SSH 密钥（SSH 模式）

如果使用 SSH 地址，需要先生成密钥。运行脚本后，选择选项 `10` 生成 SSH 密钥：

```
请输入选项: 10
```

按照提示输入你的 GitHub 邮箱，脚本会自动生成密钥并显示公钥。

### 3. 添加公钥到 GitHub（SSH 模式）

1. 复制脚本显示的公钥内容
2. 访问 https://github.com/settings/keys
3. 点击 "New SSH key"
4. 粘贴公钥并保存

### 4. 测试连接（SSH 模式）

选择选项 `t` 测试 SSH 连接：

```
请输入选项: t
```

如果显示 "✓ SSH 连接成功"，说明配置正确。

### 5. 配置远程仓库（可选）

如果需要修改仓库地址，选择选项 `8`：

```
请输入选项: 8
```

支持两种格式：
- **SSH 格式**：`git@github.com:用户名/仓库名.git`（需要 SSH 密钥）
- **HTTPS 格式**：`https://github.com/用户名/仓库名.git`（需要账号密码）

### 6. 开始使用

现在你可以使用其他选项进行 Git 操作：

**【Git 操作】**
- `1` - 推送到 GitHub
- `2` - 从远程拉取并合并
- `3` - 从远程拉取但不合并
- `4` - 强制推送（慎用）
- `5` - 强制拉取并覆盖本地（慎用）
- `6` - 查看状态
- `7` - 查看提交历史

**【配置管理】**
- `8` - 配置远程仓库地址
- `9` - 配置 Git 用户信息
- `10` - 生成 SSH 密钥

**【测试工具】**
- `t` - 测试 SSH 连接

## 配置说明

### 仓库地址格式

工具支持两种仓库地址格式，并且**支持智能转换**：

**1. SSH 格式（推荐）**
```
git@github.com:用户名/仓库名.git
```
- 优点：无需每次输入密码，更安全
- 需要：生成 SSH 密钥并添加到 GitHub
- 适合：频繁推送拉取的场景

**2. HTTPS 格式**
```
https://github.com/用户名/仓库名.git
```
- 优点：无需配置 SSH 密钥
- 需要：每次操作输入用户名和密码（或配置 credential helper）
- 适合：临时使用或不想配置 SSH 的场景

**智能转换功能：**
- 输入 HTTPS 地址时，脚本会自动提取用户名和仓库名
- 自动生成对应的 SSH 地址并保存
- 配置 SSH 密钥后，可以无缝切换到免密模式
- 示例：
  ```
  输入: https://github.com/aGROWLz/Comfy-Workflow-Manager.git
  自动生成: git@github.com:aGROWLz/Comfy-Workflow-Manager.git
  ```

### 修改仓库地址

有两种方式修改仓库地址：

**方式 1：使用菜单（推荐）**
```
运行脚本后选择选项 8，输入新的仓库地址
支持 SSH 或 HTTPS 格式，输入 HTTPS 会自动生成 SSH 地址
```

**方式 2：手动编辑**
```bash
# 编辑 git_function.sh 文件，修改 REPO_URL 变量
REPO_URL="你的仓库地址"
```

**智能转换示例：**
```bash
# 输入 HTTPS 地址
新地址: https://github.com/aGROWLz/Comfy-Workflow-Manager.git

# 脚本输出
检测到 HTTPS 地址，已自动生成对应的 SSH 地址：
SSH: git@github.com:aGROWLz/Comfy-Workflow-Manager.git

✓ 远程仓库地址已更新
Git 远程地址: https://github.com/aGROWLz/Comfy-Workflow-Manager.git
SSH 地址（已保存）: git@github.com:aGROWLz/Comfy-Workflow-Manager.git
```

### SSH 密钥位置

密钥自动存储在：
- 私钥：`git_function/ssh_keys/id_ed25519_github`
- 公钥：`git_function/ssh_keys/id_ed25519_github.pub`

## 安全提示

⚠️ **重要**：
- 私钥文件（`id_ed25519_github`）不应该提交到 Git 仓库
- 脚本会**自动**将 `git_function/` 添加到父项目的 `.gitignore` 中
- 首次运行脚本时会自动保护你的密钥文件
- 不要分享你的私钥给任何人

### 自动 .gitignore 保护

脚本启动时会自动检查父目录的 `.gitignore` 文件：
- 如果不存在，会自动创建并添加 `git_function/` 规则
- 如果已存在该规则，不会重复添加
- 确保 SSH 密钥等敏感信息不会被意外提交

## 故障排除

### SSH 连接失败

1. 确认公钥已正确添加到 GitHub
2. 等待 1-2 分钟让 GitHub 同步
3. 检查密钥文件权限（私钥应为 600）
4. 使用选项 t 重新测试连接

### 推送失败

1. 先使用选项 2 拉取远程更新
2. 解决可能的冲突
3. 如果想强制覆盖远程，使用选项 4（慎用）

### 拉取失败或有冲突

1. 如果想保留本地更改，手动解决冲突
2. 如果想完全使用远程版本，使用选项 5 强制拉取
3. 选项 5 会**覆盖所有本地更改**，使用前请确认

### HTTPS 每次都要输入密码

配置 Git credential helper 来保存凭据：

```bash
# 永久保存密码（明文存储）
git config --global credential.helper store

# 或者缓存密码 15 分钟
git config --global credential.helper cache
```

### 权限问题

确保脚本有执行权限：

```bash
chmod +x git_function.sh
```

## 使用场景

### 场景 1：SSH 模式（推荐）

适合需要频繁推送拉取的项目：

1. 生成 SSH 密钥（选项 10）
2. 添加公钥到 GitHub
3. 配置 SSH 仓库地址（选项 8）
4. 测试连接（选项 t）
5. 开始使用

### 场景 2：HTTPS 模式

适合临时使用或不想配置 SSH：

1. 配置 HTTPS 仓库地址（选项 8）
   - 输入：`https://github.com/用户名/仓库名.git`
   - 脚本会自动生成对应的 SSH 地址
2. 直接开始使用（会提示输入密码）
3. 可选：配置 credential helper 保存密码

### 场景 3：HTTPS 转 SSH（推荐）

先用 HTTPS 快速开始，后续升级到 SSH 免密：

1. 配置 HTTPS 地址（选项 8）
   - 脚本自动生成 SSH 地址
2. 使用 HTTPS 推送拉取（需要密码）
3. 想要免密时：
   - 生成 SSH 密钥（选项 10）
   - 添加公钥到 GitHub
   - 测试连接（选项 t）
   - 自动切换到 SSH 模式，无需重新配置地址

### 场景 4：强制同步

当本地和远程有冲突，想完全使用远程版本：

1. 使用选项 5 强制拉取
2. 本地所有更改会被覆盖
3. 代码完全同步到远程状态

## 与其他项目集成

这个工具可以独立使用，也可以集成到其他项目中：

1. 将 `git_function` 文件夹复制到目标项目
2. 运行脚本会自动添加到目标项目的 `.gitignore`
3. 配置仓库地址（选项 8）
4. 如果使用 SSH，生成密钥或复用现有密钥
5. 开始使用

**重要说明：**
- `git_function` 可以有自己的 `.git` 仓库（用于工具本身的版本管理）
- 运行脚本时，所有 Git 操作都针对**外部项目**的 `.git`
- 两个 Git 仓库互不干扰

## 工作原理

```
外部项目/
├── .git/                    ← 脚本操作这个 Git 仓库
├── .gitignore              ← 自动添加 git_function/ 规则
├── git_function/
│   ├── .git/               ← git_function 自己的仓库（可选）
│   ├── git_function.sh     ← 运行这个脚本
│   ├── ssh_keys/           ← SSH 密钥（自动忽略）
│   │   ├── id_ed25519_github
│   │   └── id_ed25519_github.pub
│   └── README.md
└── 其他项目文件...
```

## 许可证

MIT License
