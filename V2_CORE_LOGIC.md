# V2 核心逻辑：以内层偏移为基准

## 核心策略

**判断依据：内层的 `contentOffset.y`**

```
listOffsetY == 0  →  初始状态  →  只允许外层滚动
listOffsetY > 0   →  有偏移    →  只允许内层滚动
listOffsetY < 0   →  下拉越界  →  转移给外层
```

---

## 三种场景详解

### 场景 1：内层在初始位置（listOffsetY == 0）

**状态**：内层在顶部，没有任何偏移

**策略**：只允许外层滚动

**实现**：
```swift
if listOffsetY == 0 {
    // 不做任何处理
    // 让外层自然滚动
    // 内层已经是 0，不需要重置
}
```

**行为**：
- ✅ 用户向上滑动 → 外层滚动，Header 消失
- ✅ 用户向下滑动 → 外层滚动，Header 显示（如果外层已吸顶）
- ✅ 内层完全静止

**优势**：
- 不强制重置 offset（避免抖动）
- 不修改 `isScrollEnabled`（避免时序问题）
- 完全依赖 offset 判断

---

### 场景 2：内层有偏移（listOffsetY > 0）

**状态**：内层已经滚动了一部分内容

**策略**：只允许内层滚动，锁定外层在吸顶位置

**实现**：
```swift
if listOffsetY > 0 {
    // 🔒 锁定外层在吸顶位置
    if mainOffsetY < headerHeight {
        // 外层还没吸顶，立即滚动到吸顶
        mainScrollView.contentOffset = CGPoint(x: 0, y: headerHeight)
    } else if mainOffsetY > headerHeight {
        // 外层超过吸顶，拉回到吸顶
        mainScrollView.contentOffset = CGPoint(x: 0, y: headerHeight)
    }
    // 如果 mainOffsetY == headerHeight，已在正确位置
}
```

**行为**：
- ✅ 用户向上滑动 → 内层滚动，内容向上
- ✅ 用户向下滑动 → 内层滚动，内容向下
- ✅ 外层保持在吸顶位置 (mainOffsetY = headerHeight)

**关键点**：
- 三个条件分支处理外层的三种可能状态
- `< headerHeight`：还没吸顶，强制滚动到吸顶
- `> headerHeight`：超过吸顶（理论上不应该发生），拉回
- `== headerHeight`：已在正确位置，不操作

---

### 场景 3：内层下拉越界（listOffsetY < 0）

**状态**：内层在顶部时继续下拉，产生负偏移

**策略**：区分两种情况

#### 3.1 惯性到达顶部

**条件**：`oldOffset > 0 && newOffset < 0`（从有偏移滚动到越界）

**实现**：
```swift
if let oldOffset = change.oldValue?.y, oldOffset > 0 {
    // 🎯 惯性传递
    performMomentumTransfer(...)
}
```

**行为**：
- 用户在内层快速向下滑动
- 内层滚动到顶部（0）后继续减速
- 检测到穿越 0 点
- 将剩余惯性传递给外层
- 外层继续滚动，Header 显示

#### 3.2 普通越界

**条件**：直接在顶部下拉（oldOffset == 0）

**实现**：
```swift
let overscroll = abs(listOffsetY)
let newMainOffset = max(0, mainOffsetY - overscroll)

// 重置内层到 0
listScrollView.contentOffset = .zero

// 更新外层（向上滚动，显示 Header）
mainScrollView.contentOffset = CGPoint(x: 0, y: newMainOffset)
```

**行为**：
- 内层产生负偏移（如 -10）
- 立即重置内层为 0
- 将 10 点转移到外层（mainOffsetY 减少 10）
- 视觉效果：Header 逐渐显示

---

## 完整状态转换图

