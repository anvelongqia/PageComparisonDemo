# 🎯 实现微博/小红书式吸顶效果

## 📱 效果演示

### 你想要的效果

```
【初始状态】
┌─────────────────────────────┐
│  🎮 ViewController-Based    │ ← Section 0: 顶部内容（所有分页共享）
│  (200pt 高度)               │
├─────────────────────────────┤
│ [Overview][Details][Analytics] │ ← Segment Header
├─────────────────────────────┤
│  Page 内容                   │ ← Section 1: 分页内容
│  • Item 1                   │
│  • Item 2                   │
│  • Item 3                   │
└─────────────────────────────┘

⬇️ 向上滚动

【滚动中 - 一起向上移动】
┌─────────────────────────────┐
│  ViewController-Based       │ ← 顶部内容向上滚动
│                             │
├─────────────────────────────┤
│ [Overview][Details][Analytics] │ ← Segment 也在向上移动
├─────────────────────────────┤
│  • Item 3                   │
│  • Item 4                   │ ← Page 内容也在滚动
│  • Item 5                   │
│  • Item 6                   │
└─────────────────────────────┘

⬇️ 继续滚动

【Segment 到达顶部 - 吸顶！】
┌─────────────────────────────┐
│ [Overview][Details][Analytics] │ ← Segment 吸附在导航栏下方
├─────────────────────────────┤
│  • Item 8                   │
│  • Item 9                   │ ← 只有 Page 内容继续滚动
│  • Item 10                  │
│  • Item 11                  │
│  • Item 12                  │
└─────────────────────────────┘
         ↑
    顶部内容已经完全滚出屏幕
```

---

## ✅ 实现原理

### 关键配置

```swift
private func createPagingSection() -> NSCollectionLayoutSection {
    // ... section 配置
    
    let header = NSCollectionLayoutBoundarySupplementaryItem(
        layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44)),
        elementKind: UICollectionView.elementKindSectionHeader,
        alignment: .top
    )
    
    // ⭐⭐⭐ 核心设置
    header.pinToVisibleBounds = true  // 吸顶效果
    header.zIndex = 2                 // 确保在最上层
    
    section.boundarySupplementaryItems = [header]
    return section
}
```

### 工作原理

1. **Section 0 (顶部内容)**
   - 高度固定 200pt
   - 普通的 Cell，会随滚动移动
   - 滚动时会向上移出屏幕

2. **Section 1 的 Header (Segment)**
   - `pinToVisibleBounds = true`
   - 初始状态：位于 Section 1 的顶部（Section 0 下方）
   - 滚动时：跟随 Section 1 向上移动
   - 到达屏幕顶部后：**吸附住**，不再向上移动

3. **Section 1 的 Content (Page 内容)**
   - 横向分页的 Page ViewControllers
   - Segment 吸顶后，继续垂直滚动

---

## 🎨 滚动行为详解

### 阶段 1: 初始状态 (offsetY = 0)
```
视口顶部
│
├─ Section 0 (高度 200pt)
│  └─ 顶部内容完全可见
│
├─ Section 1 Header (高度 44pt)
│  └─ Segment 位于 Section 0 下方
│
├─ Section 1 Content
│  └─ Page 内容开始显示
│
视口底部
```

### 阶段 2: 开始滚动 (0 < offsetY < 200)
```
视口顶部
│
├─ Section 0 (部分可见)
│  └─ 顶部内容正在向上滚出
│
├─ Section 1 Header
│  └─ Segment 跟随向上移动
│
├─ Section 1 Content
│  └─ 更多 Page 内容进入视口
│
视口底部
```

### 阶段 3: Segment 到达顶部 (offsetY ≥ 200)
```
视口顶部
│
├─ Section 1 Header ⭐ 吸附在此！
│  └─ Segment 停止移动
│
├─ Section 1 Content
│  └─ Page 内容继续滚动
│  └─ (Section 0 已完全在屏幕外)
│
视口底部
```

---

## 🔧 代码实现

### 完整的 Layout 配置

```swift
private func createLayout() -> UICollectionViewLayout {
    UICollectionViewCompositionalLayout { sectionIndex, _ in
        switch sectionIndex {
        case 0:
            // Section 0: 顶部共享内容
            return self.createStaticHeaderSection()
        case 1:
            // Section 1: 分页内容 + 吸顶 Segment
            return self.createPagingSection()
        default:
            return nil
        }
    }
}

private func createStaticHeaderSection() -> NSCollectionLayoutSection {
    let item = NSCollectionLayoutItem(
        layoutSize: .init(widthDimension: .fractionalWidth(1.0), 
                         heightDimension: .absolute(200))
    )
    let group = NSCollectionLayoutGroup.vertical(
        layoutSize: .init(widthDimension: .fractionalWidth(1.0), 
                         heightDimension: .absolute(200)),
        subitems: [item]
    )
    return NSCollectionLayoutSection(group: group)
}

private func createPagingSection() -> NSCollectionLayoutSection {
    // 横向分页的 Page
    let item = NSCollectionLayoutItem(
        layoutSize: .init(widthDimension: .fractionalWidth(1.0), 
                         heightDimension: .fractionalHeight(1.0))
    )
    let group = NSCollectionLayoutGroup.horizontal(
        layoutSize: .init(widthDimension: .fractionalWidth(1.0), 
                         heightDimension: .estimated(600)),
        subitems: [item]
    )
    
    let section = NSCollectionLayoutSection(group: group)
    section.orthogonalScrollingBehavior = .groupPaging
    
    // ⭐ 吸顶的 Segment Header
    let header = NSCollectionLayoutBoundarySupplementaryItem(
        layoutSize: .init(widthDimension: .fractionalWidth(1.0), 
                         heightDimension: .absolute(44)),
        elementKind: UICollectionView.elementKindSectionHeader,
        alignment: .top
    )
    header.pinToVisibleBounds = true  // ⭐ 吸顶
    header.zIndex = 2                 // ⭐ 确保在最上层
    
    section.boundarySupplementaryItems = [header]
    return section
}
```

