# TODO · 唯一待办清单

> **本文件是项目唯一的 TODO**。合并自原先四个文件：`TODO.md`（MicroTeX 公式运行时渲染，已 100% 完成）、
> `TODO-lab.md`（几何章节迁移到 LabStage，已完成）、`TODO-gamify.md`（关卡游戏化 P1/P2/P3，已交付）、
> `TODO-quality.md`（架构收敛 + 题目内容审计，本次新增）。
> **已完成条目与历史验收记录已清除**，需要追溯请看 `git log`（提交信息里带条目编号）。
>
> 本清单每条都带「现状证据 / 做法 / 验收」，**可跨机器续接**。
> 用法：按优先级从上往下做；每完成一项，在提交信息里引用条目编号（如 `fix(A1): 数列关卡迁移到 StageBase`），
> 并把该条打勾、同步更新第 9 节的基线数字。
>
> 已被清除的历史文件内容另有归宿，不受影响：
> - MicroTeX 工具链 / 已知坑（Error 126、`res.bin`、`user://` 中文路径等）→ `docs/环境配置.md`
> - 游戏化设计稿与数据 schema（`boss{}` / `rules{}` / `gate`/`chest`/`event`）→ `docs/关卡游戏化方案.md`
> - 架构与题目审计的原始数据 → 本文件第 9 节

---

## 0. 总览

### 0.1 优先级总览

| 编号 | 标题 | 优先级 | 说明 |
|---|---|---|---|
| **A1** | `SequenceStage` 迁移到 `StageBase` | **P0** | ✅ 已完成（763 → 185 行，双轨消除） |
| **B1** | 题型单一：把 `interact/gate` 与填空题用起来 | **P0** | 🟡 填空题已落地 + 题型看板；26/26 章已扫描改写（非四选一 19.2%，目标 ≥30%；纯数值转换已到上限，余下需内容重设计） |
| **B3** | 「探究→建构→迁移」名不副实 | **P0** | 🟡 26/26 章探究轮题面已改写（陈述句 0.0%，验收①达标）；建构/迁移轮深化待续 |
| **B9** | 轮次标签编号错乱（纯编校，可脚本修） | **P0** | ✅ 已完成（`fix_labels.gd`，错位归 0） |
| **C1** | 重复通关无限刷经验/金币 | **P0** | ✅ 已完成（经验仅星升；重复奖励×0.3/日封顶） |
| **C2** | 星级只升不降 + 免费重试 + 四选一 → 进度可刷 | **P0** | ✅ 已完成（当日第 3 次起星级上限 2） |
| **A5** | 关卡 JSON 校验器（schema + 编校） | **P0** | ✅ 已完成（`check_questions.gd` + 基线） |
| **A10** | 公式来源单一化：新数据直接写 LaTeX | **P1** | 🟡 已支持 `$$…$$` 直写 LaTeX（`InlineMath` + 校验器已适配）；旧 `{f:}` 兼容，待存量迁移 |
| **A2** | 遗留模块（`SolidChallenge` / `ConicStage`+C1~C3）定策略 | **P1** | 决定继续删还是冻结 |
| **A3** | `Battle.gd` 死代码处理 | **P1** | 614 行不再增长 |
| **A6** | CI（headless 四件套自动化） | **P1** | ✅ 已完成（`.github/workflows/check.yml`） |
| **A11** | UI/交互层缺自动化断言（测试只盖纯逻辑） | **P1** | ✅ 已完成（`tests/UiSmoke`：342 断言 + 反向验证 + 入 CI） |
| **A12** | `questions.json` 变成第二份权威题库（与现行数据冲突） | **P1** | 数据层也有死代码 |
| **A13** | 资源体积治理（`.xcf` 入库、13.8MB 字体、未排除） | **P1** | 🟡 部分完成（`.xcf` 出库 + 图标降采样：46.8→29.6MB；残留：字体替换/背景压缩） |
| **A14** | `export_presets.cfg` 残留第三方机器路径 | **P1** | ✅ 已完成（统一 `build/…`） |
| **A15** | 元游戏内容硬编码在 `GameData.gd` | **P2** | 与「改内容只改 JSON」相悖 |
| **A16** | 立几方法关内容在 GDScript（两套内容管线） | **P2** | ~1900 行代码当内容 |
| **A17** | 数据文件命名易混（`conic`/`conics`、`vector`/`vectors`） | **P2** | 改错文件静默失效 |
| **A18** | 内容数据异常时缺用户可见兜底 | **P1** | 坏档 → 空白知识体系 |
| **A19** | 多用户切换的会话状态残留 | **P2** | 切用户丢萌宠问候 |
| **B13** | 朗读/无障碍路径不完整且双路径不一致 | **P1** | 听题用户拿不到数学内容 |
| **B2** | 每关题量 3 → 5~8 | **P1** | 掌握度信号太弱 |
| **B4** | 实验与追问不闭环 | **P1** | 探究轮形同虚设 |
| **B5** | 干扰项改为诊断性干扰项 | **P1** | ✅ 已完成（2026-10-20 收官：黑名单校验器 + 42 轮整改 + 抽检 30 题；`tools/sample_distractors.gd`） |
| **B6** | 选项过短、退化为结果核对 | **P1** | 概念性误解测不出来 |
| **B7** | 图片选项回归 LaTeX 文本 | **P1** | 180 处图片选项 |
| **B11** | 模块间质量方差过大 | **P1** | 同一品牌下深度差 3 倍 |
| **A4** | 上帝对象拆分（`GameData`/`StageBase`/`TheoremTree`） | **P2** | 趁还能读懂 |
| **A7** | 版本声明漂移（文档 vs `project.godot` vs GDExtension） | **P2** | ✅ 已完成（文档基线 + 版本策略已记录） |
| **A8** | 「地图」隐喻套在清单结构上 | **P2** | 产品层，长期方向 |
| **A9** | 工作区残留（`*.log` / `*.pck`） | **P2** | ✅ 已完成（已清理） |
| **B8** | 正确项恒写在第 1 位（92.7%） | **P2** | 编校规范 |
| **B10** | 题干套路化与重复 | **P2** | 编校质量 |
| **B12** | 提示语泄露答案 | **P2** | 编校质量 |
| **B13** | 朗读/无障碍路径不完整且双路径不一致 | **P1** | 听题用户拿不到数学内容 |
| **D1** | 2D 探究器无过渡动画（拖动=瞬时跳变） | **P1** | 看不见"量在怎么变" |
| **D2** | 演示动画只覆盖 1/26 个关卡文件 | **P1** | 228 关只有 12 关有 |
| **D3** | 动效全在"结果反馈"，缺"理解型动效" | **P1** | 强化情绪而非数学因果 |
| **D4** | 动效令牌缺失 + 演示不可控 + 无障碍粒度不足 | **P2** | 44 处裸时长、无法重播 |
| **E1** | 知识点覆盖矩阵 + 校验器（内容补全的前置） | **P0** | ✅ 已完成（`data/knowledge_map.json` + `check_knowledge` → `docs/知识点覆盖矩阵.md`；硬缺口基线随 E2 收敛，现 2 条） |
| **E2** | 补齐薄弱章节题量（8 章 ≤4 关，最少仅 6 题） | **P0** | ✅ 已完成（2026-10-19）：27 章全部 ≥6 关（知识章 9 章 + 方法章 `function_methods`、`conic` 各补齐到 6 关）；薄弱章节 **11 → 0** |
| **E3** | 补全 15 个整块缺失的教材必学知识点 | **P1** | ✅ 已完成（13 条落成关卡，#1/#11 用户判定教材已删跳过；末两条 `vector_physics`/`prob_simulate` 2026-10-20 收官） |
| **E4** | 方法章/专题章过薄且与知识章脱节 | **P2** | 🟡 function_methods、conic 均已 1→6（2026-10）；余 `thinking` 专题章与知识章引用关系待强化 |
| **E5** | 与 6 版教材对齐的持续核对流程 | **P1** | 换版本只改排序不改覆盖 |
| **F1** | 在线 TTS 的合规与稳定性（外发题目文本） | **P0** | ✅ 客户端策略完成（默认关闭+明示同意+隐私政策）；官方 API/商店表单并入 F2 |
| **F2** | 发布准备（包名/版本/签名/targetSdk） | **P0** | ✅ 包名=cn.edu.mathgates、版本脚本、targetSdk35、签名位就绪；残留 keystore/真机 |
| **F3** | 性能与耗电（3D 每帧渲染、背景常驻重绘） | **P1** | 静止时无信息增量 |
| **F4** | 桌面端键盘操作（主流程完全缺失） | **P1** | 已发布 Windows 版 |
| **F5** | 存档版本化与进度迁移（换机即丢） | **P2** | 无导出/导入 |
| **F6** | 首次引导与机制说明 | **P2** | 无 tutorial |
| **F7** | 授权与第三方声明缺失（LICENSE / 素材来源 / 教材改编） | **P0** | ✅ LICENSE+第三方声明齐备、排除 GPLv3 字体；残留：标题字体替换/素材签字 |
| **G1** | 错题间隔重复（SRS 遗忘曲线排程） | **P1** | review_order 无时间维度 |
| **G2** | 关卡作者工具链（编辑器 + 实时预览） | **P1** | 🟡 预览器 + 脚手架已落地（`LevelPreview.tscn` + `scaffold_level.gd`，入 CI）；编辑态仅覆盖 q/ask/opts/ans/hint/explain/scene |
| **G3** | 学习报告 / 家长视图（可导出、含趋势） | **P2** | 无导出、无时间维度 |
| **G4** | 云同步（**决策项：暂不实施**，需先做隐私评估） | **P2** | 先由 F5 覆盖大部分场景 |
| **G5** | 音效与配乐（**决策项：先确认是否刻意不做**） | **P2** | 无 BGM，音效已完整 |

### 0.2 工期估算与实施顺序（**全部 AI 产出**模式）

**口径与前提**
- 本项目为**全 AI 产出**：AI 负责写代码/写数据/跑测试，人负责**决策、真机验证、目视验收、数学终审**。
- 校准依据：最近 6 个自然日（`2026-10-11` ~ `10-16`）的 **70 次提交**，交付了
  MicroTeX GDExtension 全链路、lab3d 子系统（`SolidBuilder` 842 行）、6 模块迁移到 LabStage、
  游戏化 P1~P3、多章教材重构、6 版教材系统 —— 约 **1~1.5 个重大项目/天**。
- ⚠️ **测量限制**：git 历史**无法测量项目主体的真实耗时**——首个提交 `968af71`
  已是 3148 个文件的「初始提交」（+92,579 行）。故基准只能取上述 6 天窗口。

**结论**

| 口径 | 估算 |
|---|---|
| 全清单（55 条） | **6~12 周**（全职盯） |
| 最小可上架子集 | **1~2 周** |

**瓶颈已从"写"转移到"验"**——AI 产出不是限制，真正的限制是：
① **数学正确性终审**（批量产题错误率不可忽略，返工量 ×2~3）；
② **真机/目视**（F2 签名安装、F3 耗电、D2 动效观感、B 类题目可读性）；
③ **决策**（A8 / A16 / F2 包名 / G4 / G5）。

**执行顺序（六步）**

| 阶段 | 内容 | 估算 | 为什么在这个位置 |
|---|---|---|---|
| **第 0 步 · 护栏** | **A5** 校验器 · **A6** CI · **G2** 作者工具链 · **A11** UI 断言 | 5~9 天 | 全 AI 模式下，校验器 + CI 是"内容能批产且自证没坏"的**前提**；跳过则返工吃掉全部压缩出的工期 |
| **第 1 步 · 内容能力** | **D1/D2**（2D 补间层 + `anim` 覆盖）· **B1**（interact/填空/多选） | 1~2 周 | 内容必须先有可用的题型与演示能力，否则写完还要返工 |
| **第 2 步 · 内容批产** | **B + E**（约 300~400 轮新题 + 400~700 轮重写） | 4~8 周 | 最大项，可与第 3 步并行；**每批产出即跑校验器 + 抽检**，不要攒到最后验 |
| **第 3 步 · 收敛与上架** | **A1/A2/A4** 收敛 · **F1/F2/F7** 合规与签名 · **C1/C2** 防刷 | 2~3 周 | 与第 2 步并行推进 |
| **第 4 步 · 收尾增强** | **G3** 学习报告 · **G1** SRS · **D3/D4** 动效深化 | 1~2 周 | 内容与上架稳定后再做 |
| **决策项（最先）** | **A8** · **A16** · **G4** · **G5** · **F2 包名** | 1~2 天 | 只有人能拍板；其中 **F2 包名上架后不可改**，必须最先定 |

**最小可上架子集（1~2 周）**

| 项 | 为什么必须 |
|---|---|
| **F2** release 签名 / 包名 / targetSdk | 没有 release 签名装不上商店；包名上架后不可改 |
| **F7** 授权与第三方声明 | 商店审核硬门槛；**与 A13 的字体替换可一并解决** |
| **F1** TTS 合规 | 未成年人数据外发 |
| **A13** 资源体积 | APK 61MB 偏大 |
| **A18 / A14 / A9** | 便宜且防崩溃/防换机翻车 |
| **C1 + C2 / B9** | 否则成长体系可被刷穿、错题记录错乱 |

**全 AI 模式特有风险（靠机制兜，不能靠记性）**
1. **风格漂移**：跨会话批量产内容，题干句式/命名/四阶段结构容易不一致 → 靠**模板 + A5 校验器**兜住。
2. **假绿灯**：若回归基线本身不可信（如 `Tests.gd` 的关卡门卡是**手抄白名单**），AI 会"改坏但显示通过" → **A6/A11 的可信度直接决定前面能跑多快**。
3. **数学错误的系统性偏差**：AI 倾向生成"看起来对"的干扰项（**B5 已证**：全库干扰项都是范畴错误型）→ B5 的"干扰项必须对应真实错误路径"必须**写进批产模板**，不能事后补。

**仍需人工的环节（无法 AI 化）**
决策（A8 / A16 / F2 包名 / G4 / G5）· 真机验证（F2 签名安装、F3 耗电、Android 端公式渲染）·
目视验收（D2 动效观感、B 类题目可读性）· **数学抽样终审**（质量闸门）。

### 0.3 续接点（每次收工更新）

- **最后提交**：`9c3edb0`（`docs(TODO)` 续接点回填，对应 `8aa1abe` 导数及其应用章扩题）；前一提交链：
  `8aa1abe`（B2 导数及其应用章）→ `d023dbb`（docs 回填）→ `6acb576`（B2 立体几何初步章）→
  `e8a5bf6`（B2 不等式章）→ `515d933`（B2 函数与分段章）→ `5c79298`（B2 随机变量章）→
  `b42943f`（B2 递推求通项章）→ `79e4ef8`（B2 圆锥曲线章）→ `26332eb`（B2 复数章）→
  `7ccfe5d`（E3 验收补齐 #2/#3）→ `6fb59c7`（B5 收官），已 push（`main` 与 `origin/main` 同步）。
  本轮数学思想综合章扩题随后提交。
- **本轮交付（2026-10-20，第十二轮）**：**B2 扩题启动（复数章）+ E3 验收补齐**。
  - E3 #2/#3 补齐验收轮：`ineq_props` 补 `3-6`（对称性 a>b⇔b<a 与传递性 a>b、b>c⇒a>c 辨析；
    首版「无法确定」干扰项命中 B5 黑名单，已改为「a=c（误把传递当相等）」），`ineq_param` 补
    `4-6`（全体实数解需 a>0 且 Δ<0，辨析 Δ≤0 的取等混淆）、`4-7`（先比较两根 1 与 m 的大小再写解集）；
    E3 清单 #2/#3 由「无 ✅」改为 ✅，15 条全部落定（13 条落成关卡，#1/#11 跳过）。
  - B5 总览行仍写「四选一实际是二选一」，与标题 `[x]` 不一致 → 改 ✅ 并补证据。
  - **B2 扩题**：复数（24 → 30）、圆锥曲线（18 → 30）、递推求通项（18 → 30）、随机变量及其分布
    （24 → 30）、函数与分段（28 → 30）、不等式（29 → 33）、立体几何初步（52 → 64）、
    导数及其应用（28 → 40）、数学思想综合（22 → 34）共补 80 轮，新增轮次以填空为主
    （38 填空 + 42 四选一），非四选一占比约 19.1% → 21.1%。
  - 全量回归绿：`CHECKED 90` / `TESTS 1245` / `SMOKE 285` / `UI-SMOKE 368`（fail=0）/
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7305` / `QUESTION-CHECK 269 关 1026 题 0 new（warn 3 与基线同）` /
    `KNOWLEDGE 275 点 hard-gaps=0` / `ASSETS 29.98`。
  - 上一轮（第十一轮）：**B5 收官**（`6fb59c7`：抽检 30 题 + `sample_distractors.gd`）；
    第十轮：B5 批次二（`32f064e`）；第九轮：B5 批次一（`0ddf55e`）；
    第八轮：E3 全条收官 `vector_physics` #14（`7f94b7c`）、`prob_simulate` #15（`9534189`）；
    第七轮：E3 #13 `93240c1`；第六轮：#12 `0a3aae0`；第五轮：#10 `b3205f0`；第四轮：#9 `0bb0a2e`；
    第三轮：#7/#8 `5d784bb`；第二轮：#6/#4 `017f04b`/`d4a6a40`、#5 `1630a99`。
- **下次建议顺序**（按性价比）：
  1. **B2 扩题**（3.81 → ≥5 题/关）/ **B1 达标**（21.1% → ≥30%）——大批量内容生产，按章成批、每章一个 commit；
     下一批建议从看板最薄的章节取（集合与逻辑 8/30…），
     **批产模板必须内建 B5 规范**（错误路径型干扰项，见第 1 节第 129 行的教训），新题先过 `check_questions`
     黑名单与 `sample_distractors` 抽检；新增轮次优先用填空/多选，顺手抬 B1。
  2. **B6 选项过短/理由选项占比**（可与 B1/B2 同批推进：新题直接用「理由选项」）。
  3. **A13 字体替换 + F7 素材签字 + F2 keystore/真机** —— 需人工决策/下载/目视（AI 无法替代，也是上架硬门槛）。
  4. 决策项待拍板：**A2/A3/A12**（遗留模块与 `Battle`/`questions.json` 去留）、**A17**（数据文件命名）、**G4/G5**。
- **收工前必做**：跑全量校验（`check_all` / `Tests` / `smoke_scene` / `UiSmoke` / `LabSmoke` /
  `check_questions` / `check_knowledge` / `check_assets` / `LevelPreview --smoke`），并同步 §9.2 基线数字。

---

## 1. A 类 · 架构与工程收敛

### [x] A1 · `SequenceStage` 迁移到 `StageBase`（P0）

**现状（证据）**
- `scripts/modules/sequence/SequenceStage.gd`（712 行）`extends Control`，**未继承** `StageBase`，
  自行实现了 `_ready/_build_ui/_build_choices/_choice_row/_on_choice/_reveal_choices/_level_ok/_wrong/
  _use_hint/_next_pressed/_finish/_show_feed/_update_hud/_refresh_nav/_spawn_confetti` 等约 28 个同名函数，
  与 `scripts/screens/StageBase.gd`（1092 行）重复。
- 后果：`StageBase` 上的 P1（BOSS 战层）/P2（连击条、限时降星、三星引导、极速奖励）**在 6 个数列关卡
  （`archetype:"SLIDER"`，`scene:res://scenes/SequenceStage.tscn`）上全部缺失**，形成功能双轨。
