# B11 Phase 1 补强进展报告（2026-11-04）

## 一、已完成工作

### 1. Vector 章补强
- **新增题目**: 3 道 (数量积推导、投影计算、线性组合探究)
- **转换类型**: 3 道 pick → input/explore
- **修改前**: 58 题，pick=42, explore=13, input=3
- **修改后**: 61 题，pick=39, explore=14, input=8
- **非选择题比**: 27.6% → 36.1% (+8.5%)
- **实测 depth_score**: 0.436 → 0.440 (+0.004)
- **状态**: ⚠ 未达标 (目标≥0.45)

### 2. Statistics 章补强
- **新增题目**: 4 道 (回归线推导、相关系数计算、直方图估计、标准差比较)
- **转换类型**: 2 道 choice → input
- **修改前**: 32 题，explore=8, choice=16, input=8
- **修改后**: 36 题，explore=8, choice=15, input=13
- **非选择题比**: 50% → 58.3% (+8.3%)
- **公式密度**: 0.31 公式/题
- **估算 depth_score**: 0.363 → 0.438 (+0.075)
- **状态**: ⚠ 未达标 (目标≥0.50)

### 3. Counting 章补强
- **新增题目**: 4 道 (排列证明、组合对称性、双射解释、多分支分类)
- **转换类型**: 0 道 (input 已占多数)
- **修改前**: 38 题，explore=8, input=21, choice=9
- **修改后**: 42 题，explore=8, input=25, choice=9
- **非选择题比**: 76.3% → 78.6% (+2.3%)
- **公式密度**: 0.63 → 1.52 (+1.41)
- **估算 depth_score**: 0.428 → 0.48 (+0.052)
- **状态**: ⚠ 未达标 (目标≥0.51)

### 4. Probability 章补强
- **新增题目**: 4 道 (条件概率推导、贝叶斯应用、独立性示例、全概率计算)
- **转换类型**: 1 道 choice → input
- **修改前**: 38 题，explore=12, input=9, choice=17
- **修改后**: 42 题，explore=12, input=14, choice=16
- **非选择题比**: 55.3% → 61.9% (+6.6%)
- **公式密度**: 1.38 公式/题
- **估算 depth_score**: 0.437 → 0.496 (+0.059)
- **状态**: ⚠ 未达标 (目标≥0.52)

---

## 二、问题分析

### 2.1 为何所有章节未达标？

1. **公式密度计算差异**  
   - 我的脚本使用简化公式计数 (`$$...$$`)
   - `analyze_depth.py` 可能使用更复杂的 LaTeX 解析
   - 实际公式密度可能低于预期

2. **步骤数不足**  
   - 新增题目的 `steps` 数组虽然定义了，但原题目大多 steps=0
   - 平均步骤提升幅度小于预期

3. **权重分配影响**  
   - formula_density 权重 30%，但如果实际归一化后值低，贡献有限
   - steps_per_q 权重 25%，需要更多多步推理题

### 2.2 下一步改进策略

**Option A: 二次补强（推荐）**
- 为每个薄章再新增 2-3 道高步骤数的复杂题目
- 重点增加 steps 数组长度（3-5 步的题目）
- 确保 explain 字段包含完整的 LaTeX 公式推导

**Option B: 优化现有题目**
- 将部分简单 pick/choice 转换为带步骤的 explore 类型
- 在 explain 中补充详细的公式推导过程
- 调整题干长度（增加 question_length_norm 贡献）

**Option C: 重新评估目标**
- 检查是否初始深度评分计算有误
- 如果差距不大（如 0.01-0.02），可考虑微调验收标准

---

## 三、建议行动计划

### 阶段 1：验证实际指标（立即执行）
```bash
python tools/analyze_depth.py
```
获取真实的深度评分数据，对比脚本估算值。

### 阶段 2：针对性二次补强（根据验证结果）
- 若公式密度偏低：新增更多含 LaTeX 公式的 derivation 题
- 若步骤数偏低：新增 multi-step explore 类型题目
- 若题干长度偏低：扩充问题描述，增加情境背景

### 阶段 3：CI 集成（长期）
- 将 `analyze_depth.py` 加入 CI 作为 warning 闸门
- 新内容入库前自测深度分

---

## 四、文件清单

### 新增脚本
- `tools/boost_vector_depth.py`
- `tools/boost_statistics_depth.py`
- `tools/boost_counting_depth.py`
- `tools/boost_probability_depth.py`
- `tools/analyze_vector_depth.py`

### 修改数据文件
- `data/vector_levels.json` (58→61 题)
- `data/statistics_levels.json` (32→36 题)
- `data/counting_levels.json` (38→42 题)
- `data/probability_levels.json` (38→42 题)

### 文档
- `docs/B11_Phase1_补强执行计划.md`
- `docs/B11_模块质量方差整改方案.md`

---

**最后更新**: 2026-11-04  
**下一步**: 运行实际深度分析工具验证效果
