# JXPagingView V2 版本设计文档

## 概述

**V2 版本**采用全新的滚动控制策略，通过**精确控制内外层 `contentOffset`** 来实现嵌套滚动，而不是依赖手势拦截或启用状态控制。

---

## 核心设计理念

### V1 vs V2 对比

| 方面 | V1 版本 | V2 版本 |
|------|---------|---------|
| **控制方式** | 手势控制 + KVO 回调 | 纯 contentOffset 控制 |
| **策略** | `canScroll` + 强制重置 | 双向 offset 同步 |
| **复杂度** | 中等（手势协调） | 低（纯数学计算） |
| **可靠性** | 依赖时序 | 不依赖时序 |

---

## 核心算法

### 场景 1：外层未吸顶（mainOffsetY < headerHeight）

**策略**：锁定内层在顶部，所有滚动由外层处理

```swift
if mainOffsetY < headerHeight {
    // 🎯 锁定内层
    if listOffsetY != 0 {
        listScrollView.contentOffset = .zero
    }
    return
}
```

**原理**：
- 用户滚动时，外层自然响应
- 如果内层尝试滚动（offset 变化），立即重置为 0
- 结果：只有外层在动

---

### 场景 2：外层已吸顶 + 内层有内容（listOffsetY > 0）

**策略**：保持外层在吸顶位置，允许内层滚动

```swift
if listOffsetY > 0 {
    // 🎯 锁定外层在吸顶位置
    if mainOffsetY != headerHeight {
        mainScrollView.contentOffset = CGPoint(x: 0, y: headerHeight)
    }
    return
}
```

**原理**：
- 内层正常滚动（系统原生行为）
- 如果外层尝试离开吸顶位置，立即拉回
- 结果：只有内层在动

---

### 场景 3：内层到顶后惯性传递

**策略**：计算剩余惯性，传递给外层

```swift
if let oldOffset = change.oldValue?.y, oldOffset > 0 && listOffsetY <= 0 {
    let velocity = listScrollView.panGestureRecognizer.velocity(in: listScrollView).y
    
    if abs(velocity) > 100 {
        // 计算减速距离
        let deceleration: CGFloat = 2500.0
        let distance = (velocity * velocity) / (2.0 * deceleration)
        let targetY = max(0, mainOffsetY - distance)
        
        // 停止内层
        listScrollView.setContentOffset(.zero, animated: false)
        
        // 外层继续滚动
        mainScrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: true)
    }
}
```

**原理**：
- 检测内层从 `> 0` 到 `<= 0` 的瞬间
- 读取当前手势速度
- 使用物理公式计算剩余距离
- 外层接管并继续滚动

---

### 场景 4：内层下拉越界

**策略**：将越界量实时转移给外层

```swift
if listOffsetY < 0 {
    let overscroll = abs(listOffsetY)
    let newMainOffset = max(0, mainOffsetY - overscroll)
    
    // 重置内层
    listScrollView.contentOffset = .zero
    
    // 更新外层
    if mainOffsetY != newMainOffset {
        mainScrollView.contentOffset = CGPoint(x: 0, y: newMainOffset)
    }
}
```

**原理**：
- 内层下拉产生负偏移（橡皮筋效果）
- 立即重置内层为 0
- 将越界量同步到外层（向上滚动）

---

## 优势分析

### 1. 不依赖时序
- V1 问题：`isScrollEnabled` 在 KVO 回调中设置，时机太晚
- V2 解决：每次 KVO 回调都重新计算并同步，不依赖顺序

### 2. 逻辑简洁
- V1 问题：需要维护 `canScroll`、`isScrollEnabled` 等多个状态
- V2 解决：只需要判断 offset 值，纯数学运算

### 3. 无手势冲突
- V1 问题：需要协调 `gestureRecognizerShouldBegin` 等手势方法
- V2 解决：完全不涉及手势层面，让系统处理手势

### 4. 可预测性强
- V1 问题：手势协调有时会出现边界情况
- V2 解决：每种场景都有明确的 offset 计算公式

---

## 关键参数

### 惯性传递参数

```swift
velocity: 速度阈值 = 100 pt/s
deceleration: 减速度 = 2500 pt/s²
```

**调整建议**：
- 增大 `velocity` → 只有快速滑动才传递
- 减小 `deceleration` → 滑动距离更长
- 增大 `deceleration` → 滑动距离更短

---

## 文件结构

### 新增文件