- 参照实现：`scripts/modules/lab/LabStage.gd`（196 行）只做钩子覆盖，`SequencePlane` 可原样复用为 `_build_view` 的视图。
- 同一问题在游戏化交付时已被记录（原 `TODO-gamify.md` P2 范围说明）：该层只改 `StageBase`，
  而 `SequenceStage` / `SolidChallenge` / `ConicStage` 是**独立实现**（各自 `_finish`、无 `_streak`）→ 本条目负责收口。

**做法**
- `SequenceStage` 改为 `extends StageBase`，覆写配置钩子（`_module()/_pet_message()/_wrong_text()/_default_title()/
  _default_color()/_use_rich_text()/_load()/_build_view()/_load_q()/_on_confirm()/_build_interact()/_build_explore()`）。
- 删掉与基类重复的实现；`SequencePlane`（675 行）保持不变。
- 迁移后核对：数列关卡应自动获得连击条/计时/三星引导；BOSS 关（若有）获得 BossHud。

**已实施（记录）**
- `extends StageBase`，仅保留数列专属部分：`_load()`（recurrence_levels.json）、`_build_view()`（SequencePlane 画布）、
  `_load_q()`、`_build_explore()/_build_interact()/_on_confirm()`（explore 两段式）、`_refresh_live()` 与配置钩子；
  763 → 185 行，无与基类同名函数。
- 探针已验（临时脚本，验后删）：`extends StageBase`、`_combo_bar != null`、`rules{time_limit}` → `_timing=true`、
  explore→追问构建 4 选项。

**验收**
- `SequenceStage.gd` 行数显著下降（目标 < 300），无与基类同名函数重复。
- `res://tests/Tests.tscn`、`res://tools/smoke_scene.tscn`、`res://tests/LabSmoke.tscn`、`tools/check_all.gd` 全绿。
- 运行期探针（临时脚本，用完删）验证 `recur_add`：连击条存在、`_timing` 按 `rules{}` 生效。

---

### [ ] A2 · 遗留关卡模块定策略（P1）

**现状（证据）**
- 当前 230 个关卡里：`LabStage` 182、`Lab3DStage` 31、`SequenceStage` 6、`SolidChallenge` 6、`ConicStage` 3。
- 遗留实现：`scripts/modules/solid/SolidChallenge.gd`（977 行）、`scripts/modules/conic/ConicStage.gd`（528 行）
  + `scripts/modules/conic/scenes/C1.gd`（672 行）/`C2.gd`（337）/`C3.gd`（256），均为自绘关卡，不走 `StageBase`。
- 几何章节迁移（圆/椭圆/向量/直线/立体几何/空间向量）已完成，但这两块没动。

**做法（二选一，明确写进 README）**
- **迁**：按 A1 的做法迁到 `LabStage`（若几何演示可用 `LabPlane` 表达）。
- **冻结**：在文件头加 `## 冻结：不再新增功能，仅修复缺陷`，并在 `README.md` 的目录说明里标注，
  防止后续继续在旧实现上加功能。

**验收**
- `README.md` 的模块说明与代码现状一致；遗留文件顶部有明确状态标注（或已删除）。

---

### [ ] A3 · `Battle.gd` 死代码处理（P1）

**现状（证据）**
- `scripts/screens/Battle.gd`（614 行）仅在关卡**没有** `scene` 字段时作为回退占位
  （`GameData.gd:490 / 1275 / 1418 / 1434`，`TheoremTree.gd:1509`），而当前所有关卡都带 `scene` → 从不出现。
- `docs/关卡游戏化方案.md` §9 决策记录第 5 条已确认：保留 `Battle.tscn` 作回退占位、未删；
  `HexAvatar`/`HpBar` 已抽到 `scripts/ui/BossHud.gd`，`Battle.gd` 改为引用它。

**做法**
- 若保留回退能力：保留脚本，但补一条 `Tests.gd` 用例证明「缺 scene 的关卡能进 Battle 且不报错」，
  并在文件头写清它是**回退关**而非历史遗留。
- 若不保留：删除 `Battle.gd`/`Battle.tscn`，把 5 处回退改成显式报错（`push_error` + 跳回知识体系）。

**验收**
- 二选一落定，`README.md` 有说明；`check_all.gd` 0 failures。

---

### [ ] A4 · 上帝对象拆分（P2）

**现状（证据）**
- `scripts/autoload/GameData.gd` **1548 行**：课程表 + 进度 + 存档 IO + 勋章 + 称号 + 领域掌握度 + 萌宠
  + 每日任务 + 经济 + 地图宝箱/事件 + 错题本 + 多用户，全在一个 autoload 类里。
- `scripts/modules/line/TheoremTree.gd` **1496 行**：同一脚本同时充当 `WorldMap.tscn`（`kind="method"`）
  与 `TheoremTree.tscn`（`kind="knowledge"`）。
- `scripts/screens/StageBase.gd` **1092 行**：HUD + 答题 + 选项乱序 + BOSS 层 + 节奏/计时 + 结算 + 导航。

**做法（增量，不必一次到位）**
- `GameData` → 组合子对象：`Curriculum`（课程/教材/章节）、`Progress`（星级/记录/掌握度）、
  `Economy`（金币/经验/道具/商店）、`Pet`、`Adventure`（宝箱/事件）、`WrongBook`。保持 `GameData.xxx()` 门面不破坏调用方。
- `StageBase` → 把 BOSS 层（`BossHud` 交互）、节奏层（`ComboBar`/计时/`_grade`/`_next_star_hint`）、
  结算面板（`_victory*`）拆成独立 `Control` 子类。
- `TheoremTree` → 抽出「章节数据源 + 布局」与「两种呈现」；或因 A8 另立新场景。

**验收**
- 单文件行数上限约定（如 ≤ 600）写进 `README.md`；拆分后四件套全绿、无行为变化。

---

### [x] A5 · 关卡 JSON 校验器（P0，B9/C 类的防线）

**现状（证据）**
- 现有校验只有 `tests/Tests.gd::_test_lab_data()` 里的**手抄 id 白名单**（每加一关必须手动补一行）。
- 无 schema、无字段必填校验、无 `ans` 越界校验、无题干/选项去重、无轮次标签编号校验。
- B9 列出的 6 类编校错误，现有测试**一个都没抓到**。

**做法**
- 新增 `tools/check_questions.gd`（SceneTree 脚本，风格对齐 `tools/check_all.gd`），校验：
  1. 结构：`data/*_levels.json` 每个关卡含 `levels[]`，每轮含必需字段（`q`，或 `type:"interact"` + `gate`/`answers`）；
  2. `ans` 为 int 时 `0 <= ans < opts.size()`；为 Array 时全部合法且不重复；
  3. 选项无重复；题干（同文件内）无重复；
  4. **轮次标签编号 == 关卡序号**（B9 的自动化）；
  5. 每个公式片段能被 `data/inline_math.json` 覆盖（可复用 `tools/check_inline.gd` 的逻辑）；
  6. 图片选项计数（B7 的进度看板）。
- 输出形如 `QUESTION-CHECK: N levels / M questions / X problems`，有问题则逐条打印并 `quit(1)`。

**验收**
- 当前仓库跑出的 **X > 0**（应能完整复现 B9 的清单）；
- 把 `tests/Tests.gd` 里的手抄 id 白名单替换为对该校验器的调用（或至少保持同步）。

---

### [x] A6 · CI（P1）

**现状（证据）**
- 仓库根目录**没有 `.github/`**；四件套只能手动跑（命令见第 9 节）。
- 所有校验脚本都是 headless 可跑的，接入成本极低。

**做法**
- 加 `.github/workflows/check.yml`：装 Godot 4.7.2 → `--headless --import` → 跑
  `check_all.gd` / `tests/Tests.tscn` / `tools/smoke_scene.tscn` / `tests/LabSmoke.tscn` / `tools/check_questions.gd`，
  解析退出码与末尾汇总行。
- 需注意：`gdextension/bin/` 不在库里（`.gitignore`），CI 上 `InlineMath` 会走 PNG 回退路径 —— 这是**预期行为**，
  正好顺带回归「扩展缺失时的降级不崩」。

**验收**
- PR 上能看到五条 job；故意改坏一条数据（如 B9 的标签）能红灯。

---

### [x] A7 · 版本声明漂移（P2）

**现状（证据，已核对）**
- `project.godot` → `config/features=PackedStringArray("4.7", "GL Compatibility")`（本机引擎 4.7.2）。
- `README.md` 写 Godot 4.7。
- **`docs/环境配置.md` 仍按 4.4 写**：第 24 行（Godot 4.4.1）、第 32~33 行（「关键对齐」）、
  第 92 行（`config/features=("4.4",...)`）——与现状不符（过期）。
- `math_tex.gdextension` → `compatibility_minimum = "4.4"`，godot-cpp 用的是 **4.4 分支**，
  成品由 4.7.2 引擎加载（扩展 4.4 可被 4.7.2 加载，实测通过，但属隐性风险）。

**做法**
- 更新 `docs/环境配置.md` 的版本基线（或把 4.4.1 标注为「历史：仅用于构建/调试扩展」）。
- 决定并记录 GDExtension 的版本策略：继续 `godot-cpp 4.4 + 引擎 4.7.2`（并写明为何可接受），
  或升到与引擎同分支。结论写进 `README.md`。

**验收**
- 全仓库搜索 `4.4` 只剩有明确上下文（历史记录 / `compatibility_minimum` 的说明）的条目。

---

### [ ] A8 · 「地图」隐喻套在清单结构上（P2，产品层）

**现状（证据）**
- `WorldMap.tscn` 实际就是 `TheoremTree.gd`（`kind="method"`），是**章节列表**；
  P3「地图冒险化」（分支路线/宝箱/Boss 门）是在列表节点上做的装饰。
- `docs/关卡游戏化方案.md`（§5.2 实现选型变更、§5.4 交付说明）已确认「地图不是地图」。

**做法**
- 若长期要「探索感」：先把数据结构抽成「节点坐标 + 邻接表」再谈装饰；
- 若接受现状：在 `docs/关卡游戏化方案.md` 明确写「地图 = 章节路径的可视化，不承诺空间探索」，避免后续预期错位。

**验收**
- 文档里有明确结论；不留下「以为要做真地图」的模糊地带。

---

### [x] A9 · 工作区残留清理（P2）

**现状（证据）**
- 仓库干净（`git status` 无未跟踪改动），但工作区根目录残留：
  `build_microtex_build.log`、`import3.log`、`import4.log`、`import_inline.log`、`inline_test.log`、
  `main_boot.log`、`main_ext.log`、`main_parse.log`、`run2~5.log`、`user_load.log`、`衍数阁.pck`。
- 均已被 `.gitignore`（`*.log`、`*.pck`）覆盖，**不属于仓库问题**，仅为本地整洁。

**做法**：清理上述文件；需要保留的日志移入 `build/`（已忽略）。

**验收**：根目录只剩源码/配置/文档/美术/音效/数据。

---

### [ ] A10 · 公式来源单一化（P1）

**现状（证据）**
- `data/inline_math.json` **14186 行 / 824 条映射**，是「数学片段 → 图片/LaTeX」的唯一查表来源，
  运行时由 `scripts/ui/InlineMath.gd` 按 CJK 切分后查表。
- 关卡数据里的公式是 Unicode 下标（如 `aₙ₊₁−aₙ=d`），**漏映射就静默退化**（字形缺失或回退成图片）。
- 环境已具备 LaTeX 运行时渲染（MicroTeX GDExtension，TODD.md 任务 6~8 已完成，824/824 已补 `latex` 字段）。

**做法**
- 新写的题目/文案**一律直接在数据里写 LaTeX**（`{f:...}` 或 `$$...$$`），不再新增 Unicode 数学片段；
- `inline_math.json` 定位改为**历史兼容层**，在文件头/README 注明「不再新增条目，仅存量维护」；
- 由 A5 的校验器第 5 条兜底「新增片段必须已映射」。

**验收**
- `README.md` 的「改内容」小节有明确写法示例（LaTeX 优先）；
- 新增关卡不再依赖新映射条目。

**已实施（记录，`$$…$$` 直写 LaTeX）**
- `InlineMath.gd` 新增 `$$LaTeX$$` 支持：`inline_formulas` 先做 `_inline_dollar`（经 MicroTeX 渲染为内联图，
  无扩展时回退原文），`strip_formulas` 增 `_dollar_speech`（口播）；`>`/`<` 补入通用 LaTeX→口播表。
- 校验器适配：`check_questions.gd`/`check_inline.gd` 扫描前**剥离 `$$…$$` 区段**（不再触发「未覆盖」）。
- 回归测试：`Tests.gd` 新增 `_test_inline_math()`（7 条断言：`$$` 去除、口播、分式、渲染/回退、`{f:}` 兼容）。
- README「改内容」增写法示例；E2 的 `inequalities` 4 关已全部改用 `$$…$$`（177 段，渲染 0 失败）。
- **残留**：存量 228 关仍用 Unicode 数学片段 + `{f:}` 命名（`inline_math.json` 未动）；`A5` 第 5 条兜底保留。

---

### [x] A11 · UI/交互层缺自动化断言（P1）

**现状（证据）**
- `tests/Tests.gd`（约 1220 例）基本全在测 `GameData` 等**纯逻辑**；UI 层只有
  `tools/smoke_scene.tscn`（`SMOKE: 238 ok`，断言口径是「场景能构建、不报错」）
  与 `tools/capture_scene.gd` / `tools/dev_shots.gd`（出图后**人工目视**）。
- 缺断言的对象：关键节点是否存在（HUD/答题面板/结算面板）、选项数 == `opts` 数、
  选项乱序是否真的生效、`UI.fs()` 是否随 `UI.S` 生效、多分辨率下是否挤压（P3 只做过一次人工验证）。
- 影响面：A1（SequenceStage 迁移）与 B 类数据改动**只能靠人眼验**，回归网有洞；这也是历史上
  「（可选）GUI 下逐章目视复核」一条长期挂在待办里、始终没人做的原因（**本条目承包它**）。
- 可复用基建已具备：`smoke_scene` 已能逐场景构建；`tools/lab3d_render_check.gd` 已用
  **像素占比**做「空白场景」自动判定，思路可直接推广到 2D 关卡。

**做法**
- 新增 `tests/UiSmoke.gd(+.tscn)`：对每类舞台（`StageBase` 的各个子类）断言
  「关键节点存在 + 选项数匹配 + 结算面板可弹出 + 进入/退出不报错」；
- 断言「选项乱序生效」：同一轮反复构建 N 次，正确项显示位置不恒为同一值（保护 B8 的修复）；
- 断言「字号随 `UI.S` 生效」：调 `S` 后取关键 Label 的 `font_size` 应线性变化；
- 把 `lab3d_render_check` 的像素占比阈值法推广成 2D 关卡截图回归（基线图存 `build/`，不入库）；
- 两者都纳入 A6 的 CI。

**验收**
- 新增 ≥ 20 条 UI 断言，可在 `--headless` 下跑通；
- 反向验证：故意注释掉 A1 迁移后的 HUD 构建，应能红灯；
- 「逐章目视复核」可由该套断言替代大部分，届时可关闭该历史遗留项。

**已实施（记录）**
- 新增 **`tests/UiSmoke.gd` + `tests/UiSmoke.tscn`**，headless 运行输出 `UI-SMOKE: 342 ok, 0 fail`（退出码非 0 表示有失败）。
- 断言内容（**342 条**，远超要求的 20 条）：
  1. `StageBase` 家族（`LabStage`/`Lab3DStage`/`SequenceStage`）每关采样断言 **14 个关键节点**存在
     （`_ui`/`_panel`/`_ans`/`_q`/`_next`/`_hint`/`_victory`/`_dim`/`_v_title`/`_v_rate`/`_v_star_row`/`_v_score`/`_prog`/`_coins`）；
  2. 逐轮数据级不变量：`opts.size()≥2`、`ans` 在范围内、多选非全选；
  3. 实际按钮数 == 数据 `opts` 数，`badge`/`panel` 与按钮数一致；
  4. `_opt_order` 是**排列**、`_disp_of/_orig_of` **往返一致**；
  5. 顺序相关选项（以上/都对…）**不打乱**；
  6. **乱序确实生效**：同一轮重建 12 次，出现 ≥2 种顺序（保护 B8）；
  7. `_finish()` → 结算面板/遮罩可见、星级行已渲染、标题非空；
  8. `UI.fs()` 随 `UI.S` 线性生效（1.0/1.4/2.0 → 20/28/40，最小 1）；
  9. legacy 场景（`ConicStage`/`SolidChallenge`/`Battle`）能构建出子节点。
- **反向验证通过**：临时注释 `StageBase._ready()` 的 `_build_ui()`，`UiSmoke` 立即红灯（`EXIT=1`，14 条节点断言失败），恢复后回到全绿。
- 已纳入 CI（`.github/workflows/check.yml` 新增 UiSmoke 步骤，`pipefail` + 断言 `0 fail`）。
- 说明：`Battle.tscn` 无课程表样本（占位/死代码，见 A3），用任意真实关卡上下文实例化验证。

---

### [ ] A12 · `questions.json` 变成第二份权威题库（P1）

**现状（证据）**
- `data/questions.json`（12 组 / 42 题）的唯一消费者是 `GameData.questions_for()`，
  而后者**只被 `scripts/screens/Battle.gd:50` 调用**；`Battle` 仅在关卡缺 `scene` 时回退，
  而 `curriculum.json` 的 228 个关卡**全部带 `scene`** → 该通道整体不可达（与 A3 同源）。
- 更关键：其 12 组 key 里有 **5 组与 `data/set_logic_levels.json` 同名**
  （`set_ops` / `set_interval` / `logic_cond` / `logic_neg` / `logic_special`），
  但**逐题比对 5/5 组内容完全不同**（题面、题量都不同：`questions.json` 每组 5 题、
  `set_logic_levels.json` 每组 3 轮）。
- 例（`logic_cond`）：
  - `questions.json`：「'x>2' 是 'x>0' 的什么条件？」等 5 题；
  - `set_logic_levels.json`：「若集合 A 完全落在 B 内…」等 3 轮。
- 另 7 组（`func_mono` / `seq_ap` / `seq_ap_sum` / `seq_gp` / `seq_gp_sum` / `deriv_tangent` /
  `func_piecewise_range`）在现行关卡数据里也不是 key，属迁移前遗留。

**做法**
- 二选一并写进 `README.md`：**删除** `questions.json` + `questions_for()`（若确认 Battle 也一并删，见 A3），
  或**保留但改名并加注释**说明它是历史题库、不参与现行关卡。
- 无论如何，禁止同一 `level_id` 存在两份内容不同的题——由 A5 校验器加一条「跨文件同名关卡数据」检查兜底。

**验收**
- 全仓只剩一份权威题库；A5 校验器输出「跨文件重名」为 0。

---

### [ ] A13 · 资源体积治理（P1）

