# Smart Dialer — BlackBerry 风格智能拨号 App

一个 iOS 全键盘快速拨号应用，模仿黑莓手机的拨号体验。

## 功能特点

- **QWERTY 全键盘** — 类黑莓风格的三行物理键盘布局，支持按键动画反馈
- **拼音首字母搜索** — 输入 `zs` 即可找到 `张三`（Zhang San）
- **拼音全拼搜索** — 输入 `zhang` 即可找到 `张三`
- **英文名搜索** — 输入 `jd` 即可找到 `John Doe`
- **昵称搜索** — 支持搜索联系人的昵称字段
- **公司名搜索** — 支持搜索联系人的公司/组织名称
- **手机号搜索** — 输入号码的任意部分即可匹配
- **一键拨号** — 点击联系人直接拨打（或选择号码后拨打）
- **深色主题** — 完全深色界面，模拟黑莓经典风格
- **Swift 6 并发安全** — 使用最新的 Swift 并发模型

## 如何使用

1. **首次启动**：授予通讯录访问权限
2. **输入搜索**：在键盘上输入联系人姓名缩写
3. **拨号**：点击搜索结果中的联系人，确认后拨出

### 搜索示例

| 输入 | 结果 |
|------|------|
| `zs` | 张三 (Zhang San) |
| `lisi` | 李四 (Li Si) |
| `jd` | John Doe |
| `138` | 所有以 138 开头的号码 |
| `小明` | 昵称为"小明"的联系人 |
| `acme` | 公司名为 Acme 的联系人 |

## 项目结构

```
qdialer/
├── qdialer/
│   ├── qdialerApp.swift              # App 入口
│   ├── ContentView.swift             # 主界面
│   ├── Models/
│   │   └── ContactModel.swift        # 联系人数据模型
│   ├── Services/
│   │   ├── PinyinService.swift       # 拼音转换 & 搜索匹配
│   │   └── ContactService.swift      # 通讯录框架服务
│   ├── ViewModels/
│   │   └── ContactSearchViewModel.swift  # 搜索逻辑
│   ├── Views/
│   │   ├── KeyboardView.swift        # QWERTY 键盘
│   │   ├── SearchBarView.swift       # 搜索栏
│   │   └── ContactRowView.swift      # 联系人列表项
│   ├── Assets.xcassets/              # App 图标 & 主题色
│   └── Info.plist                    # App 配置
├── qdialer.xcodeproj/                # Xcode 项目
├── generate_project.py               # 项目文件生成器
└── README.md
```

## 系统要求

- iOS 17.0+
- Xcode 16+
- Swift 6.0

## 打开项目

```bash
cd /Users/xiaodongzhou/qdialer
open qdialer.xcodeproj
```

然后在 Xcode 中选择一个 iOS 17+ 模拟器，点击 ▶ 运行即可。

## 构建说明

项目包含自动生成的 `.xcodeproj` 文件。如果需要重新生成：

```bash
cd /Users/xiaodongzhou/qdialer
python3 generate_project.py
```

## 技术栈

- SwiftUI — 声明式 UI
- Contacts 框架 — 通讯录访问
- CFStringTransform — 中文拼音转换
- Swift 6 — 严格并发检查
