# 📚 Section 0 详解

## 什么是 Section 0？

在这个项目中，CollectionView 被分为 **2 个 Section**：

```
┌─────────────────────────────────────┐
│  Section 0: 静态头部区域             │  ← 固定高度 200pt
│  "🎮 ViewController-Based"          │
│  "Pages are UIViewController..."    │
├─────────────────────────────────────┤
│  [Overview] [Details] [Analytics]   │  ← Section 1: Sticky Header
├─────────────────────────────────────┤
│  ╔═══════════════════════════════╗  │
│  ║  Section 1: 横向分页区域       ║  │  ← 可左右滑动
│  ║  - Overview Page              ║  │
│  ║  - Details Page               ║  │
│  ║  - Analytics Page             ║  │
│  ╚═══════════════════════════════╝  │
└─────────────────────────────────────┘
```

---

## Section 0 的作用

### 1. 显示方案标识
告诉用户当前是哪种实现方案：
- **Cell-Based Tab**: "📊 Cell-Based Implementation"
- **VC-Based Tab**: "🎮 ViewController-Based"

### 2. 区分两种方案
通过不同的背景色和文案，让用户一眼看出区别：
- Cell-Based: 蓝色背景
- VC-Based: 紫色背景

---

## Section 0 的实现细节

### 数据源配置

```swift
private func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
    
    // 添加两个 Section
    snapshot.appendSections([0, 1])
    
    // Section 0: 只有 1 个 item (静态头部)
    snapshot.appendItems([0], toSection: 0)
    
    // Section 1: 有 3 个 item (三个可滑动的页面)
    snapshot.appendItems([0, 1, 2], toSection: 1)
    
    dataSource.apply(snapshot, animatingDifferences: false)
}
```

### 数据结构

| Section | Items | 说明 |
|---------|-------|------|
| **0** | `[0]` | 静态头部 Cell |
| **1** | `[0, 1, 2]` | 三个分页 (Overview, Details, Analytics) |

---

## Section 0 的 Layout 配置

### 布局特点

```swift
private func createStaticHeaderSection() -> NSCollectionLayoutSection {
    let item = NSCollectionLayoutItem(
        layoutSize: .init(
            widthDimension: .fractionalWidth(1.0),  // 宽度：100% 屏幕宽度
            heightDimension: .absolute(200)         // 高度：固定 200pt
        )
    )
    
    let group = NSCollectionLayoutGroup.vertical(
        layoutSize: .init(
            widthDimension: .fractionalWidth(1.0),  // 宽度：100%
            heightDimension: .absolute(200)         // 高度：200pt
        ),
        subitems: [item]
    )
    
    return NSCollectionLayoutSection(group: group)
}
```

### 关键点
- ✅ **固定高度**: 200pt，不会变化
- ✅ **全宽**: 占满整个 CollectionView 宽度
- ✅ **垂直布局**: 使用 `NSCollectionLayoutGroup.vertical`
- ✅ **静态**: 不可滚动，始终在顶部

---

## Section 0 的 Cell 实现

### VCBasedStaticHeaderCell

```swift
class VCBasedStaticHeaderCell: UICollectionViewCell {
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "🎮 ViewController-Based\nPages are UIViewController subclasses"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemPurple.withAlphaComponent(0.1)  // 紫色背景
        contentView.layer.cornerRadius = 12
        contentView.addSubview(label)
        // ... layout constraints
    }
}
```

### 内容

| 方案 | 背景色 | 文本 |
|------|--------|------|
| **Cell-Based** | 蓝色 (.systemBlue) | 📊 Cell-Based Implementation<br>Pages are UIView subclasses |
| **VC-Based** | 紫色 (.systemPurple) | 🎮 ViewController-Based<br>Pages are UIViewController subclasses |

---

## DataSource 如何处理 Section 0

```swift
private func configureDataSource() {
    dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { 
        [weak self] collectionView, indexPath, item in
        
        switch indexPath.section {
        case 0:
            // ✅ Section 0: 返回静态头部 Cell
            print("✅ [VCBased] Creating static header cell")
            let cell = collectionView.dequeueReusableCell(VCBasedStaticHeaderCell.self, for: indexPath)
            cell.backgroundColor = .red  // 用于调试，实际会被 contentView 覆盖
            return cell
            
        case 1:
            // Section 1: 返回页面容器 Cell
            let cell = collectionView.dequeueReusableCell(ViewControllerContainerCell.self, for: indexPath)
            let pageType = PageType.allCases[item]
            let pageVC = self.createViewController(for: pageType)
            cell.configure(viewController: pageVC, parent: self)
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
}
```

---

## 完整的视图层级

```
UICollectionView
├── Section 0 (静态头部)
│   └── Item 0: VCBasedStaticHeaderCell
│       └── Label: "🎮 ViewController-Based..."
│
└── Section 1 (分页区域)
    ├── Item 0: ViewControllerContainerCell
    │   └── OverviewPageViewController
    ├── Item 1: ViewControllerContainerCell
    │   └── DetailsPageViewController
    └── Item 2: ViewControllerContainerCell
        └── AnalyticsPageViewController
```

---

## 为什么需要 Section 0？

### 1. 教学目的
清楚地标识当前使用的是哪种实现方案，帮助理解差异。

### 2. 视觉区分
通过不同颜色和文案，让用户一眼看出两个 Tab 的区别。

### 3. 模拟真实场景
许多 App 都有类似的布局：
- 顶部固定的头部信息
- 下方可滑动的内容区域
- 例如：微博详情页、小红书详情页

### 4. 演示 Compositional Layout
展示如何在同一个 CollectionView 中使用不同的 Layout：
- Section 0: 垂直固定布局
- Section 1: 横向分页布局

---

## 调试 Section 0

### 如果 Section 0 不显示

**1. 检查控制台日志**
运行后应该看到：
```
📊 [VCBased] Applying snapshot - Sections: 2, Items in section 0: 1, Items in section 1: 3
🔍 [VCBased DataSource] section: 0, item: 0
✅ [VCBased] Creating static header cell
```

**2. 检查 Cell 是否注册**
```swift
collectionView.register(VCBasedStaticHeaderCell.self)  // 必须在 setupCollectionView 中
```

**3. 检查 Layout 高度**
```swift
heightDimension: .absolute(200)  // 确保不是 0
```

**4. 添加可视化调试**
```swift
case 0:
    let cell = collectionView.dequeueReusableCell(VCBasedStaticHeaderCell.self, for: indexPath)
    cell.backgroundColor = .red           // 红色背景
    cell.layer.borderWidth = 5            // 边框
    cell.layer.borderColor = UIColor.yellow.cgColor
    return cell
```

---

## 总结

**Section 0** 是一个简单但重要的组件：
- 📍 **位置**: CollectionView 的第一个 Section
- 📏 **高度**: 固定 200pt
- 🎨 **内容**: 显示方案名称和说明文字
- 🎯 **作用**: 教学标识 + 视觉区分

它不是分页内容的一部分，而是一个固定的静态头部，用于标识和说明当前的实现方案。