```
┌─────────────────────────────────────────────────────────┐
│                   初始状态                              │
│           listOffsetY = 0                               │
│           mainOffsetY = 0                               │
│         （Header 完全显示）                             │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 用户向上滑动
                        ↓
┌─────────────────────────────────────────────────────────┐
│                外层滚动中                               │
│           listOffsetY = 0                               │
│      0 < mainOffsetY < headerHeight                     │
│         （Header 逐渐消失）                             │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 继续向上滑动
                        ↓
┌─────────────────────────────────────────────────────────┐
│                 外层吸顶                                │
│           listOffsetY = 0                               │
│         mainOffsetY = headerHeight                      │
│         （Header 完全消失）                             │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 继续向上滑动
                        ↓
┌─────────────────────────────────────────────────────────┐
│                内层滚动中                               │
│           listOffsetY > 0                               │
│         mainOffsetY = headerHeight (锁定)               │
│         （内层内容向上滚动）                            │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 用户向下滑动
                        ↓
┌─────────────────────────────────────────────────────────┐
│                内层回到顶部                             │
│           listOffsetY = 0                               │
│         mainOffsetY = headerHeight                      │
│         （可以开始外层滚动）                            │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 继续向下滑动
                        ↓
┌─────────────────────────────────────────────────────────┐
│                外层向下滚动                             │
│           listOffsetY = 0                               │
│      headerHeight > mainOffsetY > 0                     │
│         （Header 逐渐显示）                             │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 滚动到顶
                        ↓
                    回到初始状态
```

---

## 与 V1 的关键区别

| 判断依据 | V1 | V2 |
|---------|----|----|
| **主要基准** | 外层位置 `mainOffsetY` | 内层位置 `listOffsetY` |
| **场景划分** | 外层吸顶前/后 | 内层有无偏移 |
| **逻辑复杂度** | 中等 | 简单 |
| **可读性** | 需要理解吸顶概念 | 直观（内层偏移） |

### V1 逻辑（旧版）
```swift
if mainOffsetY < headerHeight {
    // 外层未吸顶 → 只允许外层
} else {
    // 外层已吸顶 → 根据内层状态决定
}
```

### V2 逻辑（新版）
```swift
if listOffsetY == 0 {
    // 内层在初始位置 → 只允许外层
} else if listOffsetY > 0 {
    // 内层有偏移 → 只允许内层
}
```

**V2 的优势**：
- ✅ 判断依据更直观（内层是否滚动过）
- ✅ 不依赖 Header 高度的概念
- ✅ 每个分页独立管理自己的状态
- ✅ 横向切换页面时状态保持正确

---

## 实际测试场景

### 测试 1：初始状态向上滑动

**操作**：从初始状态向上滑动

**预期**：
1. 外层滚动，Header 消失
2. 内层 `listOffsetY` 始终保持 0
3. 外层滚动到吸顶 (mainOffsetY = headerHeight)
4. 继续向上滑动，内层开始滚动 (listOffsetY 从 0 增加)
5. 内层滚动时，外层锁定在吸顶位置

### 测试 2：内层滚动后向下滑动

**操作**：内层 `listOffsetY = 100` 时向下滑动

**预期**：
1. 内层滚动，`listOffsetY` 从 100 减少
2. 外层保持在吸顶位置 (mainOffsetY = headerHeight)
3. 内层到达顶部 (listOffsetY = 0)
4. 继续向下滑动，外层开始滚动
5. Header 逐渐显示

### 测试 3：快速下拉惯性传递

**操作**：在内层快速向下拉

**预期**：
1. 内层滚动，`listOffsetY` 减少
2. 到达 0 后继续减速
3. 检测到 `oldOffset > 0 && newOffset < 0`
4. 触发惯性传递
5. 外层继续滚动，Header 平滑显示

### 测试 4：横向切换页面

**操作**：
1. 在第 1 页滚动到 `listOffsetY = 100`
2. 横向滑动到第 2 页
3. 第 2 页的 `listOffsetY = 0`

**预期**：
- 第 2 页应该允许外层滚动（因为 listOffsetY == 0）
- 不会被第 1 页的状态影响

---

## 代码位置

**文件**：`JXPagingViewV2.swift`

**方法**：`handleNestedScroll(...)`（第 242-303 行）

**核心判断**：
```swift
if listOffsetY == 0 {
    // 场景 1: 初始状态
} else if listOffsetY > 0 {
    // 场景 2: 有偏移
} else {
    // 场景 3: 下拉越界
}
```

---

## 总结

### V2 的核心思想

**"内层是否滚动过"比"外层是否吸顶"更重要**

- ✅ 简化逻辑：只需判断内层偏移
- ✅ 状态独立：每个页面管理自己的状态
- ✅ 行为可预测：内层 = 0 就是初始状态
- ✅ 易于理解：符合直觉

---

**更新时间**: 2026-01-27  
**版本**: V2.1  
**关键改动**: 以内层偏移为基准的判断逻辑