**现状（证据，已实测）**
- 仓库 tracked 文件合计 **48.4MB**；`art/` 占 **39.9MB**，其中：
  - **9 个 `.xcf`（GIMP 源文件）已入库**：`bg_worldmap.xcf` 5.9MB、`bg_mainhub.xcf` 5.7MB、
    `island_unlocked.xcf` 581KB、`ui_panel.xcf` 534KB、`island_locked.xcf` 504KB、
    `icon_book/icon_lock/icon_map/icon_train.xcf`…
  - **`art/fonts/aidianqianfengxingshu.ttf` 13.8MB**，而它只被 **3 处**用到
    （`BootSplash.gd:40` / `Login.gd:51` / `MainHub.gd:173` 的 `UI.title_font()`，即品牌大标题）。
  - `bg_worldmap.png` 5.0MB、`bg_mainhub.png` 2.4MB 未做压缩优化。
- `export_presets.cfg` 的 `exclude_filter` **没有排除 `art/*.xcf`**
  （只排除了 `third_party/*`、`gdextension/build*`、`tests/mathtex_test/*`、`build/*`、`docs/*`、`*.log`、`*.pck` 等）
  → 源文件会被打进包；实测 **APK 60.9MB**（debug）。

**做法**
- `.xcf` 源文件移出仓库（或入 `assets_src/` 并加 `.gitignore`；需留档则用外部存储/LFS 单独说明）。
- 标题字体做**子集化**（只保留标题实际用到的汉字，或换成更小的行书字体）；
  背景 PNG 走压缩/降采样（`optipng`/`pngquant` 或改用 WebP）。
- `exclude_filter` 增补 `art/*.xcf`、`art/fonts/*.xcf` 等非运行时资源。

**验收**
- tracked 体积降到 **≤ 20MB**；`art/` 无 `.xcf`；
- 重新导出 APK 体积明显下降（并记录新基线）；
- 首页/知识体系/关卡内观感无回退（用 A11 的截图回归比对）。

**已实施（记录）**
- **`.xcf` 移出仓库**：9 个源文件（13.6MB）移到 `assets_src/art/`（`.gitignore` 新增 `assets_src/`），
  `art/` 已无 `.xcf`；`export_presets.cfg` 四个预设 `exclude_filter` 增 `assets_src/*, *.xcf`（源文件不再进包）。
- **项目图标降采样**：`icon.png` 2048×2048/3.91MB → **512×512/0.33MB**（仅作项目/窗口图标；Android 图标另由 `art/android/*` 提供）。
- **新增工具**：`tools/optimize_art.gd`（幂等降采样：`icon.png`≤512、`art/**/*.png`≤2048；默认 dry-run）、
  `tools/check_assets.gd`（护栏：源文件入库→退出 1；总体积 >22MB 告警 / >40MB 失败）。
- **CI**：`.github/workflows/check.yml` 增 `check_assets` 步骤；`docs/资源优化.md` 记录全过程。
- 实测：仓库 tracked **46.8MB → 29.6MB**（`ASSETS: 29.59 MB over 3080 files, banned=0, oversize=0`）；
  `res.bin` 亦因 F7 从 652KB→297KB。五件套全绿。

**残留（需决策/换机）**
- ⚠️ **字体 `art/fonts/aidianqianfengxingshu.ttf`（13.5MB）**：替换为 OFL 字体（见 F7）后仓库可降到 ≤20MB，
  与 F7 是同一件事、一并解决；
- ⚠️ 两张 1080p 背景（`bg_worldmap.png` 4.9MB / `bg_mainhub.png` 2.3MB）未压缩：本机无 `pngquant`/`cwebp`/ImageMagick，
  需在有工具的环境跑 `pngquant` 或改 Godot 导入压缩，**改后须目视比对观感**；
- ⚠️ APK 新基线需在有 Android SDK 的环境重新导出 release 记录。

---

### [x] A14 · `export_presets.cfg` 残留第三方机器路径（P1）

**现状（证据）**
- `export_presets.cfg` 的 Windows 预设里有：
  `export_path="C:/Users/seewo/Desktop/衍数阁.exe"` —— **`seewo` 不是本机用户**（本机是 `Administrator`），
  是别的开发机的桌面路径残留。换机导出会直接失败或导到意料之外的位置。
- 其余三个预设（Android / arm64 / x86_32）路径已是 `build/…`，正常。

**做法**
- 把该预设的 `export_path` 统一改为 `build/衍数阁.exe`（与其它预设同风格）。
- 顺手核对 `encryption_include_filters` / `encryption_exclude_filters` 均为空（当前为空，正确）。

**验收**
- 全仓搜索无 `seewo`；四个预设的 `export_path` 全部落在 `build/`。

---

### [ ] A15 · 元游戏内容硬编码在 `GameData.gd`（P2）

**现状（证据）**
- `scripts/autoload/GameData.gd` 里以常量硬编码了全部元游戏内容：
  `AVATARS`（可选头像）、`RANKS`（7 级称号阶梯）、`MEDALS`（19 个勋章）、
  `DAILY_MISSIONS`（4 条每日任务）、`DOMAINS`（7 个知识领域）、`LORE`（7 段碑文）。
- 这与 `README.md`「改内容」小节的约定（课程/题库/关卡都在 `data/*.json`）**不一致**：
  改一个勋章文案、加一条每日任务、调称号阈值都要改代码。
- 后果：内容迭代需要开发者参与；也无法给非技术编辑做校验（A5 的校验器目前覆盖不到这些）。

**做法**
- 把这 6 组常量迁到 `data/meta.json`（或按主题拆 `data/medals.json`、`data/domains.json` 等），
  `GameData` 启动时加载，保持现有访问器签名不变（`MEDALS` → `medals_def()` 或保留常量名做转发）。
- 注意**存档兼容**：`medals{}` / `pet_parts{}` 按 id 存储，id 不变即可无缝。

**验收**
- 不改变任何数值的情况下搬迁完成；四件套全绿；A5 校验器能校验 id 唯一性。
- `README.md`「改内容」小节补上这些文件的位置。

---

### [ ] A16 · 立几方法关内容在 GDScript（两套内容管线）（P2）

**现状（证据）**
- `data/solid_methods.json`（6 个 method）里的 `topic` 字段指向 **GDScript 文件**：
  `res://scripts/modules/solid/topics/{complement,inout,geom_sphere,anglepyramid,vector_sphere,insphere}.gd`，
  `SolidChallenge.gd:176 _load_topic()` 直接 `scr.new()` 实例化后 `build()`。
- 这 6 个脚本合计 **约 1900 行**（`geom_sphere.gd` 491、`vector_sphere.gd` 313、`inout.gd` 308…），
  即**这 6 个关卡的图形内容以代码形式存在**，而同类内容在 `lab3d` 里是 JSON 驱动的
  （`SolidBuilder.gd` 由 JSON 描述生成网格）。
- 对应关系已核对无缺口：curriculum 的 `solid_complement/vector/geom/insphere/inout/angle`
  六个关卡 ↔ `solid_methods.json` 的 6 个 method ↔ 6 个 topic 脚本。
- 结论：**同一个学科存在两套内容管线**（JSON 驱动 vs 代码驱动），维护者要学两种写法。

**做法**
- 与 A2 一起决策：短期在 `README.md` 明确「立几方法关属代码驱动，新增内容请优先用 lab3d JSON」；
- 长期评估把 6 个 topic 迁到 `lab3d` 的 JSON 描述能力（若 `SolidBuilder` 已支持所需几何）。

**验收**
- `README.md` 说明两套管线的边界与选择原则；后续不再新增代码驱动关卡。

---

### [ ] A17 · 数据文件命名易混（P2）

**现状（证据）**
- 同时存在且都在用的近似名：
  - `data/conics_levels.json`（6 组，圆锥曲线综合，现行 `archetype:LAB`）
    vs `data/conic_levels.json`（3 组 `C1/C2/C3`，旧 `ConicStage` 专用）
  - `data/vectors_levels.json`（4 组，`vec_*`，平面向量章节）
    vs `data/vector_levels.json`（19 组，`vector_*`，向量 LAB 章节）
  - 另有 `data/functions_levels.json` vs `data/function_lab_levels.json`（后者仅 1 组 `piecewise_range`）。
- 改动时极易改错文件，且错改后**静默失效**（另一份没人用/或用了另一份）。

**做法**
- 结合 A2/A16 的决策统一命名（如旧模块加 `_legacy` 后缀，或直接删除）。
- 在 `README.md`「改内容」小节列出「文件名 ↔ 章节」对照表；由 A5 校验器兜底跨文件重名。

**验收**
- 不再存在仅差复数/后缀的成对数据文件；README 有对照表。

---

### [ ] A18 · 内容数据异常时缺用户可见兜底（P1）

**现状（证据）**
- `GameData._load_curriculum()`（`GameData.gd:362`）：文件缺失或 JSON 损坏时**只 `push_error` 然后 `return`**，
  `chapters` 保持为空；`_load_textbooks()` 同样是静默 return。
- `scripts/modules/line/TheoremTree.gd:656-657`：
  ```
  if GameData.chapters.is_empty():
      return
  ```
  → **静默返回**，页面只画了顶栏，主体**空白**。
- 结果：内容数据一旦出问题，学生看到的是**没有任何解释的空白知识体系**
  （只有开发者能在控制台看到 `push_error`）。
- 对比：**资源层已有完整降级**（`Art.gd` 有图用图、无图代码绘制；`InlineMath` 扩展不可用回退 PNG）——
  缺的是**数据层**的面向用户兜底。

**做法**
- 加"数据异常"兜底：一个提示页/弹窗，说明发生了什么 + 提供
  「重试」「重置内容缓存」「复制错误信息」；而不是静默空白。
- 启动时做一次**轻量完整性校验**（复用 A5 的校验器核心：章节非空、关卡 id 唯一、
  每章至少 1 关、引用的 `lab`/`lab_ref` 能定位到数据文件），失败即走上面的提示。
- 与 F2 联动：**导出前必跑一次完整性校验**，把问题挡在发版之前。

**验收**
- 手动把 `data/curriculum.json` 改成非法 JSON → 运行得到**明确提示**（而非空白页），
  且「重置」后能恢复；
- 校验器在导出流程中被调用一次。

---

### [ ] A19 · 多用户切换的会话状态残留（P2）

**现状（证据）**
- `pet_greeted_session`（`GameData.gd:142`，注释明确写「不存档」）只在
  `scripts/screens/Login.gd:21` 与 `MainHub.gd:53` 被置为 `true`，
  而 `login()` / `logout()` / `create_user()`（`GameData.gd:1611/1626/1639`）**都不重置它**。
- 后果：**同一进程内切换用户后，第二个用户不会得到萌宠问候**
  （`if not pet_greeted_session` 分支被跳过）。
- 已核实**其它状态是干净的**（不是问题，勿重复排查）：
  - `_apply()` 会**无条件**重设 `wrong_log` / `level_records` / `medals`，
    且 `stars` 采用"**先全部清零再套用存档**"的写法（`GameData.gd:1579-1585`），天然防串档；
  - `_save()` 在 `current_user == ""` 时**直接返回**（`GameData.gd`），不会写出空用户名档；
  - 掌握度缓存 `_level_mastery` / `_domain_mastery` 在 `login()` → `_eval_mastery()` →
    `_recompute_mastery()` 里会重建，不残留。

**做法**
- 抽一个 `_reset_session()`，集中重置所有「不存档」的会话态
  （`pet_greeted_session`、`pet_away_days`、`current_level`、`current_chapter_index`、
  `current_level_index`、`review_focus`、`_save_pending`），在 `login/logout/create_user` 后调用；
- 立一条约定写进 `GameData` 顶部注释/README：**新增「不存档」变量必须登记进 `_reset_session()`**。

**验收**
- `Tests.gd` 增用例：同一进程 `A → B` 切换后 `pet_greeted_session == false`；
- 约定有书面记录（注释或 README）。

---

## 2. B 类 · 题目与内容质量

> 本节所有数字来自 26 个 `data/*_levels.json` + `data/questions.json` 的全量扫描，
> 口径与复现方法见第 9 节。**题数合计 754**（关卡文件 712 + 通用题库 42），**关卡组 222**。

### [ ] B1 · 题型单一 → 把已有非选择题型用起来（P0）

**现状（证据）**
- **754 / 754 全是四选一单选**；全库仅 **2 道多选**（`ans` 为数组）。
- 但基础设施**已经存在**：`StageBase`/`LabStage` 支持阶段级 `gate` + `answers` + `tol`
  （见 `data/line_levels.json` → `line_2_2.levels[2]`、`line_5_1.levels[2]`：`type:"interact"` +
  `gate:true` + `answers:{k:2}` + `tol:{k:0.06}`，配合 `readouts` 表达式读数）。
- 该机制目前**只有 4 轮在用**（全在 `line_levels.json`，且都是「迁移应用」轮）。

**做法**
- 把「迁移应用」轮优先改成 `interact`（调参数/拖动到满足条件）或**数值填空**（复用 `LabPlane._num` 表达式求值与 `tol` 容差）；
- 题目层面引入「选出所有正确项」（多选）用于概念辨析；
- 每关至少 1 轮非四选一。

**验收**
- 四选一占比降到 ≤ 70%；`check_questions.gd` 输出各题型分布；
- 至少 50 轮为 `interact`/填空。

**进度（🟡 进行中）**
- ✅ 能力已落地：`StageBase` 新增 `type:"input"` 数值/公式填空题
  （`_build_input`/`_submit_input`/`_parse_math`/`_norm_math`，复用 `SolidChallenge` 的数学解析），
  已接入 `LabStage`/`SequenceStage`/`Lab3DStage`；多选（`ans` 为数组）沿用旧机制。
- ✅ `check_questions.gd` 看板新增「题型：单选/多选/interact/填空」与「非四选一占比」。
- ✅ 批量改写：26 章全部扫描完毕。在「纯数值答案」的迁移/建构轮删 `opts` 改 `type:"input"`
  （`ans`=原正确项值，`tol`=0.01；`|ans|<0.05` 用 0.001）：`probability`/`functions`/`statistics`/
  `corr_data`/`random_var`/`counting`/`set_logic`/`complex`/`trig`/`inequalities`/`thinking`/
  `sequences`/`recurrence`/`function_lab`/`conic`/`conics`/`hyperbola`/`parabola`/`ellipse`/
  `circle`/`line`/`space`/`vector`/`vectors`/`solid_basic`（`derivative` 无可改）。
- ✅ 验收②达标：非四选一 **147 轮**（≥「至少 50 轮」）。
- ⚠️ 验收①差距：四选一仍占 **80.8%**（目标 ≤70%，即非四选一 ≥30%）。**纯数值填空已到上限**
  （全库已无「正确项为纯数值」的选择题可安全机械改）。要达标须做**内容重设计**（属 §0.1
  「内容批产」阶段，非机械转换）：① 把「探究/gate 轮」转为纯 `interact`（拖动满足条件、去掉
  追问选项）；② 用真实错误路径设计「多选」辨析题（见 B5）；③ 迁移轮改开放式数值填空。
- 当前：单选 **813** / 多选 **4** / `interact` **4** / 填空 **209** → 非四选一 **21.1%**（目标 ≥30%；
  2026-10-20 起 B2 扩题新增轮次以填空为主，覆盖复数/圆锥曲线/递推求通项/随机变量/函数与分段/不等式/
  立体几何初步/导数及其应用/数学思想综合 九章，已使占比回升 2.0 个点）。

---

### [ ] B2 · 每关题量 3 → 5~8（P1）

**现状（证据）**
- 26 个关卡文件中 **20 个恰为 3.0 轮/关**，另 3 个 3.1；只有 `functions`(3.8)、`solid_basic`(4.3)、
  `sequences`(5.0) 更厚。
- 定星规则 `StageBase._finish`（第 713 行起）：`ratio = clean/total`，`>=0.8 → 3 星`、`>=0.6 → 2 星`。
  3 题时即「3/3 对 → 3 星、2/3 → 2 星」。
- 掌握度（`_eval_mastery`）与萌宠进化都建立在星级之上 → **一关 3 道四选一就决定「掌握」**。

**做法**
- 每关 5~8 轮，并按「识记 / 理解 / 迁移」分档；
- 星级改为按维度（如：概念轮全对 + 迁移轮至少 1 对）而非单纯比例。

**验收**
- 全量平均 ≥ 5 题/关；`Tests.gd` 与 `check_questions.gd` 输出新基线。

**进展（2026-10-20 起，按章成批）**
- 序号会随 `data/*_levels.json` 的关序变化而变（如 `complex_levels.json` 把 `cplx_period` 排在 `cplx_div` 前，
  故「3-」「4-」即 `cplx_period`/`cplx_div`），落地前先照 `curriculum.json` 核对。
- ✅ 复数章（`complex_levels.json`）：3 组 ×3 轮 → 各补 2 轮，24 → **30 题（5.0 题/关）**（`26332eb`）。
- ✅ 圆锥曲线章（`conics_levels.json`）：6 组 ×3 轮 → 各补 2 轮，18 → **30 题（5.0 题/关）**；
  新增 12 轮为 7 填空 + 5 四选一，4-5 补上了抛物线切线（判别式/导数）。
- ✅ 递推求通项章（`recurrence_levels.json`）：6 组 ×3 轮 → 各补 2 轮，18 → **30 题（5.0 题/关）**；
  新增 12 轮为 6 填空 + 6 四选一，覆盖累加/累乘/构造/取倒数/取对数/Sₙ 六条方法线（4-6 组以纯文本
  `$$…$$` 数学表达，不依赖 `art/inline` 图片）。
- ✅ 随机变量及其分布章（`random_var_levels.json`）：3 组 ×3 轮 → 各补 2 轮，24 → **30 题（5.0 题/关）**；
  新增 6 轮覆盖分布列归一化与方差公式、二项方差与 P(X=k)（含漏乘组合数的错解）、σ 的几何含义与区间概率换算。
- ✅ 函数与分段章（`function_lab_levels.json`）：`piecewise_range` 3 轮 → 补 2 轮，28 → **30 题（5.0 题/关）**；
  新增 1-4（两段值域取并集）、1-5（含参拼接使值域为 R 的临界下界）；该章用 `{f:name}` 占位符映射
  `art/line/formulas/*.png`，新轮改用纯文本数学表达以免发明未注册的公式图名。
- ✅ 不等式章（`inequalities_levels.json`）：`ineq_quad`/`ineq_basic` 各 3 轮 → 各补 2 轮，
  29 → **33 题（5.5 题/关）**；新增 1-4（因式分解写解集）、1-5（二次不等式恒成立需 Δ<0 而非 Δ≤0）、
  2-4（基本不等式的「一正、二定、三相等」前提辨析）、2-5（配凑定值 x+1/(x−1)）。
- ✅ 立体几何初步章（`solid_basic_levels.json`）：`solid_frustum`/`solid_surface`/`solid_diag`/`solid_sphere`/
  `solid_angle`/`solid_dist`（12 组中的第 2/3/5/6/11/12 组）各 3 轮 → 各补 2 轮，52 → **64 题（5.33 题/关）**；
  新增 12 轮为 6 填空 + 6 四选一，覆盖台体/柱锥台退化、展开图圆心角、长方体体对角线、球截面、异面直线与
  线面角范围、点到平面距离与等体积法。
