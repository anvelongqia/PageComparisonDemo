# V2 官方逻辑实现文档

## 概述

V2 版本现在采用 **JXPagingView 官方的控制逻辑**，核心思想是：

**双向同步控制 contentOffset，确保在任何时刻内外层都处于正确的状态。**

---

## 核心逻辑（参考官方实现）

### 关键常量

```swift
let maxMainOffsetY = headerHeight  // 外层最大偏移（吸顶位置）
let minListOffsetY: CGFloat = 0    // 内层最小偏移（顶部）
```

---

## 三个控制阶段

### 阶段 1：处理内层滚动

```swift
if mainOffsetY < maxMainOffsetY {
    // 外层还没到吸顶位置，强制内层保持在顶部
    if listOffsetY != minListOffsetY {
        listScrollView.contentOffset = CGPoint(x: 0, y: minListOffsetY)
    }
} else {
    // 外层已吸顶，固定外层位置
    if mainOffsetY != maxMainOffsetY {
        mainScrollView.contentOffset = CGPoint(x: 0, y: maxMainOffsetY)
    }
}
```

**逻辑**：
- `mainOffsetY < maxMainOffsetY`（外层未吸顶）→ 强制内层为 0
- `mainOffsetY >= maxMainOffsetY`（外层已吸顶）→ 固定外层在吸顶位置

---

### 阶段 2：处理外层滚动

```swift
if listOffsetY > minListOffsetY {
    // 内层有偏移，固定外层在吸顶位置
    if mainOffsetY != maxMainOffsetY {
        mainScrollView.contentOffset = CGPoint(x: 0, y: maxMainOffsetY)
    }
}

// 外层已显示 header 时，重置内层
if mainOffsetY < maxMainOffsetY {
    if listOffsetY != minListOffsetY {
        listScrollView.contentOffset = CGPoint(x: 0, y: minListOffsetY)
    }
}
```

**逻辑**：
- `listOffsetY > 0` → 固定外层在吸顶位置
- `mainOffsetY < maxMainOffsetY` → 重置内层为 0

---

### 阶段 3：修复边界情况

```swift
// 当外层滚动超过吸顶位置，且内层在顶部时，修复外层位置
if mainOffsetY > maxMainOffsetY && listOffsetY == minListOffsetY {
    mainScrollView.contentOffset = CGPoint(x: 0, y: maxMainOffsetY)
}
```

**逻辑**：
- 防止外层滚动超过吸顶位置
- 这种情况理论上不应该发生，但作为保护性代码

---

## 工作原理图解

```
┌─────────────────────────────────────────────────┐
│  初始状态                                       │
│  mainOffsetY = 0                                │
│  listOffsetY = 0                                │
│  (Header 完全显示)                              │
└─────────────────────────────────────────────────┘
              │
              │ 用户向上滑动
              ↓
┌─────────────────────────────────────────────────┐
│  外层滚动中                                     │
│  0 < mainOffsetY < headerHeight                 │
│  listOffsetY = 0 (强制锁定)                     │
│  (Header 逐渐消失)                              │
└─────────────────────────────────────────────────┘
              │
              │ 阶段 1 控制
              │ if mainOffsetY < maxMainOffsetY:
              │     listOffsetY = 0
              ↓
┌─────────────────────────────────────────────────┐
│  外层吸顶                                       │
│  mainOffsetY = headerHeight (锁定)              │
│  listOffsetY = 0                                │
│  (Header 完全消失，Segment 吸顶)                │
└─────────────────────────────────────────────────┘
              │
              │ 继续向上滑动
              ↓
┌─────────────────────────────────────────────────┐
│  内层滚动中                                     │
│  mainOffsetY = headerHeight (强制锁定)          │
│  listOffsetY > 0                                │
│  (内层内容向上滚动)                             │
└─────────────────────────────────────────────────┘
              │
              │ 阶段 2 控制
              │ if listOffsetY > 0:
              │     mainOffsetY = maxMainOffsetY
              │
              │ 用户向下滑动
              ↓
┌─────────────────────────────────────────────────┐
│  内层回到顶部                                   │
│  mainOffsetY = headerHeight                     │
│  listOffsetY = 0                                │
└─────────────────────────────────────────────────┘
              │
              │ 继续向下滑动
              ↓
┌─────────────────────────────────────────────────┐
│  外层向下滚动                                   │
│  mainOffsetY 从 headerHeight 减小               │
│  listOffsetY = 0 (强制锁定)                     │
│  (Header 逐渐显示)                              │
└─────────────────────────────────────────────────┘
              │
              │ 回到初始状态
              ↓
```

---

## 与官方 JXPagingView 的对应关系

### 官方方法 → V2 实现

| 官方方法 | 功能 | V2 对应 |
|---------|------|---------|
| `preferredProcessListViewDidScroll` | 处理内层滚动 | 阶段 1 |
| `preferredProcessMainTableViewDidScroll` | 处理外层滚动 | 阶段 2 + 3 |
| `setListScrollViewToMinContentOffsetY` | 重置内层 | `listOffsetY = 0` |
| `setMainTableViewToMaxContentOffsetY` | 固定外层 | `mainOffsetY = headerHeight` |

---

## 关键特点