---

## 📊 数据结构

```swift
private func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
    snapshot.appendSections([0, 1])
    
    // Section 0: 顶部共享内容（1 个 item）
    snapshot.appendItems([-1], toSection: 0)
    
    // Section 1: 三个分页（3 个 item）
    snapshot.appendItems([0, 1, 2], toSection: 1)
    
    dataSource.apply(snapshot, animatingDifferences: false)
}
```

---

## 🎯 关键点

### 1. `pinToVisibleBounds = true`
这是实现吸顶的**核心属性**：
- ✅ Header 会在滚动到屏幕顶部时**停止移动**
- ✅ 只对 `NSCollectionLayoutBoundarySupplementaryItem` 有效
- ✅ 自动处理吸附逻辑，不需要手动计算

### 2. `zIndex = 2`
确保 Segment Header 在其他内容之上：
- Section 0 的内容会滚动到 Segment 下方
- Segment 始终保持可见

### 3. Section 分离
将顶部内容和分页内容分成两个 Section：
- **Section 0**: 普通内容，会滚出屏幕
- **Section 1**: 有吸顶 Header 的分页内容

---

## 🆚 与其他方案对比

### 方案 1: 所有内容在一个 Section（不推荐）
```swift
// ❌ 问题：无法实现"顶部内容滚出后 Segment 才吸顶"
section.boundarySupplementaryItems = [header]
header.pinToVisibleBounds = true  
// Header 会立即吸顶，顶部内容无法占据空间
```

### 方案 2: 使用 UIScrollView + 手动管理（复杂）
```swift
// ❌ 需要手动计算滚动位置
// ❌ 需要手动调整 Segment 的 frame
// ❌ 代码复杂，容易出 bug
```

### 方案 3: Compositional Layout 两个 Section（✅ 推荐）
```swift
// ✅ 简单直接
// ✅ 自动处理吸顶逻辑
// ✅ 性能优秀
```

---

## 📱 真实应用示例

这种效果在很多主流 App 中使用：

### 微博详情页
```
[用户头像、昵称、发布时间]  ← Section 0
[转发][评论][点赞]          ← 吸顶 Segment
[评论列表...]              ← Section 1 内容
```

### 小红书详情页
```
[图片轮播、作者信息]        ← Section 0
[笔记][评论]              ← 吸顶 Segment
[评论列表...]              ← Section 1 内容
```

### YouTube 视频详情
```
[视频播放器]               ← Section 0
[简介][评论]              ← 吸顶 Segment
[评论列表...]              ← Section 1 内容
```

---

## 🎨 自定义调整

### 调整顶部内容高度
```swift
layoutSize: .init(widthDimension: .fractionalWidth(1.0), 
                 heightDimension: .absolute(300))  // 改为 300pt
```

### 调整 Segment 高度
```swift
layoutSize: .init(widthDimension: .fractionalWidth(1.0), 
                 heightDimension: .absolute(60))  // 改为 60pt
```

### 调整吸顶位置（加入偏移）
```swift
header.pinToVisibleBounds = true
header.zIndex = 2

// 如果需要偏移（比如导航栏下方）
// 需要通过 contentInset 调整
collectionView.contentInset = UIEdgeInsets(top: 88, left: 0, bottom: 0, right: 0)
```

---

## ✅ 验证效果

运行项目后：

1. **初始状态**：看到顶部内容 + Segment + Page 内容
2. **开始滚动**：三者一起向上移动
3. **继续滚动**：顶部内容逐渐消失
4. **Segment 到顶**：Segment 吸附，不再移动
5. **继续滚动**：只有 Page 内容滚动

这就是你想要的效果！🎉

---

## 📝 总结

通过 Compositional Layout 的 `pinToVisibleBounds` 属性，我们实现了：

- ✅ 顶部内容可以滚出屏幕
- ✅ Segment 滚动到顶部后自动吸附
- ✅ Segment 吸顶后，只有 Page 内容滚动
- ✅ 无需手动计算，系统自动处理
- ✅ 性能优秀，流畅顺滑

这是 iOS 原生的最佳实践方案！🚀