- ✅ 导数及其应用章（`derivative_levels.json`）：`deriv_formula`/`deriv_tangent`/`deriv_mono`/`deriv_param`/
  `deriv_prove`/`deriv_zero`（第 1~6 组）各 3 轮 → 各补 2 轮，28 → **40 题（5.0 题/关）**（第 7/8 组原已 5 轮）；
  新增 12 轮为 4 填空 + 8 四选一，覆盖乘积/复合求导、过定点的含参切线、三次函数单调区间与极值、
  恒成立与存在性辨析、作差构造函数与切线放缩、零点存在定理与方程根的个数。
- ✅ 数学思想综合章（`thinking_levels.json`）：`think_func_eq`/`think_geo`/`think_classify`/`think_convert`
  各 3 轮 → 各补 2 轮，22 → **34 题（5.67 题/关）**（第 5/6 组原已 5 轮）；
  新增 8 轮为 4 填空 + 4 四选一，覆盖交点横坐标与因式分解、分离参数下界、距离之和最小值与绝对值几何翻译、
  含参一次不等式分类、换元反解指数方程、化归为「对勾」结构。注意本章 JSON 内 LaTeX 命令须双反斜杠
  （`\\ge`/`\\cdot`/`\\sqrt`），单反斜杠会触发 JSON 解析失败。
- ⏳ 待办最薄章节（按 `check_questions` 看板升序）：集合与逻辑 8/30 等。

---

### [ ] B3 · 「探究 → 建构 → 迁移」名不副实（P0）

**现状（证据）**
- 230 个探究轮里 **221 个（96%）题面是陈述句（无问号）**：学生被告知结论，再被要求选回该结论。
  例（`probability_levels.json`）：
  - `prob_cond.levels[0]` 题面已是「已知掷出的是奇数点（1、3、5），问此时是 3 的概率。」，
    追问又原样问「已知点数为奇数，则该点数为 3 的概率是？」→ **题面即答案**。
  - `prob_stats.levels[0]` 陈述「呈正相关」，追问「说明两变量呈？」→ 同上。
  - `prob_props.levels[0]` 陈述「概率落在 0 与 1 之间」，追问「P(A) 满足？」→ 同上。
- 「建构」轮大量是**背公式**：`prob_cond`「条件概率公式 P(A|B)=?」、`prob_indep`「相互独立当且仅当？」、
  `prob_stats`「独立性检验用？」、`count_binomial`「通项 T_{k+1}=?」、`deriv_formula`「下列正确的是？」。
- 「迁移」轮多为**一步代入或仍为定义**：`prob_binom.levels[2]` 二项分布轮问「正态分布关于哪条直线对称」；
  `prob_dist.levels[2]` 问线性变换期望。

**做法**
- 探究轮题面改为**任务句**（「拖动 r，先猜…，再验证」），结论**不写进题面**；
- 追问必须**依赖学生拖出的读数/图形**（正确示范：`circle_levels.json` 滑块参数与追问方程完全一致）；
- 「建构」轮改为辨析/选择理由（给 3 个解题过程选正确的，或指出错在哪一步）；
- 「迁移」轮必须跨情境（新条件/新问法），禁止换考点充数。

**验收**
- 探究轮题面「无问号占比」由 96% 降到 < 20%；
- 抽检 20 关：追问中的数值能在同一轮的 `scene` 滑块/读数里找到对应。

**进度（🟡 进行中）**
- ✅ `check_questions.gd` 新增口径「探究轮题面陈述句（无「？」）占比」，可自动复现。
- ✅ 批量改写：26 章全部完成——所有探究轮题面均由陈述句改为任务/问句（结论不再写进题面）。
- ✅ 验收①达标：探究轮陈述句 **0/256（0.0%）**（目标 <20%；原始人工口径 221/230）。
- ⏳ 验收②（抽检 20 关：追问数值能在同轮 `scene` 滑块/读数中找到对应）未逐关核验，
  与 B4「实验与追问闭环」同源，留待 B4 一并做。
- ⏳ 「建构」轮改辨析、「迁移」轮改跨情境（B3 做法第 3/4 条）尚未系统开展。

---

### [ ] B4 · 实验与追问不闭环（P1）

**现状（证据）**
- 反例 `sequences_levels.json` `seq_ap.levels[0]`：让「拖动滑块改变首项 a₁ 与公差 d，观察散点 aₙ」，
  追问却是「a₁=1，d=2 时，a₅ 是多少？」——拖滑块对答题毫无帮助。
- 正例 `circle_levels.json` `circle_1_1`：滑块 `a=2,b=-1,r=3`，追问正是「(x−2)²+(y+1)²=9 的圆心与半径」。

**做法**
- 每个探究轮建立「实验 → 追问」闭环：追问的条件 = 实验给出的初始/最终状态；
- 或让 `gate` 承接实验（调到满足条件）后再追问结论。

**验收**
- 抽检全部探究轮，闭环率 ≥ 90%（可用 A5 的校验器做静态近似：追问中的数值是否出现在 `scene.sliders` 的值域/取值上）。

---

### [x] B5 · 干扰项改为诊断性干扰项（P1）✅ 2026-10-20 完成（第十、十一轮）

**现状（证据）**
- 大量干扰项是**范畴错误**，不列式即可排除：
  `prob_stats`「画折线图 / 求概率密度」、`prob_hypergeo`「连续型随机变量 / 几何概型」、
  `prob_binom`「一次试验的取值」、`counting`「错位相减 / 裂项相消 / 数学归纳」、
  `derivative`「都趋于无穷」、`prob_freq`「无数个」。
- 缺少「学生真会犯的那个错」型干扰项：例如问 `P(A|B)` 时经典混淆 `P(B|A)` 在选项中**从未出现**。

**做法**
- 每个知识点维护「常见错误 → 干扰项」对照表，干扰项必须来自错误路径（符号错、条件错、漏解、混淆定义）；
- 禁止新增范畴错误型干扰项；给「以上都对/都不对」限用（它也会触发 `_shuffle_allowed` 关闭乱序，见 B8）。

**验收**
- 抽检 30 题：每题至少 2 个干扰项可对应一条真实错误路径；
- `check_questions.gd` 增加「干扰项关键词黑名单」检查（画折线图 / 求概率密度 / 无法判断 …）。

**进度（✅ 2026-10-20 完成，第十、十一轮）**
- ✅ 验收②落地：`check_questions.gd` 新增 `BAD_DISTRACTOR` 黑名单，**只查错误选项**，
  命中即记 `干扰项黑名单「<词>」`，看板新增「干扰项黑名单命中」行。词表现为 7 词：
  画折线图 / 求概率密度 / 无法判断 / **无法确定** / **无法比较** / 不能确定 / 说不清
  （后两词为第十轮扩入——扩词后立刻命中 22 处，证明是全库性句式）。
- ✅ 批次一 14 轮（9 文件，`0ddf55e`）：「无法判断」回避项换成错误路径型
  （忘开方、代点符号错、残差符号记反、$$f′>0$$ 误当 $$f>0$$、「至少一个」当「恰有一个」、
  忽略量词数集限定、漏「不在同一直线上」、方差反向理解…）；`prob_stats` 三个范畴错误项
  整体换成「用相关系数 / 频率目测不检验 / 用回归拟合」三种可辨识的错配。
- ✅ 批次二 28 轮（14 文件，`32f064e`）：「无法确定/无法比较」22 处 + B5 点名的学科专属范畴错误
  6 处（`counting` 赋值法改为四组具体代入辨析、`counting` 6-1/6-4、`derivative` 5-3「都趋于无穷」→
  无穷远处取等、`prob_binom` 4-2 → 平均值/超几何/参数 $$p$$ 三条真实混淆、`prob_hypergeo` 7-1 →
  单次 0-1 结果/总体比例 $$M/N$$）；顺手修正 `conic_line_circle` 题干问「几个交点」但选项是位置关系词的错位。
  两批累计 **42 轮、黑名单命中清零**。
- ✅ 审计澄清：B5 现状列的 `prob_freq`「无数个」实际在遗留题库 `questions.json`，对应「区间内实数
  无穷多」的真实误解，判定为**合格错误路径，不改**；该文件去留待 A2/A3/A12 拍板。
- ✅ **验收①已达成**（`6fb59c7`）：新增可复现抽样工具 `tools/sample_distractors.gd`
  （确定性等间隔抽样：770 道四选一轮中取 30 道，explore 轮取 `ask` 题干；`-- n` 可调样本量）。
  逐题判定结果：**26 题达标 / 4 题整改后达标**，整改明细：
  - `fm_inverse` 反函数：原选项 $$y=\dfrac{x}{3}+2$$ 与正确选项 $$y=\dfrac{x+6}{3}$$ **数学上完全等价
    （两正确选项的真 bug）**→ 换成 $$y=\dfrac{x}{3}-2$$（系数取倒数、常数照抄同号）；
  - `think_whole` 整体加减：ask 问 $$3x+3y$$ 而选项里**没有正确路径的邻近错值**（9/6/12/15 全是凭空数）
    → 换成 3（只算出 $$x+y$$，忘系数 3）/ 18（两式相加两次）/ 4.5（多除一次 2）；
  - `stat_percentile` 百分位数第一步：原三个干扰项（求平均数/求方差/画直方图）是**范畴错误**，
    → 换成「跳过排序直接取原顺序第 i 个数」「先求平均数再乘 p%」「先分组求频率再按比例找位置」；
  - `count_misc` 错位排列 D₄：原 6/8/12 三个裸数字无错误路径 → 标注为 8（递推记成 $$D_{n}=n\cdot D_{n-1}$$）/
    6（错记成 $$(n-1)!$$）/ 12（只让前两封互换 $$C_{4}^{2}\times2$$）。
- ⏳ 持续约束：新增干扰项一律按 B5 规范（错误路径型），禁新增范畴错误型（黑名单会拦截通用回避句式）；
  数值型选项尽量配「错因」说明（与 B6 同向）。

---

### [ ] B6 · 选项过短、退化为结果核对（P1）

**现状（证据）**
- 选项平均字数：`counting` 2、`conics` 3、`sequences` 4、`complex` 5、`hyperbola` 5、`derivative` 5 …（最大 `recurrence` 23）。
- 即大量题的选项就是 `0 / 1 / 2 / 3` 这类数字 → 只能测「算得对不对」，测不出**概念性误解**；
  `wrong_log` 记的是选项下标，也诊断不出错因。

**做法**
- 关键概念轮用「理由选项」（给 3 种解释选正确的那种）而非数值选项；
- 为数值题配「错因标签」（如 `err_reason:"符号错"`），供错题本聚合诊断。

**验收**
- 概念轮中「理由选项」型占比 ≥ 30%；错题本可按错因聚合。

---

### [ ] B7 · 图片选项回归 LaTeX 文本（P1）

**现状（证据）**
- **180 处图片选项**：关卡文件 114 处（`vector` 44 / `recurrence` 42 / `ellipse` 22 / `conic` 6），
  `questions.json` 66 处（其中 15 道题**四个选项全是图片**）。
- 同一题的四张图文件名形如 `qn_m12_c1ac7ac3.png` / `qn_m12_95c9f3ef.png` / `qn_m12_f28da539.png` /
  `qn_m12_bda148b9.png` —— 即四个**近乎同形**的区间记法（`[-1,2)` / `(-1,2]` / `[-1,2]` / `(-1,2)`），
  题目退化为「比眼力辨形」。
- 图片选项不可搜索、不可朗读（TTS 失效）、无法 diff。
- 环境已具备运行时 LaTeX 渲染（`InlineMath` + MicroTeX），无技术障碍。

**做法**
- 全部改为内联公式/LaTeX 文本选项；图片仅保留「图形/图像」类题目（如散点图、三视图）；
- 迁移后删除 `art/**/formulas/qn_*.png` 与对应映射。

**验收**
- `check_questions.gd` 统计「图片选项数」归零（图形题除外）；
- TTS 朗读选项可用（手动抽检）。

---

### [ ] B8 · 正确项恒写在第 1 位（P2）

**现状（证据）**
- `ans == 0` 占 **699/754（92.7%）**；`ans==1` 36、`ans==2` 12、`ans==3` 5。
- **运行时确实会打乱选项**（`StageBase._opt_order_for` → `_shuffle_allowed`，默认开；
  754 题里只有 1 题因选项含「以上/都对」等标记而关闭乱序）——**所以不直接漏答案**。
- 但它说明：**没有任何人审阅过选项顺序与干扰项合理性**（与 B5 同源）。

**做法**
- 出题规范：写题时先写 3 个干扰项、最后填正确项；或在提交前随机化一次存储顺序；
- 禁止在选项中使用 `以上都对/都不正确`（会关闭乱序），改用明确表述。

**验收**
- `ans==0` 占比降到 ≤ 35%（随机基线 25% ± 容差）；
- `check_questions.gd` 增加该分布看板。

---

### [x] B9 · 轮次标签编号错乱（P0，纯编校，可脚本修）

**现状（证据）**——「轮次标签编号 == 关卡序号」的校验结果：

| 文件 | 错位数/总数 | 具体 |
|---|---|---|
| `circle_levels.json` | 54/57 | 19 关里 18 关的轮次全叫 `1-1/1-2/1-3` |
| `line_levels.json` | 53/56 | 同病；另有 **1 处轮次名完全重复** |
| `ellipse_levels.json` | 45/48 | 同病 |
| `recurrence_levels.json` | 18/18 | 全用「实验一/实验二」，不编号 |
| `functions_levels.json` | 49/49 | 全无编号前缀（「实验探究 · 描点连线」） |
| `counting_levels.json` | 9/12 | 4 关里 3 关（`count_comb`/`count_indirect`/`count_binomial`）全标 `1-x` |
| `probability_levels.json` | 11/33 | **从第 2 关起整体错位一位**（`prob_cond` 标 `1-2`、`prob_dist` 标 `2-1`） |
| `random_var_levels.json` | 5/9 | 第 2、3 关仍标 `1-x` |
| `derivative_levels.json` | 2/18 | `deriv_prove` 的轮次是 `5-1` 接 **`4-2` / `4-3`**（复制残留） |
| `conic_levels.json` | 9/9 | 用 `C1/C2/C3` 描述名 |
| `function_lab_levels.json` | 3/3 | 全无编号 |

- 另有 **3 种命名风格混用**：`N-M 阶段名`、`阶段名`（无编号）、`实验一/实验二`。轮次名会写入错题记录
  （`StageBase._level_ok` → `GameData.record_answer(..., name, ...)`），错乱会在错题本里暴露。

**做法**
- 统一规范（建议：`<关卡序号>-<轮次> <阶段名>`，如 `3-2 建构知识 · 通项公式`）；
- 一次性脚本批量修正上述文件；`conic`/`recurrence` 等无编号文件补齐编号；
- 由 A5 的校验器第 4 条长期兜底。

**验收**
- `check_questions.gd` 的「编号错位」归 0；
- 抽查错题本显示的轮次名可读且与关卡序号一致。

---

### [ ] B10 · 题干套路化与重复（P2）

**现状（证据）**
- 745 个不同题干 / 754 题（重复度很低），但**套路化**严重：
  「下列说法正确的是？」重复 4 次；「下列最符合二项分布的是？」「判断…最本质的依据是？」等模板句遍布。
- `questions.json` 里出现「下列说法/下列」型 47 题（占 754 的 6%）。

**做法**
- 对「下列说法正确的是」型：改为带具体错因的辨析题（见 B5）；
- 建立题干模板库并轮换，避免同章内句式雷同。

**验收**
- 同文件内题干句式重复率下降；抽检 20 题无「万能题干」。

---

### [ ] B11 · 模块间质量方差过大（P1）

**现状（证据）**
- 同一「三阶段」品牌下，深度差 3 倍：
  - 好：`sequences_levels.json` 5.0 题/关，含真正辨析题（「下列数列中不一定是等差数列的是？」）、
    一题多轮递进（`seq_ap` 2-1…2-8）；
  - 差：`complex`(9 题)、`random_var`(9 题)、`corr_data`(9 题) 基本是「每个知识点凑 3 题」，
    且大量为定义复述。
- 同为 3 题/关的 `counting`/`derivative`/`probability`/`statistics`/`thinking` 也以模板填充为主。

**做法**
- 以 `sequences_levels.json` 为**质量基准模板**（辨析题 + 递进轮次），逐模块补齐；
- 优先补 `complex` / `random_var` / `corr_data` / `statistics` / `thinking`（题量最少、最薄）。

**验收**
- 题量最少的三模块 ≥ 5 题/关且含 ≥ 2 个辨析轮；`check_questions.gd` 输出各文件题量看板。

---

### [ ] B12 · 提示语泄露答案（P2）

**现状（证据）**
- 例：`data/line_levels.json` → `line_5_1.levels[2]`（「动手调夹角」）的 `hint` 直接写
  「当 k = 0 时，l 与 y = x 的夹角为 45°」——学生还没算，答案已在提示里。
- `prob_indep.levels[0]` 的 `hint`「独立指一个发生与否不影响另一个」+ 选项含判定式，几乎等价于给答案。

**做法**
- 提示只给**方法/方向**（「用夹角公式 tanθ=|(k₂−k₁)/(1+k₁k₂)|」），不给结论；
- 给 `hint` 加一道规则：不得包含与正确选项字面高度重合的内容；由 A5 校验器近似检查。

**验收**
- 抽检 30 题：`hint` 与正确选项的重合度低于阈值。

---

### [ ] B13 · 朗读/无障碍路径不完整，且两条路径行为不一致（P1）

**现状（证据）**
- 关卡数据里**没有任何 `speak` 字段**（`data/*.json` 全量搜索 `"speak"` = **0 处**），
  但 `StageBase.gd` 的注释宣称「`_q_speak` 为题干的可朗读文案（公式转成**口播**而非图片标记）」——
  **承诺未实现**。
- 实际两条路径行为不一致：
  - `StageBase.gd:199`（普通轮）：`_q_speak = UI.strip_formulas(raw)` → **把公式整段剥掉**，
    朗读出来就是「圆的标准方程 的圆心和半径分别是？」——方程没了，题目不可答；
  - `StageBase.gd:211-212`（探究追问轮）：`_q_speak = ask` 后直接 `UI.tts_say()`，
    **没有** strip，公式按原始字符（Unicode 下标等）读出，听感是乱码式念法。
- 入口：`StageBase.gd:1082` 的朗读按钮 + `Settings` 的语音开关；`scripts/ui/Tts.gd` / `TtsOnline.gd` 提供后端。
- 影响：视障/低视力学生、以及「听题」这一场景（通勤/睡前）基本不可用——而这两个场景正是移动端教育 App 的主要价值之一。

**做法**
- 给题目数据补**可选口播字段**（推荐 `speak`，缺省回退现有行为），或实现
  **「LaTeX/公式 → 口语」转换表**（如 `x²` → 「x 的平方」、`aₙ` → 「a 下标 n」、`≤` → 「小于等于」、
  `(−∞,1)` → 「负无穷到 1 开区间」），在 `InlineMath`/`Tts` 侧统一出口；
- **两条路径统一**走同一个「显示文本 → 口播文本」函数，禁止一处 strip、一处不 strip；
- 用 A5 校验器统计「口播覆盖率」（有 `speak` 或可自动口播的公式占比）。

**验收**
- 抽检 20 关：朗读内容包含题目所需的数学信息（不再丢公式），且探究轮/普通轮行为一致；
- 校验器输出「口播覆盖率」看板，可持续提升。

---

## 3. C 类 · 防刷与经济（跨 A/B）

