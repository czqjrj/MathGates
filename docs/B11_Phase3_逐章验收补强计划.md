# B11 Phase 3 · 逐章验收补强计划

## 一、验收标准（统一）

每个章节需要达到以下标准才算"通过验收"：
- ✅ depth_score ≥ **0.45**
- ✅ interaction_quality ≥ **0.20**（至少有一定比例的 explore）
- ✅ method_coverage ≥ **0.60**（覆盖主要解题方法）
- ✅ 无纯填空题（input），或 input 占比 ≤ 30%
- ✅ 至少有 2 道高交互 explore 题（带多个滑块 + 实时反馈）

---

## 二、章节优先级排序（按深度分从低到高）

### 🔴 P0：严重不达标 (< 0.40) - 需重点补强
| 章节 | 当前分 | 缺口 | 预计需新增 explore 数 | 优先级 |
|------|-------:|-----:|---------------------:|-------:|
| **thinking** | 0.400 | **-0.05** | 3-4 道 | ⭐⭐⭐⭐⭐ |
| **conic** | 0.426 | -0.024 | 2-3 道 | ⭐⭐⭐⭐ |
| **inequalities** | 0.410 | -0.04 | 2-3 道 | ⭐⭐⭐⭐ |

### 🟡 P1：接近达标 (0.40-0.45) - 少量补强
| 章节 | 当前分 | 缺口 | 预计需新增 explore 数 | 优先级 |
|------|-------:|-----:|---------------------:|-------:|
| **sequences** | ~0.423 | -0.027 | 1-2 道 | ⭐⭐⭐ |
| **recurrence** | ~0.425 | -0.025 | 1-2 道 | ⭐⭐⭐ |
| **corr_data** | 0.425 | -0.025 | 1-2 道 | ⭐⭐⭐ |
| **derivative** | 0.430 | -0.02 | 1 道 | ⭐⭐ |
| **function_lab** | 0.431 | -0.019 | 1 道 | ⭐⭐ |
| **functions** | 0.434 | -0.016 | 1 道 | ⭐⭐ |
| **random_var** | 0.435 | -0.015 | 1 道 | ⭐⭐ |
| **set_logic** | 0.441 | -0.009 | 1 道 | ⭐ |
| **vectors** | 0.443 | -0.007 | 1 道 | ⭐ |
| **complex** | 0.444 | -0.006 | 1 道 | ⭐ |

### 🟢 P2：已达标 (≥0.45) - 无需行动
trig, parabola, conics, ellipse, space, hyperbola, circle, line, solid_basic, counting, statistics, probability, vector

---

## 三、逐章补强执行顺序（从高一到高三）

### Day 1：集合逻辑与函数基础

#### 1️⃣ set_logic（第 1 章，当前 0.441 → 目标 0.45+）
**现状**: 只有 1 道 explore，interaction_quality=0.167
**补强方案**: 
- [ ] Set_Venn_Diagram_Interactive: 拖动区域观察韦恩图运算
- [ ] expected_depth: +0.01 → 0.452

#### 2️⃣ functions（第 2 章，当前 0.434 → 目标 0.45+）
**现状**: function_lab=0.431 也接近，两者可协同
**补强方案**:
- [ ] Func_Transform_Sliders: 拖动平移/伸缩参数观察图像变化
- [ ] Func_Composition_Path: 逐步构造复合函数的探索实验
- [ ] expected_depth: +0.02 → 0.454

#### 3️⃣ function_lab（第 3 章，当前 0.431 → 目标 0.45+）
**补强方案**:
- [ ] Func_Even_Odd_Symmetry: 拖动点验证奇偶对称性
- [ ] expected_depth: +0.02 → 0.451

---

### Day 2：数列与不等式核心

#### 4️⃣ sequences（数列，当前~0.423 → 目标 0.45+）
**补强方案**:
- [ ] Seq_Arithmetic_Graph: 等差数列通项公式的可视化对比
- [ ] Seq_Geometric_Puzzle: 等比数列增长率实验（多滑块控制 q）
- [ ] expected_depth: +0.03 → 0.453

#### 5️⃣ recurrence（递推数列，当前~0.425 → 目标 0.45+）
**补强方案**:
- [ ] Recur_Fixed_Point_Exploration: 迭代收敛到不动点的动画演示
- [ ] expected_depth: +0.02 → 0.445（可能还需微调）