1. **JXPagingViewV2.swift** (350 行)
   - `JXPagingViewV2`: 主视图类
   - `JXMainCollectionView`: 外层 CollectionView
   - `JXPagingCellV2`: Cell
   - `JXHeaderContainerView`: Header 容器
   - `ScrollState`: 滚动状态结构体

2. **JXOrthogonalPagingViewControllerV2.swift** (240 行)
   - `JXOrthogonalPagingViewControllerV2`: 主控制器
   - `GradientHeaderViewV2`: 渐变 Header
   - `ListPageViewControllerV2`: 列表页面

### 修改文件

3. **ComparisonTabBarController.swift**
   - 添加第 6 个 Tab（正交滚动 V2）

---

## 使用方式

### 1. 在 TabBar 中选择第 6 个 Tab

```
Tab 1: Cell-Based
Tab 2: VC-Based
Tab 3: JXPaging
Tab 4: TabBar 用例
Tab 5: 正交滚动 V1 ⬅️ 旧版本
Tab 6: 正交滚动 V2 ⬅️ 新版本（图标：↕️）
```

### 2. 测试场景

#### 场景 A：初始状态下拉
1. 进入 V2 Tab
2. 在内层区域向下拉
3. **预期**：只有外层滚动，Header 消失

#### 场景 B：吸顶后滚动内层
1. 向上滚动直到吸顶
2. 在内层向上滚动
3. **预期**：只有内层滚动，外层保持吸顶

#### 场景 C：内层到顶后惯性
1. 在内层快速向下拉
2. 内层到顶后松手
3. **预期**：外层继续滚动，Header 显示

#### 场景 D：内层下拉越界
1. 外层已吸顶
2. 内层在顶部状态下继续下拉
3. **预期**：越界量实时转移到外层

---

## V1 vs V2 行为对比

| 场景 | V1 行为 | V2 行为 | 改进 |
|------|---------|---------|------|
| **初始下拉内层** | ⚠️ 内外层同时动（轻微） | ✅ 只有外层动 | 完美 |
| **吸顶后滚动** | ✅ 内层优先 | ✅ 内层优先 | 一致 |
| **惯性传递** | ✅ 平滑传递 | ✅ 平滑传递 | 一致 |
| **下拉越界** | ❌ 不支持 | ✅ 实时转移 | 新增 |

---

## 潜在问题与解决

### Q: 在 KVO 回调中修改 offset 会触发新的 KVO 吗？

**A**: 会，但不会造成无限循环，因为：
1. 每次修改都会检查 `if offset != target`
2. 第二次 KVO 时 offset 已经是目标值，不会再修改
3. 最多触发 2 次 KVO

### Q: 频繁修改 offset 会影响性能吗？

**A**: 不会，因为：
1. `contentOffset` 的 setter 非常轻量
2. 只在值不同时才修改（避免无效调用）
3. 现代设备性能足够

### Q: 为什么不用 `setContentOffset(_:animated:)`？

**A**: 
- 重置时使用 `animated: false`，确保立即生效
- 惯性传递时使用 `animated: true`，利用系统原生曲线

---

## 下一步优化方向

### 1. 速度记录优化
当前从 `panGestureRecognizer.velocity` 读取，可以改为持续记录：
```swift
private var lastListVelocity: CGFloat = 0

// 在 KVO 中
let deltaTime = currentTime - lastTimestamp
let instantVelocity = deltaOffset / CGFloat(deltaTime)
if listOffsetY > 0 {
    lastListVelocity = instantVelocity
}
```

### 2. 橡皮筋效果增强
可以添加阻尼系数，让下拉越界更自然：
```swift
let dampingFactor: CGFloat = 0.5
let dampedOverscroll = overscroll * dampingFactor
```

### 3. 吸顶时惯性传递
V1 中有实现，V2 中可以添加：
```swift
// 检测外层刚到达吸顶
if lastMainOffsetY < headerHeight && mainOffsetY >= headerHeight {
    // 获取外层速度并传递给内层
}
```

---

## 总结

### V2 版本的核心思想

**"让系统处理手势，我们只控制结果（contentOffset）"**

- ✅ 不干预手势识别
- ✅ 不修改 `isScrollEnabled`
- ✅ 只在 KVO 回调中同步 offset
- ✅ 简单、可靠、可预测

### 适用场景

V2 版本特别适合：
- 需要完美解决初始状态下拉问题的项目
- 对滚动体验要求极高的应用
- 需要简洁易维护代码的团队

---

**创建时间**: 2026-01-27  
**版本**: V2.0  
**文件**:
- `JXPagingViewV2.swift`
- `JXOrthogonalPagingViewControllerV2.swift`