### [x] C1 · 重复通关无限刷经验/金币（P0）

**现状（证据）**
- `scripts/screens/StageBase.gd::_finish`（第 713 行起）每次结算都无条件调用：
  - 第 741 行 `GameData.grant_stars(lid, st)`；
  - 第 772 行 `GameData.add_coins(reward)`。
- `scripts/autoload/GameData.gd:695` `grant_stars`：`stars[lid] = max(...)`（星数只升不降），
  但第 697 行 `player_exp += 10 * n` **每次调用都加**，**不看星数是否提升**。
- `reward` 每次通关都发（`30 + clean*15 + st*20 + …`），只有 **BOSS 关**有首通奖励
  （`_boss_first_clear_coins()`，第 755 行 / 第 817 行）。
- 结论：反复刷同一关（尤其已 3 星的简单关）可无限刷经验 + 金币 → 商店/头像解锁/等级/称号全部可绕过。

**做法**
- 经验只在**星数提升**时发放（`if n > prev: player_exp += 10 * (n - prev)`）；
- 金币改为「首次达成该星级」给全额，重复通关给递减（如 30%）或封顶每日；
- 引入「本关当日重复次数」计数（存档兼容：旧档缺字段按 0）。

**验收**
- `Tests.gd` 新增经济用例：同一关连续通关 N 次，经验不再增长、金币收敛；
- 玩家等级不再能靠刷一关得到。

---

### [x] C2 · 星级只升不降 + 免费重试 + 四选一 → 全进度可刷（P0）

**现状（证据）**
- `grant_stars` 取 `max`（只升不降）；`_wrong()`（第 562 行起）只是 `_wrongs += 1` 并公布答案，
  学生可继续/重来，**答错无任何代价**；
- 3 题定星（`ratio>=0.8` → 3 星）叠加四选一（B1）→ 盲猜 3/3 的概率 1/3⁴? 实际 25%³ ≈ 1.56%，
  但**免费无限重试**下，期望几十次即可白嫖 3 星；`_eval_mastery` / 萌宠进化 / 勋章都建立在星级之上。

**做法（与 C1 同批）**
- 答错扣连击、扣时间预算（限时关已有），或本关星级上限降级；
- 同一关当日/单会话的尝试次数计入 `level_records` 并可影响「首次达成」奖励判定；
- 配合 B1：把关键轮改成 `gate`/填空，盲猜成本自然消失。

**验收**
- 脚本模拟「随机盲猜 + 无限重试」不再能在合理次数内刷满一关三星的经济收益；
- 三星奖励与掌握度不再能被猜测驱动。

---

## 4. D 类 · 动效与动态交互

> 结论先说：**"反馈层"动效做得不错（统一受开关控制），"演示层"很好但只覆盖 1 个文件，"理解层"基本空白。**
> 本节所有数字来自 `scripts` 与 `data/*.json` 全量扫描。

### [ ] D1 · 2D 探究器没有过渡动画（拖动 = 瞬时跳变）（P1）

**现状（证据）**
- 2D 几何的渲染器 `scripts/modules/lab/LabPlane.gd`：滑块变化后直接 `queue_redraw()` 立即重绘，
  **没有补间、没有轨迹、没有残影**（全文件无 `create_tween`）。
- 对比 3D：`scripts/modules/lab3d/Lab3DView.gd` 有完整的补间播放器（`_tick_anim`），
  其中 `vars` 步骤可把参数从一个值**动画化**到另一个值；**2D 侧没有任何对应能力**。
- 数据层：`sliders` 138 处、`readouts` 86 处、`highlight` 72 处，但这些 `highlight` 都是
  **静态标注**（标出某条棱/某个点），没有"上一个值 → 当前值"的**差量**表达。
- 覆盖范围：138 处滑块分布在 2D 几何全部章节（圆/椭圆/直线/向量/三角/函数/数列…）。

**后果**：学生把 r 从 1 拖到 3，看到的是**两张静态图**，而不是"半径在长大"这个过程。
这与 B3（探究轮名不副实）、B4（实验与追问不闭环）是**同一个病根的不同表现**：
交互有了，但**变化没有被表达出来**。

**做法**
- 在 `LabPlane` 增加一层**参数补间**：滑块值变化时对图形做 0.12~0.2s 的 tween（可关，见 D4 的开关语义）；
- 增加**差量提示（ghost）**：拖动时保留上一状态的浅色轮廓，并让受影响的关键读数高亮；
- 增加**轨迹/残影**：对切点、交点、极值点这类"位置在变"的元素，保留最近 N 帧的半透明副本。

**验收**
- 至少 3 个 2D 知识点具备「补间 + 差量高亮 + 残影」；
- 用 A11 的截图回归抓帧间差异，能证明"中间态存在"（而不是只有两个端点态）。

---

### [ ] D2 · 演示动画只覆盖 1/26 个关卡文件（P1）

**现状（证据，已实测）**
- 数据层 `anim` 字段**只出现在 `solid_basic_levels.json`（27 处）**，
  其余 **25 个 `*_levels.json` 全为 0** → 228 个关卡里约 **12 关（5%）** 有「▶ 演示」。
- 能力本身是完整的（`Lab3DView.play_anim` 支持 7 种步骤，实测数据里的用量）：
  `highlight` 50 / `view` 38 / `reveal` 25 / `a` 22（按阶段嵌套）/ `vars` 21 / `rotate` 7 / `pulse` 4。
- 空白区包括：`space_levels.json`（**19 关 3D，与已覆盖的 solid_basic 同构，复用它零成本**）、
  以及全部 2D 章节（2D 连 `anim` 能力都没有，见 D1）。

**做法**
- 第一优先：给 `space_levels.json` 补 `anim`（同基类、同 `SolidBuilder`，基本是写数据）；
- 第二优先：让 `LabStage`/`LabPlane` 支持 `anim`（与 D1 的补间层共用），再逐章补齐；
- 目标：3D 关卡全覆盖；2D 每个知识点至少 1 个可回放演示。

**验收**
- `anim` 覆盖文件数从 **1/26** 提升到 **≥ 13/26**；
- `check_questions.gd`（A5）输出「anim 覆盖率」看板，可持续跟踪。

---

### [ ] D3 · 动效全在「结果反馈」，缺「理解型动效」（P1）

**现状（证据）**
- `scripts/ui/Vfx.gd`（376 行，9 个原语）里，**8 个是答题结果的情绪反馈**：
  `burst`(答对爆发) / `star_burst`(庆祝) / `celebrate` / `ring` / `float_text`(飘字) /
  `screen_flash`(闪光) / `wobble`(答错摇头) / `shake`(抖动) / `coin_fly`(金币飞行)；
  唯一非反馈的是工具函数 `center_of()`。
- 其余动效同理：`Confetti`(彩带)、`ComboBar`(连击条填充)、`BossHud`(血条)、
  `ProgressLine`(进度补间)、`MedalBadge`、`BrandMark` —— 全是**元游戏/情绪**层。
- **没有任何一类动效用于表达数学关系**：没有"系数变了 → 图像哪里变了"的联动，
  没有参数的连续轨迹，没有临界点出现的脉冲标记，没有几何量之间的联动连线。

**后果**：动效只强化「对/错的情绪」，不强化「数学因果的理解」。
而学习产品里最值得用动效的地方恰恰是后者——这也是 D1/D2 想补的东西的**统一抽象**。

**做法**
- 在 `Vfx` 之外新增一组**理解型原语**，并在真实关卡试点：
  1. `delta_highlight` —— 拖动时高亮"变了的量"（直接消费 86 处 `readouts`）；
  2. `trace` —— 参数连续变化时留下轨迹（2D 曲线 + 3D `vars` 动画都适用）；
  3. `pulse_at` —— 临界/特殊点（极值、交点、切点、零点）出现时脉冲标记；
  4. `link_line` —— 两组几何量之间画联动虚线（如焦点↔长轴端点、圆心↔切点）。
- 明确区分「装饰动效」与「表意动效」（后者关不掉，见 D4）。

**验收**
- 至少 2 个章节用上理解型动效，且抽查学生能"看懂因果"；
- `Vfx`/新原语清单与用途登记进 `README.md` 或设计文档。

---

### [ ] D4 · 动效令牌缺失 + 演示不可控 + 无障碍粒度不足（P2）

**现状（证据）**
- **无动效设计令牌**：44 处 `tween_property(...)` **直接写裸时长**
  （`0.07 / 0.08 / 0.14 / 0.16 / 0.18 / 0.25 / 0.28 / 0.4 / 1.7 …`），缓动写法散落
  （`TRANS_CUBIC+EASE_OUT` 6 处、`TRANS_BACK` 4 处…，另有自写 `ease_pop/smooth_k`）。
  `scripts/ui/UI.gd` 已是设计系统（着色 token/字号 `fs()`/按钮/卡片），但**没有动效章节**。
  → 观感不统一，改一次要翻十几处；A11 的 UI 回归也缺可断言的动效基准。
- **演示不可控**：`Lab3DView.play_anim()` 只能整体播一次（`_anim_playing`），
  `_tick_anim` 越界后把 `_auto_pause` 置 1.5 恢复自动旋转 —— 用户**无法暂停 / 重播 / 逐步看**，
  错过关键一帧只能切轮次重进。
- **无障碍粒度不足**：全项目 40+ 处检查 `UI.animations`（单一总开关，对应设置里「界面动效」）。
  关闭后**连"变化提示"一起关**；也没有"减少位移/闪烁"（前庭敏感用户）这一档。
  当前尚可（动效都是装饰性的），但一旦做了 D1/D3 的**表意动效**，单一开关就会出问题。

**做法**
- 在 `UI.gd` 增补动效令牌：`DUR_FAST / DUR_NORMAL / DUR_SLOW`、`EASE_STD / EASE_EMPHASIS`，
  把 44 处裸时长逐步收敛（新代码禁止裸时长，由 A5/A11 静态检查兜底）；
- `play_anim` 增补 `pause() / resume() / restart() / step()`，HUD 给「▶ / ⏸ / ↻」控件；
- 开关语义拆两层：`animations`（装饰，可关）与 `essential_anim`（表意，始终开）；
  或提供「减弱动效」档（保留淡入淡出，去掉位移/闪烁/旋转）。

**验收**
- `UI.DUR_*` 成为唯一时长来源，全仓裸时长归零（或仅剩白名单）；
- 3D 演示可暂停/重播；「减弱动效」档下关键信息不丢失（用 A11 回归验证）。

---

## 5. E 类 · 知识点覆盖（知识体系完整性）

> **结论**：27 个章节里 **8 章明显偏薄**（≤4 关），另有 **15 个整块教材必学知识点缺失**
> （最典型：数学归纳法、不等式性质体系、排列组合方法体系、三角恒等变换体系、解三角形应用、集合间关系）。
> 本章是"内容补全"的施工图，与 B 类（题目质量）互补：**B 管"题好不好"，E 管"点全不全"。**
>
> 覆盖较好的章节（无需大改）：`line_eq`(18关/52题)、`circle_eq`(19/57)、`space`(19/58)、
> `vector`(19/58)、`ellipse`(16/48)、`functions`(13/49)、`solid_basic`(12/52)、
> `hyperbola`(11/33)、`parabola`(11/33)、`probability`(11/33)、`sequences`(10/50)。

### [x] E1 · 建立「知识点覆盖矩阵」+ 校验器（P0，前置）

**现状（证据）**
- 知识体系由 `data/curriculum.json` 的 **27 章 / 228 关**描述，但**没有任何一份
  「教材知识点 ↔ 关卡」的对照表**。
- 因此"缺什么"只能靠人工回忆——本次审计就是这样逐章比对才发现的；
  一旦有人新增关卡或改章节，缺口会重新变得不可见。
- `data/textbooks.json` 只声明 **6 个教材版本**（苏教/人教A/北师大/人教B/湘教/沪教）的
  分册、章节排序与章号，**不含知识点粒度**。

**做法**
- 新建 `docs/知识点覆盖矩阵.md`：**行 = 教材知识点（拆到教材小节级）**，列 = 关卡 id；
  单元格标记「已覆盖 / 未覆盖 / 不适用（选学·旧课标）」。
- 三层映射：`教材小节 → 知识点 → 关卡 id`；标注**选学（带 `*`）**与**旧课标**内容，
  避免误判为缺口（见 E3 末尾说明）。
- 由 `tools/check_questions.gd`（A5）或独立脚本校验矩阵与 `curriculum.json` 同步：
  新增关卡必须挂知识点，新增知识点必须标"未覆盖+原因"。

**验收**
- 矩阵覆盖 27 章的全部教材小节（按苏教 + 人教A 两套为主，其余四版做差异标注）；
- 校验器能输出「未覆盖知识点清单」，可在 CI 中跟踪数量下降。

**已实施（记录）**
- 新增数据源 `data/knowledge_map.json`：**27 章 / 228 个知识点**（= 关卡，每关必挂一个知识点），
  每章含 `sujiao` / `renjiao_a`（章节级对齐，与人 `data/textbooks.json` 的章号一致）与 `gaps`（未覆盖清单，
  `optional=true` 表示选学/旧课标）。
- 新增 `tools/check_knowledge.gd`：校验矩阵 ↔ `curriculum.json` 同步（章节集合/顺序一致、**新增关卡必须挂知识点**、
  引用的关卡 id 必须存在），输出未覆盖清单，并**由数据生成** `docs/知识点覆盖矩阵.md`（文档与数据不分叉）。
- 缺口对照基线 `tools/knowledge_gaps_baseline.txt`（现 **6** 条硬缺口）：**新增**硬缺口 → 退出码 1；低于基线 → 提示下调。
- 已纳入 CI（`.github/workflows/check.yml` 增 `check_knowledge` 步骤）。
- 实测：`KNOWLEDGE: 27 chapters / 228 points / 228 levels mapped / hard-gaps=6 (baseline 6) / optional=8`。
  **硬缺口 6**：集合基数（card）、含参一元二次不等式、基本不等式实际应用、函数图象变换、两角和与差、二倍角公式；
  **选学/旧课标 8**：三垂线定理、圆锥曲线统一定义/极坐标、积化和差、数学归纳法、数列放缩、定积分、复数三角表示。
- 附带发现（进 KN-WARN）：关卡 id `solid_angle` 在 `solid` 与 `solid_basic` 两章**重名**（关联 A17）。

**残留**
- ⚠️ 其余四版（北师大/人教B/湘教/沪教）仅按 `data/textbooks.json` 的章号/顺序对齐，**未拆到小节级**；
- ⚠️ 缺口清单与教材小节归属为 **AI 初稿**，数学口径（尤其「两角和与差/二倍角是否真缺」）**需人工复核**；
- ⚠️ `solid_angle` 跨章重名需与 A17 一并处置（改名或合并）。

---

### [x] E2 · 补齐薄弱章节的题量（P0）

**现状（证据，实测关卡数 / 题数）**

| 章节 | 关 | 题 | 说明 |
|---|---|---|---|
| `function_methods` | **6** | 28 | 方法章（2026-10 补齐，`fm_transform` 关掉硬缺口「函数图象变换」） |
| `conic`(method) | **6** | 24 | 三定义专题（2026-10 补齐 C4–C6，`lab_ref` + LabStage） |
| `inequalities` | **6** | 26 | 一元二次不等式（2026-10 补齐） |
| `counting` | **6** | 22 | 计数原理（2026-10 补齐） |
| `statistics` | **6** | 22 | 统计（2026-10 补齐） |
| `random_var` | **6** | 24 | 随机变量及其分布（2026-10 补齐） |
| `corr_data` | **6** | 24 | 成对数据的统计分析（2026-10 补齐） |
| `complex` | **6** | 24 | 复数（2026-10 补齐） |
| `vectors` | **6** | 22 | 平面向量初步（2026-10 补齐） |
| `thinking` | **6** | 22 | 数学思想综合（2026-10 补齐） |
| `set_logic` | **6** | 20 | 集合与逻辑（2026-10 补齐，`set_card` 关掉硬缺口「集合基数」） |

（对照：`line_eq` 18/52、`circle_eq` 19/57、`space` 19/58、`vector` 19/58）

**做法**
- 低于 6 关的章节**补到 ≥6 关**，并按 B2 的要求每关 5~8 轮；
- 优先级：`inequalities`（工具性，先补）→ `counting`（高考重点）→ `statistics`/`random_var`/`corr_data`（统计板块整体偏薄）→ `complex`/`vectors`/`thinking`。

**验收**
- 27 章全部 ≥6 关；`check_questions.gd` 输出「每章关卡数/题数」看板，可跟踪。

**已实施（前置：验收工具）**
- `tools/check_questions.gd` 增加「章节题量」看板：由 `curriculum.json` 反查「关卡 → 数据 key」
  （按实际载入器解析：LabStage/Lab3DStage→`lab_ref`、SequenceStage→`sequence`、ConicStage→`conic`、
  SolidChallenge→`method`，其中方法章题目在 `solid_methods.json`），输出 27 章「关/题」并 WARN 薄弱章节(<18 题)。

**已实施（内容：2026-10）**
- 目标：把 <6 关的章节补到 ≥6 关、每关 5 轮（B2/B3 口径：探究→建构→迁移→巩固→综合；
  探究轮用**任务式提问**，不写「题面即答案」）。

| 章节 | 补前 → 补后 | 新增关卡（各 5 轮） | 备注 |
|---|---|---|---|
| `inequalities` | 2 关/6 题 → **6 关/26 题** | `ineq_props` 基本性质与作差法、`ineq_param` 含参一元二次不等式、`ineq_apply` 基本不等式应用、`ineq_abs_frac` 绝对值/分式 | 覆盖 E1 两条硬缺口 + E3#2 |
| `counting` | 4 关/12 题 → **6 关/22 题** | `count_group` 分组与分配、`count_binom_props` 二项式系数的性质 | — |
| `statistics` | 4 关/12 题 → **6 关/22 题** | `stat_chart` 统计图表、`stat_center` 集中趋势的估计 | — |
| `random_var` | 3 关/9 题 → **6 关/24 题** | `rv_props` 期望/方差的性质与线性变换、`rv_hyper` 超几何分布、`rv_model` 分布识别与建模 | 超几何是新增分布，未与 `probability` 章重复 |
| `corr_data` | 3 关/9 题 → **6 关/24 题** | `cd_resid` 残差与拟合优度、`cd_rprops` 相关系数的性质、`cd_chi` χ² 的计算与判断 | 知识点名用「卡方」避免 check_inline 未覆盖片段（χ² 裸符号） |
| `complex` | 3 关/9 题 → **6 关/24 题** | `cplx_div` 复数的除法（共轭实数化）、`cplx_eq` 复数相等与实虚部、`cplx_mod` 模的性质与最值 | — |
| `vectors` | 4 关/12 题 → **6 关/22 题** | `vec_basis` 基底与单位向量、`vec_tri` 三角形中的向量（中线/重心） | 避免 Unicode `·` 片段（空间向量 `vector_levels.json` 已有 2 处存量） |
| `thinking` | 4 关/12 题 → **6 关/22 题** | `think_whole` 整体思想、`think_construct` 构造思想 | 原拟「命题否定/特殊值」与 `set_logic` 的 `logic_neg`/`logic_special` 撞题，改选题；初稿 LaTeX 反斜杠多写一层（数据 `\\dfrac`）会触发 MicroTeX 扩展字体缓存崩溃，已规约为单反斜杠 |

