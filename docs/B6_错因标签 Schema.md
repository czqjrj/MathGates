# B6 · 错因标签 Schema（v1.0）

## 一、设计理念

错因标签用于**错题本聚合分析**与**个性化复习推荐**，必须满足：

1. **互斥性**：每道题只能有一个主要错因（避免多重标签导致统计失真）
2. **可判定性**：错因必须是机器可判定或人工可快速选择的明确类别
3. **教育有效性**：每个错因对应具体的 remediation 策略（补救措施）
4. **扩展性**：预留 ext 字段支持自定义错因，但主标签必须来自白名单

---

## 二、错因标签白名单

### 核心错因（7 类，引擎消费）

| 标签 ID | 中文名 | 英文名 | 适用题型 | 判定条件 | Remediation 策略 |
|--------|--------|--------|----------|----------|------------------|
| `concept` | 概念混淆 | concept_confusion | 选择/填空 | 题干考察定义/性质，错项为范畴错误 | 返回知识点讲解 + 定义辨析题 |
| `calc` | 计算失误 | calculation_error | 填空/解答 | 思路正确但数值/符号错误 | 重练基础计算题 + 步骤检查清单 |
| `formula` | 公式遗忘 | formula_forget | 选择/填空 | 需要特定公式但答错 | 公式卡片记忆 + 公式推导题 |
| `read` | 审题疏忽 | misreading | 所有 | 漏读条件/看错数字/理解反义 | 圈画关键词训练 + 变式题 |
| `method` | 方法不当 | method_misfit | 解答 | 选错解题路径（如该分类讨论却直接求解） | 方法选择树 + 典型例题对比 |
| `logic` | 逻辑漏洞 | logical_gap | 证明/解答 | 推理跳跃/循环论证/忽略边界 | 逻辑链重构练习 + 反例构造 |
| `time` | 时间不足 | time_pressure | 所有（仅限模拟考场景） | 会做但未完成 | 限时训练 + 优先级策略 |

### 扩展错因（可选，暂不引擎消费）

| 标签 ID | 中文名 | 说明 |
|--------|--------|------|
| `guess` | 蒙对后暴露 | 之前蒙对，复习时发现不会 |
| `careless` | 粗心（未细分） | 无法归入上述 7 类的其他失误 |
| `ext:<自定义>` | 用户自定义 | 格式：`ext:` + 任意字符串（限 10 字内） |

---

## 三、数据 Schema

### 3.1 错题记录扩展字段

在 `SrsStore.new_plan()` 和 `wrong_log` 记录中增加 `err_reason` 字段：

```gdscript
# SrsRules.gd: new_plan() 返回结构扩展
{
    "level_id": String,      # 关卡 ID
    "qi": int,               # 题目下标
    "name": String,          # 题干摘要
    "module": String,        # 领域 ID（如"vector"）
    
    # --- SRS 排程字段 ---
    "step": int,             # Leitner 阶梯 (0-4)
    "ok_streak": int,        # 连续答对次数
    "interval_days": int,    # 当前间隔天数
    "due_day": int,          # 到期日序号
    "last_wrong_day": int,   # 上次答错日序号
    "first_wrong_at": int,   # 首次错题时间戳
    "last_review_at": int,   # 末次复习时间戳
    "wrong_count": int,      # 累计错次
    
    # --- B6 新增：错因标签 ---
    "err_reason": String,    # 错因 ID，必选来自 ERR_REASON_WHITELIST
                             # 空串 "" = 尚未标注（待用户标记或自动推断）
}
```

### 3.2 错题聚合查询 Schema

按错因聚合的错题列表返回结构：

```gdscript
{
    "by_reason": {
        "concept": [
            {"level_id": "vec_1_1", "qi": 2, "name": "...", "wrong_count": 3},
            ...
        ],
        "calc": [...],
        ...
    },
    "summary": {
        "total_wrong": int,
        "by_reason_counts": {"concept": 5, "calc": 8, ...},
        "top_reason": String,  # 占比最高的错因
        "remediation_hint": String  # 针对 top_reason 的 remediation 建议
    }
}
```

---

## 四、错因判定策略

### 4.1 自动推断规则（优先级从高到低）