### 1. 双向控制

**不只是单向锁定，而是双向同步：**

```swift
// ✅ 内层滚动时 → 固定外层
if listOffsetY > 0 {
    mainOffsetY = headerHeight
}

// ✅ 外层滚动时 → 重置内层
if mainOffsetY < headerHeight {
    listOffsetY = 0
}
```

### 2. 条件判断避免循环

**每次修改前都检查是否需要：**

```swift
if listOffsetY != minListOffsetY {
    listScrollView.contentOffset = ...  // ✅ 只在不同时修改
}
```

### 3. 简洁的边界保护

```swift
// 防止外层超过吸顶位置
if mainOffsetY > maxMainOffsetY && listOffsetY == minListOffsetY {
    mainOffsetY = maxMainOffsetY
}
```

---

## 测试场景

### 测试 1：初始状态向上滑动

**操作**：从初始状态向上滑动

**内部流程**：
1. 用户滑动 → `mainOffsetY` 增加
2. 触发 KVO → 检查 `mainOffsetY < headerHeight`
3. 强制 `listOffsetY = 0`
4. 外层继续滚动到吸顶
5. 达到吸顶 → `mainOffsetY = headerHeight`
6. 继续滑动 → 内层开始滚动
7. 触发 KVO → 检查 `listOffsetY > 0`
8. 固定 `mainOffsetY = headerHeight`

**预期结果**：
- ✅ 外层先滚动（Header 消失）
- ✅ 吸顶后内层开始滚动
- ✅ 内层滚动时外层保持固定

### 测试 2：内层有偏移时向下滑动

**操作**：内层 `listOffsetY = 100` 时向下滑动

**内部流程**：
1. 用户向下滑动 → `listOffsetY` 减少
2. 触发 KVO → 检查 `listOffsetY > 0`
3. 固定 `mainOffsetY = headerHeight`
4. 内层继续滚动到 0
5. `listOffsetY = 0` → 条件不满足
6. 继续滑动 → 外层开始滚动
7. 触发 KVO → 检查 `mainOffsetY < headerHeight`
8. 强制 `listOffsetY = 0`

**预期结果**：
- ✅ 内层先滚动到顶
- ✅ 然后外层接管（Header 显示）
- ✅ 外层滚动时内层保持在 0

### 测试 3：横向切换页面

**操作**：
1. 第 1 页滚动到 `listOffsetY = 100`
2. 横向切换到第 2 页
3. 第 2 页 `listOffsetY = 0`
4. 在第 2 页向上滑动

**内部流程**：
1. 切换到第 2 页 → 当前 list 改变
2. KVO 监听的是第 2 页的 scrollView
3. 第 2 页的 `listOffsetY = 0`
4. 向上滑动 → 检查 `mainOffsetY`
5. 如果外层已吸顶 → 外层保持，内层开始滚动
6. 如果外层未吸顶 → 外层滚动，内层保持 0

**预期结果**：
- ✅ 每个页面状态独立
- ✅ 不受其他页面影响

---

## 代码位置

**文件**：`JXPagingViewV2.swift`

**方法**：`handleNestedScroll(...)`（第 242-299 行）

**核心逻辑**：
```swift
// 阶段 1: 处理内层滚动
if mainOffsetY < maxMainOffsetY {
    listOffsetY = 0
} else {
    mainOffsetY = maxMainOffsetY
}

// 阶段 2: 处理外层滚动
if listOffsetY > 0 {
    mainOffsetY = maxMainOffsetY
}
if mainOffsetY < maxMainOffsetY {
    listOffsetY = 0
}

// 阶段 3: 边界保护
if mainOffsetY > maxMainOffsetY && listOffsetY == 0 {
    mainOffsetY = maxMainOffsetY
}
```

---

## 优势总结

### vs V1

| 特性 | V1 | V2 (官方逻辑) |
|------|----|----|
| **判断依据** | 复杂条件分支 | 简单的大小比较 |
| **控制方式** | 单向锁定 | 双向同步 |
| **可靠性** | 边界情况较多 | 官方验证 |
| **可维护性** | 中等 | 高 |

### 核心优势

1. ✅ **经过验证**：官方库使用相同逻辑
2. ✅ **逻辑清晰**：三个阶段，职责明确
3. ✅ **双向控制**：内外层互相约束
4. ✅ **边界保护**：防止异常状态

---

## 注意事项

### 1. 性能优化

当前实现中，重置内层时只处理当前列表，不遍历所有列表：

```swift
// ✅ 只处理当前显示的列表
if listOffsetY != minListOffsetY {
    listScrollView.contentOffset = ...
}

// ❌ 不这样做（官方会遍历，但我们的架构不需要）
for list in allLists {
    list.contentOffset = ...
}
```

### 2. KVO 回调频率

每次滚动都会触发 KVO，代码会执行多次。通过条件判断避免无效操作：

```swift
if mainOffsetY != maxMainOffsetY {  // ✅ 只在需要时修改
    mainScrollView.contentOffset = ...
}
```

---

**更新时间**: 2026-01-27  
**版本**: V2.2  
**参考**: JXPagingView 官方实现  
**关键文件**: `JXPagingViewV2.swift` (第 242-299 行)