- 配套改动（每章）：
  - `data/curriculum.json` + `data/<章>_levels.json`（全部答案位 `ans=0`，运行时打乱）；
  - `data/knowledge_map.json` 挂新知识点；被覆盖的 E1 硬缺口移出 `gaps`
    （不等式基线 `tools/knowledge_gaps_baseline.txt` 6 → **4**）；
  - 轮次标签经 `tools/fix_labels.gd -- --apply` 规范为 `<关卡序号>-<轮次>`；
  - **落 A10**：新内容全部用 `$$…$$` 直写 LaTeX（`MicroTeX` 渲染 0 失败），无新增 `FORMULA_LATEX` 命名、
    无新增 Unicode 数学片段。
- 实测（E2 收官，2026-10-19）：薄弱章节 **11 → 0**（27 章全部 ≥6 关；知识章 9 章 + 方法章 `function_methods` 6/28、`conic` 6/24；
  不等式 6/26、计数/统计 各 6/22、随机变量/成对数据/复数 各 6/24、平面向量/数学思想 各 6/22、集合逻辑 6/20）；
  `QUESTION-CHECK: 26 files / 252 levels / 862 questions / 0 new / 7 known`；
  `SMOKE: 268 ok, 0 fail`；`UI-SMOKE: 375 ok, 0 fail`（取样漂移，见 §9.1 注）；`TESTS: 1245 passed`；
  `KNOWLEDGE: 27 chapters / 258 points / 258 levels mapped / hard-gaps=2`；
  `LATEX-PROBE: conic C4 68 / C5 76 / C6 68 段 · 0 失败`（按组分进程）。

**残留（E2 已收官）**
- ✅ `conic` 3→6 已补齐：C4–C6 走 `lab_ref` + `LabStage` 通用通道（`lab: "conic"`、`lab_ref: C4/C5/C6`，
  仍读 `data/conic_levels.json`），C1–C3 保留 `ConicStage`（DETECT/CHAIN 场景代码硬编码）不动；
  新增 3 组各 5 轮（`ans` 恒 0、全 `$$…$$`），无新增 Unicode 数学片段 / `FORMULA_LATEX` 命名；
- ⚠️ 新增 150 题（135 + `conic` 15，及后续补题）的**数学正确性需人工复核**（尤其 `ineq_param` 含参分类、`ineq_apply` 取等条件、
  `count_group` 平均分组除以 `k!`、`stat_center` 中位数/众数、`rv_hyper` 超几何期望方差、`rv_model` 分布识别、
  `cd_chi` χ² 计算数值、`cd_resid` 残差符号约定、`cplx_mod` 模的最值数值、`vec_tri` 中线长/重心分比、
  `think_construct` 构造反例与分母有理化数值、`set_card` 容斥数值、
  `fm_quad_interval` 动轴端点值、`fm_root_dist` 6-2/6-3/6-5 参数区间端点、
  `conic` 6-2 排除圆（`m≠2`）、6-3 含参区间端点 `5/2`、6-4 双曲线最小距离 `c−a` 排除 `1`）；
- ⚠️ 新内容未预烘焙 `art/line/formulas/*.png` 回退（正式包含扩展，无头 CI 不渲染但不崩）。
- ⚠️ **MicroTeX 扩展字体缓存累积崩溃**（本章发现）：同一进程内渲染 20+ 段不同 LaTeX 后可能 signal 11
  （`fonts.cpp getChar`，block of char 为 0）；数据中 `\\`（双反斜杠）会显著提高触发概率。
  LaTeX 探针需**按组分进程**跑（每进程 ≤1 组）；游戏内单关最多 5 轮 × 若干段，暂未见触发，但长会话需留意。

**收官（E2 完成，2026-10-19）**
- 已补 11 章（合计 +30 关 / +150 题）：`inequalities`、`counting`、`statistics`、`random_var`、`corr_data`、`complex`、`vectors`、`thinking`、`set_logic`、`function_methods`、`conic`。
- 口径已拍板：方法/专题章按知识章同口径补到 6 关。
- `conic` 挂载方式结论：**C4–C6 走 `lab_ref` + `LabStage` 通用通道**（`lab: "conic"`、`lab_ref` = `C4`/`C5`/`C6`，
  组数据写入 `data/conic_levels.json`），不动 `ConicStage` 的 C1–C3 硬编码场景；选题避开
  `ellipse`/`hyperbola`/`parabola`/`conics` 已有内容（改为「定义的应用·求基本量 / 定义法求轨迹方程 / 含参分类与综合」）。
- 每章固定流程（照前 3 章的样子，缺一步校验器会红）：
  1. `data/<章>_levels.json` 追加关卡组：每组 5 轮（探究→建构→迁移→巩固→综合），`ans` 恒为 `0`，
     数学式子一律 `$$…$$`（**不写** Unicode 片段、**不加** `FORMULA_LATEX` 命名）；
  2. `data/curriculum.json` 该章 `levels` 追加同 id 条目：`technique`/`archetype`(`LAB`)/`lab`/`lab_ref`/`scene` 照抄邻条
     （知识章 `name` 用 `1-N`；方法章沿用无编号习惯，如 `conic` 的「定义的基本量」）；
  3. `data/knowledge_map.json` 该章 `points` 追加 `{ "name": "1-N …", "levels": ["<id>"] }`
     （漏挂 → `check_knowledge` 退出 1）；
  4. `godot --headless --path . --script res://tools/fix_labels.gd -- --apply` 规范轮次标签 `<关卡序号>-<轮次>`；
  5. 校验：`check_all` / `check_questions` / `check_knowledge` / `check_inline` / `smoke_scene.tscn` /
     `Tests.tscn` / `UiSmoke.tscn` / `LabSmoke.tscn` / `check_assets`；
  6. 更新本文件 §0.1、§9.1、§9.2 与本节表格，提交 `feat(E2): <章> a→6 关`。
- LaTeX 渲染自检（**临时探针，用完即删**，否则 `CHECKED` 计数会变）：扫 `data/*.json` 的 `\$\$([^$]+)\$\$`，
  逐条 `InlineMath._latex_bbcode(latex, 26)`，返回值不含 `[/img]` 即渲染失败；`conic` C4/C5/C6 逐组进程 68/76/68 段 · 0 失败。
- ⚠️ 待人工复核：`conic` C4–C6 共 15 题（离心率/基本量、轨迹方程、含参分类与综合），复核后再算「已验收」。

---

### [x] E3 · 补全整块缺失的教材必学知识点（P1）—— 2026-10-20 收官

> 下列每条都已在现有章节里确认**完全没有**对应关卡。括号内为教材出处。

1. ⏭️ **数学归纳法**（人教A选必二 4.4 / 苏教选必一 4.4）—— **跳过**（2026-10-19 用户判定：现行教材已删，不再学习，不再新增 `seq_induction`）。
2. ✅ **不等式的基本性质与比较大小**（人教A必修一 2.1）（2026-10-20 补齐验收）—— `inequalities` 原无。
   新增 `ineq_props`：可加性/乘负数改向/作差法/同向可加/同号取倒数，本轮补 `3-6`
   （**对称性 a>b⇔b<a 与传递性 a>b、b>c⇒a>c 的辨析**，并改掉命中 B5 黑名单的「无法确定」干扰项）。
3. ✅ **一元二次不等式含参讨论**（2026-10-20 补齐验收）—— `ineq_quad` 只讲图像法解集。
   新增 `ineq_param`：恒成立、由解集反求系数、ax>1 分类；本轮补 `4-6`（**二次项系数 a 的符号 + Δ 与
   恒成立的关系**：全体实数解需 a>0 且 Δ<0）、`4-7`（**先比较两根 1 与 m 的大小再写解集**）。
4. ✅ **集合间的基本关系与补集·德摩根律**（人教A必修一 1.2 / 1.3）（2026-10-19 完成）——
   新增 `set_relation`（子集/真子集/集合相等/空集与 ∈、⊆ 之辨/元素互异性筛根）与
   `set_complement`（文氏图补集边界、区间求补、补集+card 联用、德摩根律辨析），共 2 组 10 轮。
5. ✅ **三角恒等变换完整体系**（必修一 5.5）（2026-10-19 完成）—— 新增 `trig_sumdiff`（两角和差，
   单位圆双角读数探究 cos(α−β)）、`trig_double`（二倍角/升降幂/半角）、`trig_aux`（辅助角 `asinx+bcosx`
   最值与单调区间），共 3 组 15 轮；E1 的两条硬缺口（两角和差 / 二倍角）随之清零，基线文件改 0。
6. ✅ **解三角形的实际应用**（必修二 6.4.3）（2026-10-19 完成）—— 新增 `trig_measure`（1 组 5 轮）：
   仰角测高实验 + `BC=AB·tanα` 公式建构、方位角（北偏东 30° 与正东夹角）、后退法测塔高
   （30°/15° 两次观测，精确解 10 m）、河对岸不可达距离（`AD=CD/cos60°=160 m`）；
   顺带修正错名——`trig_apply` 实为简谐运动建模，curriculum/知识点「1-5 测量应用」改「1-5 三角函数的应用」。
7. ✅ **排列组合方法体系**（选必三 6.2）（2026-10-19 完成）—— 原 `counting` 仅 4 关且无方法体系，
   新增 `count_bundle`（捆绑法/插空法：整体排列×内部排列、相邻/不相邻列式辨析、相邻且不相邻综合）、
   `count_partition`（隔板法：正整数解、允许空盒、至少转化、名额分配）、
   `count_misc`（错位排列 D₄/D₅ 递推、链状染色与首尾异色排除、至少问题用补集），3 组 15 轮；
   加上 E2 `780fe06` 已落地的 `count_group`（分组分配），4 组 20 轮齐。
8. ✅ **二项式系数的性质**（选必三 6.3.2）（2026-10-19 完成，出处 `780fe06` 本轮复核）——
   `count_binom_props`（对称性、最大项、奇偶项和、赋值求和）为 E2 落地；本轮补 `6-6`
   （`(1+2x)^5` 系数和 243 ≠ 二项式系数和 32），落实"系数"与"二项式系数"之辨。
9. ✅ **函数模型的应用与增长对比**（必修一 4.5.2）（2026-10-19 完成）—— `func_apply` 只有一次/二次/分段建模。
   新增 `func_model` 5 轮：指数 y=2ˣ 与幂 y=x² 交点读图探究（(2,4)/(4,16)）、充分大时增长速度排序
   （指数>幂>一次>对数）、细菌分裂情境选指数模型、两点拟合 y=a·bˣ 定底数、复利 1000×1.05²=1102.5；
   curriculum 1-14、知识点 268 点全挂载。
10. ✅ **导数的最值与优化应用**（选必二 5.3）（2026-10-19 完成）—— 只有极值，无最值与实际优化。
    新增 `deriv_extrema` 5 轮（读图端点最值、x³−12x 闭区间最小值 −16、含参 g(1)=2、M−m=4、
    a≥0 时无极值），`deriv_optimize` 5 轮（利润抛物线读图、顶点定价 80、平均成本最低 x=20、
    水渠断面宽:深=2:1、顶点被区间截断 L(25)=2875）；curriculum 1-7/1-8、知识点 270 点全挂载。
11. ⏭️ **复数的三角表示**（必修二 7.3*，**选学**）—— **跳过**（2026-10-19 用户判定：现行教材已删，不再学习，不再新增 `cplx_polar`）。
12. ✅ **抽样方法细分与统计案例**（必修二 9.1 / 9.3）（2026-10-19 完成）—— `stat_sample` 仅 3 轮承载。
    新增 `stat_sampling` 5 轮（等距间隔读图、识别系统抽样、起点 7 抽 30 个末号 297、
    方法—情境匹配辨析、每人被抽中概率 0.05），`stat_case` 5 轮（员工体检案例：条形图读 15%、
    估计 1000 人中肥胖 150 人、健身房抽样偏差辨析、结论表述"约 15% 且有抽样误差"、
    同一抽样比下 800 人抽 80）；curriculum 1-7/1-8、知识点 272 点全挂载。
13. ✅ **相关系数与残差分析**（选必三 8.1 / 8.2）（2026-10-19 完成）—— E2 已有 `cd_resid`/`cd_rprops`，
    但缺 r 的**数值计算**。新增 `cd_corr_coef` 5 轮（近乎共线散点判 r≈0.98、分母非负故 r 的符号由分子决定、
    由离差和算 r=60/80=0.75、r=−0.92 的解释、异常点使 |r| 明显变小），`cd_resid` 补 `4-6`
    （残差图呈弯曲趋势 → 应换曲线模型）；curriculum 1-7、知识点 273 点全挂载。
14. **向量在物理与解三角形中的应用**（必修二 6.4）—— ✅ 已落地（2026-10-20，`7f94b7c`）。
    → 新增 `vector_physics`（`vectors` 章 1-7，5 轮）：力的合成、速度分解、做功；
    解三角形部分由既有 `trig_measure` 承接，章 `renjiao_a` 扩为 6.1–6.4。
15. **随机模拟**（必修二 10.3.2，可选）—— ✅ 已落地（2026-10-20，`9534189`）。
    → 新增 `prob_simulate`（`probability` 章 1-12，5 轮）：撒豆法估 π、投点估面积、频率估计与建模辨析。

**同时明确"不作为缺口"的内容**（写进 E1 的矩阵，避免以后误判）：
- **定积分与微积分基本定理**：2019 课标已从高中移除（旧课标选修 2-2），**仅当教材版本含此内容时才补**；
- **绝对值不等式 / 分式不等式 / 高次不等式（穿根法）**：属旧课标或部分版本，标注为"视版本"；
- **参数方程与极坐标**：新课标弱化，标注为"不适用（旧课标）"，除非定位离线老教材。

**验收**
- ✅ 15 条全部落定：**13 条落成关卡**（#2~#10、#12~#15，其中 #2/#3 于 2026-10-20 补齐验收轮），#1 数学归纳法、#11 复数三角表示经用户判定**教材已删、跳过**，
  并在 E1 矩阵里由「未覆盖」变为「已覆盖」（此两条保持 `optional=true` 的选学标注）；
- ✅ 每条新关卡的题目质量符合 B 类要求（非纯四选一、有干扰项设计）：末两条各含 1 轮**填空**、
  `vector_physics` 另含 1 轮**多选**，`ans` 位置刻意分散；
- ✅ E1 硬缺口保持 0（`check_knowledge` hard-gaps=0，基线 0），`docs/知识点覆盖矩阵.md` 由数据重新生成。

---

### [ ] E4 · 方法章与专题章过薄、且与知识章脱节（P2）

**现状（证据）**
- `function_methods`（`kind=method`）已 1→6（2026-10，`fm_transform`/`fm_composite`/`fm_inverse`/`fm_quad_interval`/`fm_root_dist`）；
- `conic`（method）已 1→6（2026-10，C4–C6 走 LabStage）、`solid`（method）6 关、`recurrence_methods` 6 关；
- `thinking`（`kind=knowledge`，`subtitle="苏教专题"`，`chapter_no="综合"`）4 关，
  内容是"函数与方程 / 数形结合 / 分类讨论 / 转化化归"——**这四种思想本应贯穿各章**，
  独立成章后与具体知识点脱节，学生学完不知道用在哪。

**做法**
- 方法章每章补到 **≥6 关**（✅ `function_methods`、`conic` 均已 1→6 完成，2026-10）；
- `thinking` 二选一：
  - 保留独立章，但每关**必须挂一个跨章综合题**（如"用数形结合解一道导数+不等式题"）；
  - 或改为在知识章内打「思想标记」（关卡级 `thought: "数形结合"` 字段），由知识树聚合成视图。

**验收**
- 方法章 ≥6 关；`thinking` 与知识章有明确引用关系（不再是孤立专题）。

---

### [ ] E5 · 与教材对齐的持续核对流程（P1）

**现状（证据）**
- `data/textbooks.json` 声明支持 **6 个版本**，但每个版本只定义了
  `books` / `knowledge_order` / `chapter_book` / `chapter_no`（**排序与章号**），
  **没有"这个版本的这个小节是否已被覆盖"的任何信息**；
- 换教材版本只改变展示顺序，**覆盖缺口不变**（同一批 27 章）。

**做法**
- 用 E1 的覆盖矩阵承载三层映射，并**按版本标注差异**（例如人教B 把概率与统计合在第 5 章、
  沪教把立体几何放必修三）；
- 新增教材版本的流程写进 `README.md`「改内容」小节：
  **先补矩阵（列出该版本小节）→ 再看缺口 → 再考虑补关卡**；
- 矩阵中显式区分三种状态：`已覆盖` / `未覆盖（待补）` / `不适用（选学·旧课标）`。

**验收**
- 矩阵含 6 个版本的教材小节行；
- `README.md` 有"新增教材版本"的分步流程；
- 任选一个版本，能一眼看出该版本还缺哪些小节。

---

## 6. F 类 · 发布就绪与运行时体验

> 前五类是"能跑对、教得好"；这一类是"**能上架、能长跑**"。
> F1/F2 是**上架前必做**（否则要么违规、要么装不上商店），F3~F6 是体验与寿命。

### [x] F1 · 在线 TTS 的合规与稳定性（P0，上架前必做）

**现状（证据）**
- `scripts/ui/TtsOnline.gd` 走的是**第三方非公开接口**，且**没有 API key**：
  - 百度：`https://fanyi.baidu.com/gettts?lan=zh&text=%s&spd=%d&source=web`
  - 有道：`https://dict.youdao.com/dictvoice?le=zh&audio=%s`
- 请求还**伪装浏览器 UA**（`Chrome/122.0.0.0 Safari/537.36`，`TtsOnline.gd:8`），
  属于绕第三方风控的用法，接口随时可能失效或被限流。
- 合成内容 = **题干/追问/解析原文**（`StageBase.gd:1082` 的朗读按钮），
  即**学生题目文本会被发到百度/有道服务器**；`export_presets.cfg` 里
  `permissions/internet=true` 已开启联网权限。
- 命中过的文本缓存到 `user://tts_cache/*.mp3`（`CACHE_DIR`，`TtsOnline.gd:6`）。

**为什么必须处理**：面向 K-12 学生 + 上架应用商店时，这涉及
《个人信息保护法》《未成年人个人信息网络保护规定》与各商店的隐私合规审核；
且第三方非公开接口一旦失效，"朗读"功能会整体不可用（而这是 B13 刚补齐的**无障碍**能力）。

**做法（三选一，建议前两项）**
1. **改为本地/系统 TTS 优先**：`scripts/ui/Tts.gd`（系统 TTS 子系统）已存在，
   把它设为默认，在线方案降级为"可选增强"；
2. **改用官方授权接口**（百度/讯飞/阿里云 TTS 的正规 API + 密钥），并处理密钥存放
   （**不得硬编码进客户端**，需服务端中转或用户自带 key）；
3. 若保留现状：**默认关闭 + 首次使用弹明示同意**，并在隐私政策里披露文本外发。

**验收**
- 默认路径不向第三方发送任何内容；
- 若保留在线路径，有明示同意 + 隐私政策条目 + 官方授权凭证；
- 断网时朗读功能可用（走本地 TTS）。