| 触发条件 | 推断错因 | 置信度 |
|----------|----------|--------|
| `opts` 非空且错项为范畴错误（如问集合答数） | `concept` | 高 |
| 正确答案为纯数值，错答案数值接近（±10%） | `calc` | 中 |
| 正确答案含公式，错答案为文字描述或无关公式 | `formula` | 中 |
| 题干含否定词（不/非/除），错答案正好相反 | `read` | 高 |
| 多步推导题中途出错（steps > 2 且 explain 指向前几步） | `method` | 中 |
| 证明题缺关键步骤（explain 提到"需补充 XXX 定理"） | `logic` | 低 |
| 时间戳间隔 < 5 秒即答错 | `time` | 低（仅模拟考场景启用） |

### 4.2 人工标注入口

- **错题笔记详情页**：底部按钮「标注错因」→ 弹出 7 选项单选 → 保存
- **批量操作**：长按多选错题 → 「批量标注错因」→ 统一设置
- **智能推荐**：根据自动推断结果预填，用户可修改

---

## 五、校验器设计

### 5.1 实时校验（答题时）

当用户提交错题标记时：

```gdscript
func validate_err_reason(reason: String) -> bool:
    return ERR_REASON_WHITELIST.has(reason) or reason.begins_with("ext:")
```

### 5.2 批量扫描（CI 闸门）

`tools/check_err_reason.gd`：
- 扫描 `data/*_levels.json` 中的 hint/explain 字段
- 检测是否存在**暗示错因但未标记**的题目（可作为质检指标）
- 报告「可推断错因的题目占比」（目标 ≥ 60%）

---

## 六、错题本聚合 UI

### 6.1 错因分布饼图

- 7 个错因按数量占比显示扇形
- 点击扇形筛选出对应错因的错题列表
- 顶部显示「最薄弱错因：XXX（共 Y 道）」

### 6.2 针对性复习包

根据错因自动生成复习计划：

```gdscript
func build_remediation_package(top_reason: String) -> Array[Dictionary]:
    match top_reason:
        "concept": 
            return _fetch_related_concept_drills()
        "calc":
            return _fetch_calc_exercises()
        "formula":
            return _fetch_formula_cards()
        ...
```

---

## 七、验收标准

### 功能验收

- ✅ 错题记录支持 `err_reason` 字段（空串/白名单值/`ext:*`）
- ✅ UI 提供错因标注入口（单题 + 批量）
- ✅ 错题本可按错因筛选 + 饼图展示
- ✅ 自动推断规则覆盖≥5 种错因（概念/计算/公式/审题/方法）

### 质量验收

- ✅ `check_err_reason.gd` 扫描无非法值（白名单外且不匹配 `ext:` 前缀）
- ✅ 错因分布看板更新准确（增量+全量两种模式）
- ✅ 反向验证：临时写入非法错因 → 报错 → 恢复后复绿

### 教育有效性验收

- ✅ 每个错因对应至少 3 道 remediation 练习题
- ✅ 针对 top 错因的复习包准确率 ≥ 80%（人工抽检）

---

## 八、实施路线图

### Phase 1：Schema 落地（1-2 天）

- [x] 定义 ERR_REASON_WHITELIST 常量
- [ ] 扩展 SrsRules.new_plan() 和 advance() 的 err_reason 字段
- [ ] UserStore.wrong_log 迁移逻辑增加 err_reason 兼容
- [ ] 新增 check_err_reason.gd 校验器

### Phase 2：UI 整合（2-3 天）

- [ ] 错题笔记详情页添加「标注错因」按钮
- [ ] 错因选择弹窗（7 选项 + 自定义输入）
- [ ] 错题本首页错因分布饼图
- [ ] 批量标注功能

### Phase 3：自动推断（3-5 天）

- [ ] 实现 7 类错因的自动推断规则
- [ ] 答题结束时自动提示「这道题的错因是？」
- [ ] 错题回顾时显示推断结果并允许修改

### Phase 4：个性化复习（5-7 天）

- [ ] 每种错因关联 remediation 题库
- [ ] 根据 top 错因生成专属复习包
- [ ] 复盘报告增加错因趋势图

---

**文档版本**: v1.0  
**最后更新**: 2026-11-03  
**责任人**: B6 整改小组（AI 自动生成 + 产品终审）