#### 6️⃣ inequalities（不等式，当前 0.410 → 目标 0.45+）
**补强方案**:
- [ ] Ineq_AMGM_Rectangle: AM-GM 不等式的矩形面积几何证明
- [ ] Ineq_Cauchy_Vector_Animation: 柯西不等式的向量形式互动
- [ ] expected_depth: +0.04 → 0.450

---

### Day 3：导数与应用

#### 7️⃣ derivative（导数，当前 0.430 → 目标 0.45+）
**补强方案**:
- [ ] Deriv_Tangent_Motion: 拖动切点观察切线斜率变化
- [ ] Deriv_Monotonicity_Color: 用颜色区分递增/递减区间
- [ ] expected_depth: +0.02 → 0.450

---

### Day 4：统计与概率应用

#### 8️⃣ corr_data（相关数据，当前 0.425 → 目标 0.45+）
**补强方案**:
- [ ] Corr_Scatter_Drag_Points: 拖动散点观察 r 值变化
- [ ] Reg_Line_Fit_Comparison: 拟合直线与实际数据的残差分析
- [ ] expected_depth: +0.03 → 0.455

#### 9️⃣ random_var（随机变量，当前 0.435 → 目标 0.45+）
**补强方案**:
- [ ] RV_Distribution_Shift: 拖动参数改变分布形态
- [ ] expected_depth: +0.02 → 0.455

---

### Day 5：三角函数与解析几何

#### 🔟 thinking（数学思想综合，当前 0.400 → **最高优先级**）
**注意**: thinking 跨章节综合，独立处理
**补强方案**:
- [ ] Think_Analogy_Number_Sequence: 类比推理·数列对照实验
- [ ] Think_Contradiction_Visual: 反证法可视化演示
- [ ] Think_NumberShape_Coordinate: 数形结合·方程根的个数探究
- [ ] expected_depth: +0.05 → 0.450

#### ⑪ conic（圆锥曲线，当前 0.426 → 目标 0.45+）
**补强方案**:
- [ ] Conic_Ellipse_Eccentricity: 椭圆离心率影响探索
- [ ] Conic_Parabola_Focus_Property: 抛物线光学性质互动
- [ ] expected_depth: +0.03 → 0.456

---

## 四、执行检查清单

每次完成一个章节后，运行以下验收流程：

```bash
# 1. 运行深度分析
python tools/analyze_depth_v3.py

# 2. 检查该章节是否达标
grep "chapter_name" output

# 3. 确认 interact_quality ≥ 0.20
# 4. 确认没有新增纯填空题（input）
# 5. 更新本文档的完成标记
```

---

## 五、完成进度追踪表

| 序号 | 章节 | 当前分 | 目标分 | 状态 | 完成日期 | 执行人 |
|-----:|------|-------:|-------:|------|---------:|--------|
| 1 | set_logic | 0.441 | 0.45 | 🟡 进行中 | - | - |
| 2 | functions | 0.434 | 0.45 | ⚪ 待开始 | - | - |
| 3 | function_lab | 0.431 | 0.45 | ⚪ 待开始 | - | - |
| 4 | sequences | 0.423 | 0.45 | ⚪ 待开始 | - | - |
| 5 | recurrence | 0.425 | 0.45 | ⚪ 待开始 | - | - |
| 6 | inequalities | 0.410 | 0.45 | ⚪ 待开始 | - | - |
| 7 | derivative | 0.430 | 0.45 | ⚪ 待开始 | - | - |
| 8 | corr_data | 0.425 | 0.45 | ⚪ 待开始 | - | - |
| 9 | random_var | 0.435 | 0.45 | ⚪ 待开始 | - | - |
| 10 | **thinking** | **0.400** | **0.45** | 🔴 **优先** | - | - |
| 11 | conic | 0.426 | 0.45 | ⚪ 待开始 | - | - |

**最终目标**: 所有章节 depth_score ≥ 0.45，平均深度 ≥ 0.50，标准差 ≤ 0.05

---

**最后更新**: 2026-11-04  
**下一站**: set_logic（第 1 章）→ 立即开始补强