**已实施（记录）**
- 采用「默认关闭 + 首用弹明示同意」（选项 3）：`Settings` 默认 `voice=false`、`tts_engine=system`
  （离线优先），新增持久化 `tts_online_consent`（默认 false）。
- `Tts.say()` 在 `engine=="online"` 且未同意时**绝不外发**：改弹一次性说明（`UI.confirm`，含"取消→改用离线"分支），
  无界面环境（headless/CI）直接降级离线；取消即会话内切回系统语音。
- 设置页文案注明"需联网 · 首次使用会询问是否允许外发文本"。
- 新增 `docs/隐私政策.md`（唯一网络功能=可选在线朗读；无埋点/广告/账号；本地存储说明）。
- 回归：`tests/Tests.gd` 增 `_test_tts_policy()`（默认关闭/离线/未同意不外发）；TESTS 1233 → 1238。

**残留风险（上架前）**
- 在线路径仍是**第三方公开接口、无官方授权与密钥**（`TtsOnline.gd` 伪装 UA）：可能违反第三方条款或随时失效。
  若上架正式商店，建议二选一：改用官方授权 API（密钥放服务端，CLIENT 不硬编码）**或**移除在线引擎、只保留离线。
- 需在商店后台的**数据安全/隐私表单**中勾选"朗读文本可能外发第三方"。

---

### [x] F2 · 发布准备（包名 / 版本 / 签名 / targetSdk）（P0，上架前必做）

**现状（证据，`export_presets.cfg` + `project.godot`）**
- `package/unique_name="com.theorematrix.game"` —— 与产品名"衍数阁"无关，疑似历史残留。
  **包名一旦上架便不可更改**（改包名 = 上架一个全新应用，用户与评价清零）。
- `version/code=1` / `version/name="1.0.0"`，且**没有任何发版/递增流程**（无脚本、无 CI，见 A6）→ 每次发版手改，容易忘改导致商店拒包。
- **只配置了 debug 签名**（`docs/环境配置.md` 第 6 节只有 `debug_keystore`）→
  Android 商店要求 **release 签名**，当前状态**无法正式上架**。
- `gradle_build/min_sdk=""`、`gradle_build/target_sdk=""`（用模板默认）→
  各商店（Google Play / 国内应用市场）对 targetSdk 有逐年要求，需显式确认。
- `architectures/armeabi-v7a=false`（仅 arm64）→ 老旧 32 位设备装不上（可接受，但需知情）。

**做法**
- **先定包名**（建议 `com.<品牌>.<产品>`，如 `com.derivative.gates`），再谈上架；
- 生成 release keystore 并写入预设（密钥文件入 `.gitignore`，口令走本地配置）；
- 加发版脚本/CI：递增 `version/code`、改 `version/name`、导出、归档产物（配合 A6）；
- 显式设定 `min_sdk` / `target_sdk` 并在 README 记录依据。

**验收**
- release 签名可导出并安装到真机；
- 发版只改一处版本号（脚本自动同步三处预设）；
- 包名与 targetSdk 有明确书面决定。

**已实施（记录，除"真机实装"外均完成）**
- 包名定为 **`cn.edu.mathgates`**（`package/unique_name`）。
- 显式 `min_sdk=24` / `target_sdk=35`（依据见 `docs/环境配置.md` §6）。
- 预设补齐 `keystore/release*`（指向 `keystore/mathgates-release.keystore`，`release_user=mathgates`，
  口令留空由本地填）；`keystore/`、`*.keystore`、`*.jks` 加入 `.gitignore`。
- 新增 `tools/bump_version.gd`：一处改版本，自动同步 `version/code`、`version/name` 与 3 个 Windows 预设的
  `application/file_version`/`application/product_version`（`x.y.z.0`）；本次已把 Windows 版本从空同步为 `1.0.0.0`。
- `docs/环境配置.md` §6.1 写明 keytool 生成 keystore + 填充口令 + `--export-release` 全流程。

**残留（需本机/账号动作）**
- 生成 release keystore 并填入口令（密钥不入库）；
- 真机安装验证；应用商店的**数据安全/隐私表单**（与 F1 的 TTS 外发一致）；
- 可选：`package/retain_data_on_uninstall` 当前为 true，上架按隐私策略确认。

---

### [ ] F3 · 性能与耗电（3D 视口与背景常驻开销）（P1）

**现状（证据）**
- `scripts/modules/lab3d/Lab3DView.gd:76` → `_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS`：
  3D 视口**每帧渲染**；且 `auto_rotate := true`（第 55 行）**默认自动旋转**，
  `_auto_pause` 只在特定操作后暂停 1.5~3s。学生停在 3D 关卡（31 个关卡）时，
  会持续"渲染 + 旋转"——移动端耗电/发热，且**静止时没有信息增量**。
- `scripts/ui/TechBg.gd:218` → `set_process(true)`，`_process` 每帧
  `_fx.queue_redraw()`（粒子/网格全屏重绘），**几乎所有场景常驻**。
- 对比：`BrandMark` 已经做了正确的示范（`set_process(UI.animations and active)`）。

**做法**
- 3D 视口改**按需更新**：`UPDATE_WHEN_VISIBLE` 或脏标记驱动（拖动/动画/自转时才刷新）；
- 自转加"**空闲 N 秒后停转**"，触摸/拖动立即恢复（已有 `_auto_pause` 可扩展成常驻策略）；
- `TechBg` 在 `UI.animations == false`、或应用进入后台
  （`NOTIFICATION_APPLICATION_PAUSED`，`GameData` 已有该通知）时**停帧**；
- 建立**性能基线**：3D 关卡与首页的帧时间/内存（可复用 `tools/lab3d_render_check.gd` 的采集思路），
  纳入 A6 的 CI 趋势跟踪。

**验收**
- 静止 10s 后 3D 视口不再每帧渲染、自转停止；后台时全场景停帧；
- 记录 3D 关卡/首页的帧时间与内存基线（Android 真机）。

---

### [ ] F4 · 桌面端键盘操作（P1）

**现状（证据）**
- 项目**发布 Windows 桌面版**（`export_presets.cfg` 有 3 个 Windows 预设），
  但主流程**完全没有键盘支持**：`StageBase` / `LabStage` / `Lab3DStage` / `TheoremTree` /
  `MainHub` 里搜不到任何 `InputEventKey` / `KEY_*` 处理。
- 反差很明显：**遗留的圆锥曲线场景反而有**
  （`scripts/modules/conic/scenes/C1.gd:99` 起完整支持 `KEY_1`~`KEY_6`、
  `KEY_UP/DOWN/LEFT/RIGHT`、`KEY_SPACE`、`KEY_D`、`KEY_ESCAPE`；`C2.gd`/`C3.gd` 同）。
- 全局仅两处键盘：`Sound.gd:101`（`M` 静音）、`Scene.gd:125`（`ui_cancel` = Esc 返回）。
- 后果：桌面用户答选择题必须**逐个鼠标点击**，不能按 1/2/3/4 选项、不能 Enter 提交/下一题、
  不能用方向键在选项间移动——对已发布的桌面版是明显体验缺口（也影响键盘无障碍）。

**做法**
- 在 `StageBase` 统一注入键盘层（各 Stage 子类自动获得）：
  `1..4`（或 `A..D`）选项、`Enter` 提交/下一题、`←/→` 或 `↑/↓` 移动焦点、`H` 提示、`M` 静音（已有）、`Esc` 返回（已有）；
- 3D 关卡补 `W/A/S/D` 或方向键控制视角（`Lab3DView` 已支持拖动，补键盘映射即可）；
- 焦点可见（当前选中项高亮），避免"键盘能用但不知道选到哪"。

**验收**
- 桌面版可用纯键盘完成：进入关卡 → 答题 → 提交 → 结算 → 下一关；
- 焦点状态可见；与鼠标操作行为一致。

---

### [ ] F5 · 存档版本化与进度迁移（P2）

**现状（证据）**
- 存档（`user://users.json`）**没有版本号**：`GameData.gd` 内搜不到 `version` / `save_version` / 迁移函数；
  兼容性完全依赖"新增字段用 `.get(key, default)`"的约定（当前确实如此，属于良好习惯）。
- **进度完全绑定本机**：只有 `users.bak` 本地备份（`GameData.gd:1662` 会读，备份有效）；
  没有导出/导入、没有跨设备迁移。`UserProfile` 里也没有相关入口。
- 后果：学生**换手机/重装/清数据 = 进度全丢**（含 228 关星级、勋章、萌宠、错题本）。

**做法**
- 存档加 `schema` 版本号 + 升版迁移钩子（成本极低，避免未来改结构时"只能丢档"）；
- 提供**进度导出/导入**：导出为单文件（JSON/压缩）或"文本码"，
  经系统分享/文件选择器传递（不引入账号体系即可跨设备）；
- 若要云同步，需与 F1 一起做隐私评估（学生数据）。

**验收**
- 存档含版本号，升版时可迁移且旧档可读；
- 真机验证：导出 → 另一台设备导入 → 星级/勋章/萌宠/错题本完整恢复。

---

### [ ] F6 · 首次引导与机制说明（P2）

**现状（证据）**
- 全仓搜不到 `tutorial` / `onboarding` / `新手引导` / `first_run` 一类的首启引导实现；
- 现有解释是**分散且隐式**的：关卡内 `tip`/`hint`、探究轮的 `goal`、萌宠台词
  （`StageBase._pet_message()`）、实验室的「? 演示」按钮——都需要学生自己先点出来。
- 学生需要理解的机制其实不少：滑块怎么拖、三星怎么拿、连击怎么算、
  隐藏 Boss 门的解锁条件（P3 的 `gate.need_stars`）、宝箱/随机事件、萌宠与领域掌握度。

**做法**
- 首次进入各界面时给**一次性引导**（首关的 3~4 步气泡：拖动 → 提交 → 看解析 → 拿星）；
- 知识体系/地图页首次进入时说明**图例**（Boss 门、宝箱、随机事件、支线）；
- 提供「? 帮助」入口（随时可回看），并在设置里给「重置引导」。
- 与 D4 的开关语义联动：引导属"表意"内容，不应被「界面动效」总开关关掉。

**验收**
- 新用户（清档）能仅凭引导完成第一关并说清"三星怎么来"；
- 图例/帮助可在任意时刻回看。

---

### [x] F7 · 授权与第三方声明缺失（P0，上架与开源前必做）

**现状（证据）**
- **仓库根没有 `LICENSE`**（`git ls-files` 无 LICENSE / COPYING / NOTICE）——
  项目自身授权未声明（私有？开源？保留所有权利？）。
- 第三方许可文件**只散落在被打包进来的 MicroTeX 字体目录**：
  `gdextension/res/fonts/licences/{Knuth_License.txt, License_for_dsrom.txt, OFL.txt}`、
  `gdextension/res/cyrillic/LICENSE`、`gdextension/res/greek/LICENSE`。
  **没有一份汇总的 `THIRD_PARTY_NOTICES`**（godot-cpp、MicroTeX、CM/dsrom 字体都缺）。
- **内置字体的来源与授权没有记录**：`scripts/ui/UI.gd:79` 直接引用
  `res://art/fonts/aidianqianfengxingshu.ttf`（**13.8MB**，见 A13），
  全仓搜不到它的来源、许可或商用说明。
- **`art/` 素材无来源记录**：目录下没有任何 txt/md 说明，背景图（5.0MB/2.4MB）、
  图标、头像、（以及入库的 `.xcf` 源文件）来源不明。
- **教材改编内容的版权未评估**：`README.md` 与 E 类都写明"按教材（苏教/人教A/…）重构、
  按教材顺序对齐"。若题面**改编自教材习题**，涉及出版社著作权；
  若只是"知识点对齐 + 自编题面"，则风险可控——但**目前没有任何书面说明**。
- `docs/环境配置.md` 只记录 godot-cpp（4.4 分支）与 MicroTeX（commit）的**版本与 commit**，
  **不含授权信息**。

**为什么是 P0**：应用商店上架会核查第三方素材授权与隐私政策；
一旦上线后才发现某个字体/图片不可商用，代价是**替换全部美术 + 重新发版**。

**做法**
1. 加根 **`LICENSE`**：明确项目自身授权（或显式写"私有，未开放授权"）；
2. 加 **`THIRD_PARTY_NOTICES.md`**：逐项列「依赖 / 字体 / 素材」的名称、版本、
   许可类型、来源链接，并注明**商用与再分发条件**（godot-cpp 为 MIT，需保留声明）；
3. **逐个确认内置字体的授权**（尤其那 13.8MB 行书字体）：能确认则记录，
   **不能确认就替换为明确可商用的**（如 OFL 授权字体），顺带解决 A13 的体积问题；
4. `art/` 建 `art/SOURCES.md`：记录每个素材的生成方式/来源与授权；
5. 内容侧：改为**"知识点对齐教材 + 题面自编"**，并在 README 注明，避免逐题改编；
6. 把这一项写进 F2 的**上架检查清单**。

**验收**
- 根 `LICENSE` + `THIRD_PARTY_NOTICES.md` 齐备；
- 每个字体、每张美术素材都能追溯到可商用的授权来源；
- README 有"内容与教材的关系"说明（知识点对齐，非题目改编）；
- 上架检查清单包含此项。

**已实施（记录）**
- 新增根 **`LICENSE`**（专有/保留所有权利）与 **`THIRD_PARTY_LICENSES.md`**（Godot、MicroTeX 的 MIT 全文）。
- 新增 **`THIRD_PARTY_NOTICES.md`**：逐项列出 Godot/MicroTeX/godot-cpp（组件）与全部随包字体
  （CM=Knuth、AMS Euler/Symbols=OFL、dsrom=宽许可）、美术/音效，标注许可与来源，含上架检查清单。
- **发现并排除 GPLv3 字体**：上游 MicroTeX 的 `res/greek`、`res/cyrillic` 随附完整 GPLv3（与专有发布冲突）。
  已 `git rm` 这两个目录 + 在 `tools/pack_math_res.gd` 加 `EXCLUDE_DIRS` 兜底 + 更新 `RES_README`；
  `res.bin` 652 KB/78 项 → 297 KB/36 文件（顺带缓解 A13）。
- **渲染复验**（dev 模式直接用 `gdextension/res/`，已清 `%TEMP%\mathtex_res` 缓存）：
  `MT_READY=true`、`VERIFY_TABLE: total=3904 fail=0`；五件套全绿。
- 新增 **`art/SOURCES.md`**、**`audio/SOURCES.md`**（逐项来源/授权，待项目组确认签字）。
- README 增「内容与教材的关系」（**知识点对齐教材、题面自编**）与「授权与第三方声明」两节。
- 全仓核实：**唯一**网络访问为可选在线 TTS（与 F1 一致，无埋点/广告/账号）。

**残留（需决策/采购，见 `THIRD_PARTY_NOTICES.md` §6）**
- ❌ **标题字体 `art/fonts/aidianqianfengxingshu.ttf`（13.8 MB）授权不可核实** → 上架前**必须替换**为
  OFL 字体（推荐霞鹜文楷/得意黑），并顺手解决 A13；
- ⚠️ `rsfs10`/`stmary10` 上游无单独许可文件，待核或替换；
- ⚠️ `art/`（除公式生成物）与 `audio/*.wav` 的来源需项目组签字确认（`SOURCES.md`）；
- ⚠️ 仓库有公开 remote（`github.com:czqjrj/MathGates`）：若维持公开，请确认"专有授权"与"公开可见"是否冲突
  （或转为私有仓库）。

---

## 7. G 类 · 产品演进（增强，非缺陷）

> 前六类是"把已有的东西修好"；这一类是"**让产品更强**"。
> **G4 / G5 是决策项**（技术或产品上暂不实施），列在这里是为了**不丢想法**，不是待开工的任务。
> 建议顺序：**G2（作者工具链）→ G1（SRS）→ G3（学习报告）**，G2 先行能显著降低 E 类的补内容成本。

### [ ] G1 · 错题间隔重复（SRS 遗忘曲线排程）（P1）

**现状（证据）**
- `GameData.review_order()`（`GameData.gd:1319`）目前只做两件事：
  ① 按 `wrong_count_for()` **错得多的排前面**；② 若带 `focus`，把该题提到最前。
  —— **完全没有时间维度**，同一道题昨天错和三个月前错，排程一模一样。
- `wrong_log[key]` 的字段只有
  `{ level_id, qi, name, module, count, last_chose, correct }`（`GameData.gd:1164-1167`）——
  **没有任何时间戳**（`last_chose` 是选项下标，不是时间），
  因此当前**无法回答"这道题上次复习是什么时候"**。
- 已有的清债机制是"**答对一次就减一次债**"（`GameData.gd:1151-1159`：`count -= 1`，归零则
  `clear_wrong` 并 `wrong_cleared.emit`）—— 这是"次数"语义，不是"间隔"语义。
- 调用链：`StageBase._apply_review()` → `review_order()`；深链入口 `review_focus`
  （`GameData.gd:154`），错题本 `scenes/WrongNotebook.tscn` / `UserProfile._wrong_summary_card()`。

**做法（分两步，第一步就能见效）**
1. **扩字段**：`wrong_log` 增加 `first_wrong_at` / `last_review_at` / `due_at` / `interval_days` / `ease`
   （旧存档缺字段按"立即到期"处理，天然兼容）；
2. **排程**：引入简化版 SM-2 / Leitner 分箱——答对则 `interval *= ease`（如 1→3→7→16→35 天），
   答错则**重置到 1 天**并 `count++`；`review_order()` 改为**按 `due_at` 升序**（到期先做），
   错题优先只作为**同到期日的次序**规则；
3. **入口**：首页/错题本显示「今日待复习 N 题」，一键进入复习队列（现有深链机制已能复用）；
4. 与 C 类联动：复习答对仍给金币，但**同一题当日重复不再重复计奖**（避免刷）。

**验收**
- `review_order()` 的排序依据由 count 改为到期时间；同一批错题隔天回来时"该复习的"排最前；
- 今日待复习数量可显示并可一键进入；
- 旧存档可加载（无时间戳者视为立即到期）；
- `Tests.gd` 新增：模拟 5 天推进，验证间隔按 1/3/7/16 增长、答错重置。

---

### [ ] G2 · 关卡作者工具链（编辑器 + 实时预览）（P1）

**现状（证据）**
- 内容规模：**228 关 / 712 题**全部手写在 26 个 `data/*_levels.json` 里，
  而 E 类还要**新增约 40 关**、B 类还要大改干扰项/题型——**纯手工 JSON 的成本是当前最大的瓶颈**。
- 现有 `tools/` 已有**半个雏形**（15 个脚本），但只有"调试 + 截图 + 校验"，**没有"编辑"**：
  - `dev_seq.gd` —— 直达某一关/某一轮（预览的基础）；
  - `dev_shots.gd` / `capture_scene.gd` —— 逐轮截图（可视化验证）；
  - `check_all.gd` / `check_inline.gd` / `smoke_scene.gd` —— 静态与运行期校验；
  - `gen_inline.gd` —— 批量生成公式映射（**已证明"脚本生成内容"这条路可行**）。
- 缺的是：新建关卡向导、字段提示与补全、**改完即时看到效果**、以及把 A5 校验器的报错直接定位到行。

**做法（由轻到重，可分期）**
1. **关卡预览器**（轻）：`tools/level_preview.gd(+tscn)` —— 左侧选 `章节/关卡/轮次`，
   右侧直接渲染该轮的 `scene`（复用 `LabStage`/`Lab3DStage` 的 `_build_view`），
   支持热重载 JSON（改文件即刷新），并叠加 A5 的校验结果；
