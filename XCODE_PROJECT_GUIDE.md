# 📦 Xcode 项目创建指南

## 方式 1: 通过 Xcode GUI（推荐，最简单）

### 步骤 1: 创建新项目
1. 打开 **Xcode**
2. 选择 **File → New → Project** (⌘ + Shift + N)
3. 选择 **iOS → App**
4. 点击 **Next**

### 步骤 2: 配置项目
填写以下信息：
- **Product Name**: `PageComparisonDemo`
- **Team**: 选择你的开发团队（或 None）
- **Organization Identifier**: `com.yourname` （任意）
- **Interface**: **Storyboard**
- **Language**: **Swift**
- **取消勾选**: Use Core Data, Include Tests

点击 **Next**

### 步骤 3: 选择保存位置
1. 导航到 `~/Desktop/Projects/`
2. **重要**: 选择 `PageComparisonDemo` 文件夹（已存在的）
3. **取消勾选** "Create Git repository"（我们已有源文件）
4. 点击 **Create**

⚠️ **Xcode 会警告文件夹已存在** - 选择 **Merge**

### 步骤 4: 清理自动生成的文件
删除以下不需要的文件（选中后按 Delete → Move to Trash）:
- `ViewController.swift`
- `Main.storyboard`

### 步骤 5: 添加源代码文件
1. 右键点击项目导航器中的 `PageComparisonDemo` 文件夹
2. 选择 **Add Files to "PageComparisonDemo"...**
3. 导航到 `~/Desktop/Projects/PageComparisonDemo/PageComparisonDemo/`
4. 全选所有文件夹（Core, CellBased, ViewControllerBased, Shared）
5. **勾选**: 
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to targets: PageComparisonDemo
6. 点击 **Add**

### 步骤 6: 更新项目配置

#### 6.1 删除 Storyboard 引用
1. 选中项目根节点（蓝色图标）
2. 选择 **TARGETS → PageComparisonDemo**
3. 选择 **Info** 标签页
4. 找到 **Custom iOS Target Properties**
5. 删除以下键（右键 → Delete）:
   - `Main storyboard file base name`
   - `UIMainStoryboardFile`

#### 6.2 修改 Info.plist
1. 展开 **Application Scene Manifest → Scene Configuration → Application Session Role → Item 0**
2. 删除 `Storyboard Name` 这一行

#### 6.3 设置部署目标
1. 选择 **General** 标签页
2. **Minimum Deployments** → iOS: `15.0`

### 步骤 7: 运行项目
1. 选择模拟器（如 iPhone 15 Pro）
2. 点击 **Run** (⌘ + R)
3. 🎉 应该能看到 Tab Bar 和两种方案的对比界面

---

## 方式 2: 通过命令行（高级用户）

### 使用 xcodegen（需要先安装）

```bash
# 1. 安装 xcodegen
brew install xcodegen

# 2. 创建 project.yml 配置文件
cat > ~/Desktop/Projects/PageComparisonDemo/project.yml << 'EOF'
name: PageComparisonDemo
options:
  bundleIdPrefix: com.demo
targets:
  PageComparisonDemo:
    type: application
    platform: iOS
    deploymentTarget: "15.0"
    sources:
      - PageComparisonDemo
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.demo.PageComparisonDemo
        INFOPLIST_FILE: PageComparisonDemo/Info.plist
EOF

# 3. 生成 Xcode 项目
cd ~/Desktop/Projects/PageComparisonDemo
xcodegen generate

# 4. 打开项目
open PageComparisonDemo.xcodeproj
```

---

## 常见问题

### Q1: "No such module 'UIKit'" 错误

**原因**: LSP 找不到模块，因为还没有 .xcodeproj  
**解决**: 创建 Xcode 项目后自动解决

### Q2: 运行时崩溃：找不到 Scene Delegate

**原因**: Info.plist 配置不正确  
**解决**: 
1. 打开 Info.plist
2. 确保 `UISceneDelegateClassName` = `$(PRODUCT_MODULE_NAME).SceneDelegate`

### Q3: Build 失败：找不到某些文件

**原因**: 文件没有添加到 Target  
**解决**:
1. 选中任意 .swift 文件
2. 打开右侧 File Inspector
3. 确保 **Target Membership** 中 `PageComparisonDemo` 被勾选

### Q4: 黑屏，没有显示任何内容

**原因**: Scene Delegate 没有正确配置  
**解决**: 检查 `SceneDelegate.swift` 中是否设置了 `window?.rootViewController`

---

## 验证项目配置

运行以下检查确保一切正常：

### ✅ 检查清单

1. **项目结构**
```bash
cd ~/Desktop/Projects/PageComparisonDemo
ls -la PageComparisonDemo/
# 应该看到: Core/, CellBased/, ViewControllerBased/, Shared/, AppDelegate.swift, SceneDelegate.swift
```

2. **文件数量**
```bash
find PageComparisonDemo -name "*.swift" | wc -l
# 应该有 23-25 个 Swift 文件
```

3. **编译检查**
- 在 Xcode 中按 ⌘ + B
- 应该成功编译，没有错误

4. **运行检查**
- 按 ⌘ + R 运行
- 应该看到带有两个 Tab 的界面
- 底部显示性能监控数据

---

## 📸 预期效果

运行成功后，你应该看到：

### Tab 1: Cell-Based
- 蓝色背景的静态头部
- 可滑动的 Segment Header（Overview/Details/Analytics）
- 三个可左右滑动的页面
- 底部实时显示 FPS 和内存

### Tab 2: ViewController-Based  
- 紫色背景的静态头部
- 相同的 Segment Header
- 三个可左右滑动的页面（但是 ViewController）
- 点击 Overview/Details 中的项目可以 push 详情页
- 底部实时显示 FPS 和内存

### 控制台输出
运行时应该看到类似：
```
🎮 [Overview VC] viewDidLoad
👀 [Overview VC] viewWillAppear
✅ [Overview VC] viewDidAppear
📱 [Cell-Based] Page switch duration: 0.018s
🎮 [VC-Based] Page switch duration: 0.125s
```

---

## 🆘 需要帮助？

如果遇到问题：

1. **查看完整 README.md** - 包含详细的架构说明
2. **检查控制台输出** - 查看是否有错误日志
3. **对比两个 Tab** - 理解两种方案的差异
4. **阅读代码注释** - 每个关键文件都有详细注释

---

祝你成功创建项目！🎉
