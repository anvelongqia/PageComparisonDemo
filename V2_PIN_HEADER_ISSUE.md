# V2 吸顶效果问题分析

## 当前问题

**现象**：V2 版本没有吸顶效果，Header 不会平滑滚动到吸顶位置。

---

## 根本原因分析

### 核心问题：我们只监听内层，不监听外层

```swift
private func setupScrollObserver(for list: JXPagingListViewDelegate, at index: Int) {
    let scrollView = list.listScrollView()  // 只监听内层
    
    let observer = scrollView.observe(\.contentOffset, options: [.new, .old]) {
        self.handleNestedScroll(...)
    }
}
```

**问题**：
- 我们只在内层滚动时才触发 `handleNestedScroll`
- 当用户在内层区域滑动时，实际上是**内层的 ScrollView 在响应手势**
- 我们强制重置内层为 0，但这**不会自动让外层滚动**

---

## 正确的实现方式

### 官方 JXPagingView 的架构

官方使用的是 **UITableView** 作为外层容器：

```
UITableView (mainTableView)
├─ TableHeaderView (可滚动的 Header)
├─ Section Header (吸顶的 Segment)
└─ Cell (包含 ListContainerView)
    └─ 各个内层 List
```

**关键点**：
1. 外层是 TableView，自带滚动能力
2. 内层的 List 放在 TableView 的 Cell 中
3. 手势由 TableView 统一处理
4. 通过 `scrollViewDidScroll` 回调同步状态

### 我们当前的架构（V2）

```
UICollectionView (mainCollectionView)  ← 正交滚动布局
├─ Header (通过 SupplementaryView)
└─ Cells (横向正交滚动)
    └─ 各个内层 List
```

**问题**：
- UICollectionView 使用 CompositionalLayout
- Header 是通过 `NSCollectionLayoutBoundarySupplementaryItem` 添加的
- 这种 Header **不会自动产生吸顶效果**
- 我们需要手动控制

---

## 解决方案

### 方案 1：修改 Layout 配置（推荐）

让 Header 支持吸顶：

```swift
let header = NSCollectionLayoutBoundarySupplementaryItem(
    layoutSize: headerSize,
    elementKind: UICollectionView.elementKindSectionHeader,
    alignment: .top,
    absoluteOffset: CGPoint(x: 0, y: 0)
)
header.pinToVisibleBounds = true  // ✅ 启用吸顶
header.zIndex = 1000               // ✅ 设置层级
```

**优点**：
- 系统自动处理吸顶
- 不需要手动控制

**缺点**：
- 吸顶的是整个 Header，包括渐变背景
- 可能不符合需求（通常只吸顶 Segment 部分）

---

### 方案 2：分离 Header 和 Segment

将 Header 分为两部分：

```
mainCollectionView
├─ 可滚动的 Header (SupplementaryView，不吸顶)
├─ 吸顶的 Segment (SupplementaryView，pinToVisibleBounds = true)
└─ Cells
```

**实现**：

```swift
// 创建两个 SupplementaryView
let headerItem = NSCollectionLayoutBoundarySupplementaryItem(...)
headerItem.pinToVisibleBounds = false  // 不吸顶

let segmentItem = NSCollectionLayoutBoundarySupplementaryItem(...)
segmentItem.pinToVisibleBounds = true  // 吸顶
segmentItem.zIndex = 1000

section.boundarySupplementaryItems = [headerItem, segmentItem]
```

**优点**：
- 符合常见需求
- 系统自动处理

---

### 方案 3：监听外层滚动（当前尝试）

监听外层 CollectionView 的滚动：

```swift
extension JXPagingViewV2: UICollectionViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 当外层滚动时，同步内层状态
        let mainOffsetY = scrollView.contentOffset.y
        let headerHeight = dataSource?.heightForHeader(in: self) ?? 0
        
        if mainOffsetY < headerHeight {
            // 外层未吸顶，重置所有内层
            for (_, list) in cachedListViews {
                list.listScrollView().contentOffset = .zero
            }
        }
    }
}
```

**问题**：
- 当前我们已经在 `scrollViewDidScroll` 中有回调
- 但没有实际的同步逻辑

---

## 当前代码的问题

### 为什么 Header 不会滚动？

**代码片段**：
```swift
if mainOffsetY < maxMainOffsetY {
    // 外层未吸顶
    if listOffsetY != minListOffsetY {
        listScrollView.contentOffset = CGPoint(x: 0, y: minListOffsetY)
    }
}
```

**问题分析**：
1. 用户在内层区域向上滑动
2. 内层的 `contentOffset` 增加（例如从 0 → 10）
3. 触发 KVO，调用 `handleNestedScroll`
4. 我们检测到外层未吸顶，重置内层为 0
5. **但是外层不会自动滚动！**

**为什么？**
- 因为用户的手势是作用在**内层的 ScrollView** 上
- 我们重置内层只是修改了 `contentOffset`
- **不会触发外层的滚动**
- 外层只有在**用户直接滑动外层**时才会滚动

---

## 建议的修复方案

### 方案 A：使用 UITableView 替代 UICollectionView

参考官方实现，使用 UITableView：

```swift
UITableView
├─ tableHeaderView (可滚动)
├─ section header (吸顶)
└─ cell (包含正交滚动的 ContainerView)
```

**优点**：
- 和官方实现一致
- Header 自然滚动
- Section Header 自然吸顶

---

### 方案 B：手动传递滚动（复杂）

在 `handleNestedScroll` 中，当检测到内层滚动时：

1. 计算内层的滚动增量
2. 将增量应用到外层
3. 重置内层

```swift
if mainOffsetY < maxMainOffsetY {
    // 获取增量
    let delta = listOffsetY - (change.oldValue?.y ?? 0)
    
    // 重置内层
    listScrollView.contentOffset = .zero
    
    // 应用到外层
    let newMainOffset = min(mainOffsetY + delta, headerHeight)
    mainScrollView.contentOffset = CGPoint(x: 0, y: newMainOffset)
}
```

**问题**：
- 在 KVO 回调中修改 `contentOffset` 会循环触发
- 可能导致滚动不流畅

---

## 临时解决方案

### 快速修复：启用 Header 吸顶

修改 `createOrthogonalLayout` 方法：

```swift
let header = NSCollectionLayoutBoundarySupplementaryItem(...)
header.pinToVisibleBounds = true  // 启用吸顶
```

**结果**：
- Header 会吸顶（包括渐变背景）
- 至少有吸顶效果
- 后续可以优化（分离 Header 和 Segment）

---

## 下一步

建议采用 **方案 2：分离 Header 和 Segment**：

1. 修改 Layout，创建两个 SupplementaryView
2. 上部分：渐变背景 + 标题（不吸顶）
3. 下部分：Segment 控件（吸顶）
4. 保持当前的滚动控制逻辑

这样既能保持正交滚动，又能有正确的吸顶效果。

---

**当前文件**：`JXPagingViewV2.swift`  
**问题行**：第 50-84 行（createOrthogonalLayout 方法）  
**建议修改**：启用 `header.pinToVisibleBounds = true` 或分离 Header