2. **编辑态**：在预览器上加最简编辑能力（改题干/选项/`ans`/`scene` 滑块参数 → 写回 JSON），
   先只支持 `qe` 与 `scene` 两类字段，不做通用 JSON 编辑器；
3. **脚手架命令**：脚本生成"新章节/新关卡"的 JSON 骨架（含 E 类要补的知识点 id、四阶段占位），
   避免手抄 30 行样板；
4. **与 E1 联动**：新建关卡时必须填「对应知识点 id」，直接落进覆盖矩阵。

**验收**
- 能在一个窗口里完成：选关卡 → 看效果 → 改题干 → 保存 → 立即看到新效果；
- 用脚本生成一个符合规范的新关卡骨架（不含手抄样板）；
- E 类补内容的平均单关耗时明显下降（可记录前后对比）。

**进度（🟡 做法 1/2/3/4 已落地，2026-10-19）**
- 新增 **`tools/json_text.gd`**：JSON 文本级修改原语（字符串感知的括号匹配定位、
  对象/数组末尾追加、键值替换），**不重排文件**，git diff 最小。
- 新增 **`tools/LevelPreview.tscn` + `tools/level_preview.gd`**（关卡预览器/编辑器）：
  - 左侧「章节 → 关卡 → 轮次」三级选择，右侧用**真实舞台**渲染该轮
    （LabStage/Lab3DStage/SequenceStage/ConicStage/SolidChallenge 均可预览）；
  - **热重载**：`data/*_levels.json` / `curriculum.json` 外部改动 ~0.7s 自动刷新重建；
  - **编辑态**：q / ask / opts（每行一项）/ ans / hint / explain / scene（整个 JSON 对象）
    → 「写回 JSON」（文本级，写前做「可解析 + 组数/轮数不变」终检，失败不落盘）；
  - **内置 A5 轻量校验**：轮次编号（B9）/ ans 范围 / 选项重复 / 题干缺失与文件内重复，选关即显示；
  - 代码驱动遗留关（SolidChallenge 方法关 / ConicStage C1~C3）**只读预览**；
  - headless 自检 `-- --smoke`：**6313 断言 / 0 fail**——覆盖 26 个数据文件全量「组/轮/字段定位回归」、
    内存编辑往返（不写盘）、校验器存量扫描、每类舞台抽样构建。已入 CI。
- 新增 **`tools/scaffold_level.gd`**（关卡脚手架，做法 3/4）：
  - `-- --file=<*_levels> --key=<新组> [--chapter=<章>] [--name=…] [--rounds=5] [--apply]`，默认 dry-run；
  - 生成 5 轮骨架（探究 explore→建构 choice→迁移 choice→巩固 input→综合 choice，`ans=0`，
    【TODO】占位互不重复以避免触发题干重复检查；探究轮带合法的 sliders/lines 占位 scene）；
  - `--chapter` 同步追加 `curriculum.json` 该章 levels（**结构克隆该章最后一条**，自动适配
    LabStage/Lab3DStage 的 `lab`/`lab_ref`/`space` 字段）与 `knowledge_map.json` 该章 points（E1 联动）；
  - **集成实测**：apply 到 `inequalities` 后 `check_questions` **0 new**、
    `check_knowledge` 259 points 全映射、hard-gaps 不变（测后已还原）。
- CI：`check.yml` 新增 `LevelPreview 自检` 与 `scaffold dry-run` 两步。
- README 新增「关卡作者工具链（G2）」一节（推荐创作流程）。

**残留**
- ⚠️ 预览器的 GUI 观感/操作手感**未经人眼验收**（本机 headless 无法目视）；
- ⚠️ 编辑态暂不覆盖 `steps`/`goal`/`success`（explore 轮的实验文案）与多选 `ans` 数组；
- ⚠️ 「校验报错直接定位到行号并高亮」未做（当前为文字清单）；
- ⚠️ 「E 类补内容平均单关耗时前后对比」待实际使用后记录。

---

### [ ] G3 · 学习报告 / 家长视图（P2）

**现状（证据）**
- `scripts/screens/UserProfile.gd` 已有**不错的统计展示**：
  通关数 / 累计作答 / 累计答对 / 正确率 / 总星 / 投喂次数 / 称号（第 66~77 行），
  以及 `_mastery_card()`（领域掌握度）与 `_wrong_summary_card()`（错题汇总）。
- `GameData` 已提供可复用的聚合接口：`accuracy()` / `key_points()` / `domain_mastery()` /
  `level_mastery()` / `wrong_list()` / `rank_title()` / `player_level()` / `stars_of()` /
  `best_time_of()` / `daily_*()`。
- **缺口**：① **无任何导出**（JSON/表格/图片/分享都没有）；② **无时间维度**
  （`level_records[].last_clean` 有记录但没有趋势/曲线）；③ **无家长/教师视角**
  （只面向学生本人，且只有"当前状态"没有"周报"）。

**做法**
- **周报/月报**：基于已有数据生成"本周新增星数 / 复习完成率 / 薄弱领域变化 / 错题净增"，
  存为可分享的图片或文本（复用 `UI` 的绘制能力即可，无需新依赖）；
- **导出**：一键导出 JSON 或 CSV（`wrong_log` / `level_records` / `stars`），
  走系统分享/文件选择器（与 F5 的存档导出共用一套机制）；
- **家长视角**：只读摘要页（今日学习时长/完成量/正确率/薄弱点），
  **不暴露具体作答内容**，隐私最小化；
- 注意与 F1 一致：**报告默认不联网、不上传**。

**验收**
- 能生成一份可分享的周报（图片或文本），含趋势而非只有快照；
- 能导出结构化数据（JSON/CSV）用于外部查看；
- 家长视图不含题目原文，且默认本地生成。

---

### [ ] G4 · 云同步（决策项：**暂不实施**，需先做隐私评估）（P2）

**现状（证据）**
- 存档是**本地单文件** `user://users.json`（多用户在同一文件里），
  已有 `users.bak` 备份与原子写入；**没有任何网络同步**。
- 相关度：**F5**（存档版本化与进度导出/迁移）能先解决"换机丢进度"的**大部分**问题；
  **F1**（在线 TTS 已在把文本外发）说明项目的隐私边界尚未系统梳理。

**为什么暂不实施**
- 云同步意味着**把未成年人学习数据（作答记录、错题、掌握度）上传到服务器**，
  需要同步完成：隐私政策、监护人同意、数据最小化、加密与保留期、账号体系、
  以及服务端成本与运维——**这是一条产品级决策，不是一次功能迭代**。

**做法（若将来要做）**
1. 先做 **F5 的本地导出/导入**（覆盖大多数换机场景，零隐私成本）；
2. 再评估"**用户自有云**"方案（导出到网盘/分享给自己），绕开自建服务端；
3. 若确需自建：与 F1 一起做隐私评估，账号与学生数据分离存储，提供删除权。
- **保留现状的另一半价值**：无账号、无上传，本身就是隐私卖点，应写进商店文案。

**验收（决策）**
- 明确记录"做 / 不做 / 何时做"的结论与理由（写进本文件或 `docs/`）；
- 若不做：F5 完成 + 商店文案强调"数据全本地"。

---

### [ ] G5 · 音效与配乐（决策项：先确认是否**刻意不做**）（P2）

**现状（证据）**
- `audio/` 共 **11 个 wav**（约 270KB）：`begin / click / complete / correct / deal / error / hover / select / star / unlock / wrong`。
- `scripts/autoload/Sound.gd` 启动**预载**、按钮自动接线、支持 `.wav/.ogg/.mp3`（`EXTS`），
  有静音 `toggle()` 与音量设置（`Settings.sfx_volume`）。
- **完全没有背景音乐**：无 BGM 资源、无音乐播放逻辑、无音乐音量项。
- 音效覆盖是完整的（答对/答错/星星/解锁/点击/悬停…），**不是缺失，而是"没有 BGM"这一项**。

**为什么要先决策**
- 学习场景里 BGM 可能**干扰专注**，也可能是产品氛围的一部分；
- 移动端 BGM 涉及**耗电、后台播放策略、与其他音频（TTS 朗读）抢占焦点**——
  尤其 **B13 的朗读**与 BGM 会互相打断，需要优先级设计。

**做法（二选一）**
- **确认不做**：把"无 BGM"写进设计约定（并在设置项文案里不出现"音乐"），避免后续反复讨论；
- **要做**：按页面分层（首页/地图可有人声氛围；**关卡内默认静音或极轻**），
  音乐音量独立设置项，且**朗读开始时自动压低/暂停**；优先 `.ogg` 控制体积。

**验收（决策）**
- 明确结论：不做（记入设计约定）或做（含音量项、与 TTS 的优先级规则、体积评估）。

---

## 8. 历史遗留与已确认非问题（避免重复排查）

- `ans` 恒为 0 **不是漏答案**：运行时默认打乱选项（754 题仅 1 题关闭）。见 B8。
- 根目录 `*.log` / `衍数阁.pck` **不在版本库**（`.gitignore` 覆盖），`git status` 干净。见 A9。
- `project.godot` 的版本声明**已是 4.7**，漂移只存在于 `docs/环境配置.md` 的旧基线小节。见 A7。
- `line_levels.json` 有 4 轮无 `opts` 属**预期设计**（`type:"interact"` + `gate`），不是缺题。见 B1。

**第二轮排查已核实「不是问题」的项**（勿再当缺陷上报）：

- 存档 `.bak` **确实会被读取**：`GameData.gd:1662` `data = _read_users_file(USERS_BAK)`，
  不是「只写不读」的假备份。
- **Android 返回键已处理**：`scripts/autoload/Scene.gd:131-133` 监听 `NOTIFICATION_WM_GO_BACK_REQUEST`
  （配合 `quit_on_go_back=false`，返回键走应用内导航而非退出）。
- **关闭/暂停/失焦会落盘**：`GameData.gd:1689-1691` 监听
  `NOTIFICATION_WM_CLOSE_REQUEST / APPLICATION_PAUSED / APPLICATION_FOCUS_OUT`。
- `Settings.DEFAULTS["editor_mode"]` **已是 `false`**（`Settings.gd:26`），未泄漏编辑模式。
- `solid_methods.json` 的 6 个 method 与 `curriculum` 的 6 个立几方法关**一一对应，无孤儿 topic**。
- 「关卡数据存在但 curriculum 不引用」的告警里，`C1/C2/C3` 是**误报**：
  curriculum 用 `"conic": "C1"` 字段映射（非 id），`ConicStage.gd:61-65` 据此加载。

---

## 9. 验收与回归

### 9.1 改完必跑（四件套 + 新增）

| 命令 | 期望 |
|---|---|
| `--headless --path . --script res://tools/check_all.gd` | `CHECKED <N> scripts, 0 failures`（仅 `third_party/` 历史 Parse Error） |
| `--headless --path . res://tests/Tests.tscn` | `TESTS: <N> passed, 0 failed` |
| `--headless --path . res://tools/smoke_scene.tscn` | `SMOKE: <N> ok, 0 fail` |
| `--headless --path . res://tests/LabSmoke.tscn` | 末尾 `TMP_OK` |
| `--headless --path . --script res://tools/check_questions.gd`（**已完成，见 A5**） | `QUESTION-CHECK: … / 0 new / 0 problems`（存量记基线） |
| `--headless --path . res://tests/UiSmoke.tscn`（**新增，见 A11**） | `UI-SMOKE: … ok, 0 fail` |
| `--headless --path . --script res://tools/verify_inline.gd` | 末尾 `VERIFY_TABLE: total=<N> fail=0`（MicroTeX 渲染复验，改动 `res/` 或字体后必跑） |
| `--headless --path . --script res://tools/check_assets.gd`（**新增，见 A13**） | `ASSETS: <MB> MB … banned=0, oversize=0`（不得出现 `ASSETS-FAIL`） |
| `--headless --path . --script res://tools/check_knowledge.gd`（**新增，见 E1**） | `KNOWLEDGE: <c> chapters / <p> points / <l> levels mapped / hard-gaps=<n> (baseline <b>)`（不得出现 `KNOWLEDGE-FAIL`） |
| `--headless --path . res://tools/LevelPreview.tscn -- --smoke`（**新增，见 G2**） | `LEVEL-PREVIEW-SMOKE: <N> ok, 0 fail`（作者工具链：数据定位回归 + 编辑往返 + 舞台抽样） |

> 引擎：Godot 4.7.2（本机 `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`，
> 有 console 变体可直连控制台取输出；若换机只有无 console 的 GUI exe，需
> `Start-Process -Wait -RedirectStandardOutput/Error` 重定向（GUI 子系统进程直连控制台会丢输出）。
> 换机后的工具链安装与已知坑见 `docs/环境配置.md`。
>
> **换机首次打开**：必须先让 Godot 生成全局类缓存，否则 `class_name`（如 `BossHud`）会连锁报
> `Parse Error: Could not find type "BossHud"`。用编辑器打开一次，或跑
> `& "<godot472.exe>" --headless --editor --path . --quit`。

**当前回归基线**（改完请对照，数字只能升不能降；2026-10-20 B2 复数章 + 圆锥曲线章扩题后）：
`CHECKED 90 scripts, 0 failures` / `TESTS: 1245 passed, 0 failed` / `SMOKE: 285 ok, 0 fail` /
`UI-SMOKE: 340 ok, 0 fail`（取样漂移，见下方注）/ `LabSmoke` 末尾 `TMP_OK` /
`LEVEL-PREVIEW-SMOKE: 7305 ok, 0 fail`（G2 预览器自检：数据定位回归 + 编辑往返 + 舞台抽样）/
`QUESTION-CHECK: 26 files / 269 levels / 1026 questions / 0 new / 7 known / 3 warnings`
（A5 校验器，存量问题见下方基线；看板另有「干扰项黑名单命中 0 处」，见 B5）/
`ASSETS: 29.95 MB over 3100 files … banned=0, oversize=0`（A13 护栏）/
`KNOWLEDGE: 27 chapters / 275 points / 275 levels mapped / hard-gaps=0 (baseline 0) / optional=8`（E1 矩阵，E3#4/#5/#6 起硬缺口清零）/
`LATEX-PROBE: conic C4 68 / C5 76 / C6 68 段 / 0 失败`（E2 收官）、
`vector_physics 26 段 / 0 失败`、`prob_simulate 14 段 / 0 失败`（E3 收官；**探针需按组分进程**，
写法见 E2 的 MicroTeX 累积崩溃注：扫 `$$([^$]+)$$` 逐段调 `InlineMath._latex_bbcode(latex,26)`，
返回值**含** `[/img]` 即成功——注意方向别写反；探针用完即删）。

> 注：`UI-SMOKE` 的 ok 总数随关卡池大小**取样漂移**（`_pick` 均摊取样，LabStage 样本 193→196 时
> 第 2 个样本从 5 轮的 `stat_center` 换成 3 轮的 `prob_classic`，总数 −14）。它不是单调基线，
> 判据看 `fail=0`；新增关卡若要保持可比，可把 `_pick(scene, 3)` 的 n 调大。

- 校验器基线：`tools/check_questions_baseline.txt`（**7 条已知**：题干重复 7；B9 轮次编号错位已归 0）；
  `tools/knowledge_gaps_baseline.txt`（**0 条硬缺口**：集合基数 4→3→2、两角和差与二倍角
  2026-10-19 由 `trig_sumdiff`/`trig_double` 补齐 → 0，余下 gaps 仅 optional=true）。
- CI：`.github/workflows/check.yml`（push/PR 跑上面各条；`gdextension/bin/` 不入库 → 顺带回归 PNG 回退不崩）。

### 9.2 本文件基线数字（改完请同步更新）

- 题目总数 **1068**（关卡文件 1026 + `questions.json` 42）；关卡组 **269**；
  平均 **3.81 题/关**（`check_questions` 口径：1026 = 单选 813 + 多选 4 + 填空 209；无选项 `interact` 4 另计）。
- 题型分布（`check_questions.gd` 看板）：单选 **813**，多选 **4**，`interact` **4**，填空 **209**；
  非四选一占比 **21.1%**（B1 目标 ≥30%；B2 扩题时新增轮次一律用填空/多选/`interact`，可同步抬高此值）。
- 选项：图片选项 **114** 处（位于 36 道题）；`ans==0` **739/813（90.9%）**（B8 偏高；新题已刻意分散 ans 位置）。
- 探究轮 **273**，其中题面为陈述句 **0（0.0%）**（`check_questions.gd` 口径；B3 目标 <20%；原始人工口径 221/230）。
- 轮次标签编号错位 **0 处**（B9 已修复：`tools/fix_labels.gd` 批量重编，规范 `<关卡序号>-<轮次> <阶段名>`）。
- 资源体积（A13 已治理）：仓库 tracked 合计 **29.6MB**（治理前 48.4MB；`art/` 已无 `.xcf`，源文件移至 `assets_src/`，
  标题字体 13.5MB 待替换）；APK（debug）旧基线 **60.9MB**（新基线待重新导出）。见 A13。
- 知识点矩阵（E1 已建立，E2/E3 已补齐）：`data/knowledge_map.json` 27 章 / **275 个知识点**（每关一挂）；
  **硬缺口 0**、选学/旧课标 8（基线 `tools/knowledge_gaps_baseline.txt`；2026-10-19 两角和差/二倍角清零）；
  关卡 id `solid_angle` 跨章重名 1 处。见 E1/E2/E3。
- 数据一致性：`curriculum` 关卡 275 / 关卡数据组 269，`lab_ref` 动态映射覆盖其余；
  跨文件重名关卡数据 **5 组**（`questions.json` ↔ `set_logic_levels.json`，内容互不相同）。见 A12。
- 口播字段 `speak`：**0 处**。见 B13。
- 动效：`anim` 演示字段只出现在 **1/26** 个关卡文件（`solid_basic_levels.json`，27 处 / 12 关）；
  `Lab3DView.play_anim` 支持 7 种步骤（`highlight` 50 / `view` 38 / `reveal` 25 / `a` 22 / `vars` 21 / `rotate` 7 / `pulse` 4）；
  2D 侧无 `anim` 能力、滑块重绘无补间；`tween_property` 裸时长 **44 处**。见 D1~D4。
- 经济（C1/C2 已修复）：`grant_stars` 经验仅随星级提升发放；`settle_level` 首达全额、重复通关 ×0.3 且每日最多 3 次；
  同一关当日第 3 次尝试起星级上限降为 2（`Tests._test_anti_farm` 覆盖）。

### 9.3 审计数据的复现方法

本轮统计用一次性 Node 脚本完成（**未入库**，若需要建议按 A5 落成 `tools/check_questions.gd` 的 GDScript 版）：

1. 扫描范围：`data/*_levels.json`（26 个）+ `data/questions.json`；
2. 「一题」判定：对象同时含 `q` 与 `opts`；
3. 「一关」判定：顶层键下含 `levels[]` 数组；
4. 统计项：题量、选项数、`ans` 取值分布、选项是否图片（`res://*.png`）、
   题干长度/选项长度均值、`type` 取值、`hint/explain/success/ask` 覆盖率、
   轮次标签编号 vs 关卡序号、图片选项计数、题干重复。
