# TODO · 唯一待办清单

> **本文件是项目唯一的 TODO**。合并自原先四个文件：`TODO.md`（MicroTeX 公式运行时渲染，已 100% 完成）、
> `TODO-lab.md`（几何章节迁移到 LabStage，已完成）、`TODO-gamify.md`（关卡游戏化 P1/P2/P3，已交付）、
> `TODO-quality.md`（架构收敛 + 题目内容审计，本次新增）。
> **已完成条目与历史验收记录已清除**，需要追溯请看 `git log`（提交信息里带条目编号）。
>
> 本清单每条都带「现状证据 / 做法 / 验收」，**可跨机器续接**。
> 用法：按优先级从上往下做；每完成一项，在提交信息里引用条目编号（如 `fix(A1): 数列关卡迁移到 StageBase`），
> 并把该条打勾、同步更新第 5 节的基线数字。
>
> 已被清除的历史文件内容另有归宿，不受影响：
> - MicroTeX 工具链 / 已知坑（Error 126、`res.bin`、`user://` 中文路径等）→ `docs/环境配置.md`
> - 游戏化设计稿与数据 schema（`boss{}` / `rules{}` / `gate`/`chest`/`event`）→ `docs/关卡游戏化方案.md`
> - 架构与题目审计的原始数据 → 本文件第 5 节

---

## 0. 优先级总览

| 编号 | 标题 | 优先级 | 说明 |
|---|---|---|---|
| **A1** | `SequenceStage` 迁移到 `StageBase` | **P0** | 不修则新功能永久双轨 |
| **B1** | 题型单一：把 `interact/gate` 与填空题用起来 | **P0** | 决定产品定位 |
| **B3** | 「探究→建构→迁移」名不副实 | **P0** | 教学设计核心 |
| **B9** | 轮次标签编号错乱（纯编校，可脚本修） | **P0** | 成本最低、可立刻验证 |
| **C1** | 重复通关无限刷经验/金币 | **P0** | 经济系统已被绕过 |
| **C2** | 星级只升不降 + 免费重试 + 四选一 → 进度可刷 | **P0** | 与 C1 同批处理 |
| **A5** | 关卡 JSON 校验器（schema + 编校） | **P0** | B9/C 类问题的自动化防线 |
| **A10** | 公式来源单一化：新数据直接写 LaTeX | **P1** | 消除 824 条映射的隐性耦合 |
| **A2** | 遗留模块（`SolidChallenge` / `ConicStage`+C1~C3）定策略 | **P1** | 决定继续删还是冻结 |
| **A3** | `Battle.gd` 死代码处理 | **P1** | 614 行不再增长 |
| **A6** | CI（headless 四件套自动化） | **P1** | 现有脚本已就绪，成本极低 |
| **A11** | UI/交互层缺自动化断言（测试只盖纯逻辑） | **P1** | A1/B 类改动目前只能靠人眼 |
| **B2** | 每关题量 3 → 5~8 | **P1** | 掌握度信号太弱 |
| **B4** | 实验与追问不闭环 | **P1** | 探究轮形同虚设 |
| **B5** | 干扰项改为诊断性干扰项 | **P1** | 四选一实际是二选一 |
| **B6** | 选项过短、退化为结果核对 | **P1** | 概念性误解测不出来 |
| **B7** | 图片选项回归 LaTeX 文本 | **P1** | 180 处图片选项 |
| **B11** | 模块间质量方差过大 | **P1** | 同一品牌下深度差 3 倍 |
| **A4** | 上帝对象拆分（`GameData`/`StageBase`/`TheoremTree`） | **P2** | 趁还能读懂 |
| **A7** | 版本声明漂移（文档 vs `project.godot` vs GDExtension） | **P2** | 隐性风险 |
| **A8** | 「地图」隐喻套在清单结构上 | **P2** | 产品层，长期方向 |
| **A9** | 工作区残留（`*.log` / `*.pck`） | **P2** | 仅本地整洁 |
| **B8** | 正确项恒写在第 1 位（92.7%） | **P2** | 编校规范 |
| **B10** | 题干套路化与重复 | **P2** | 编校质量 |
| **B12** | 提示语泄露答案 | **P2** | 编校质量 |

---

## 1. A 类 · 架构与工程收敛

### [ ] A1 · `SequenceStage` 迁移到 `StageBase`（P0）

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

### [ ] A5 · 关卡 JSON 校验器（P0，B9/C 类的防线）

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

### [ ] A6 · CI（P1）

**现状（证据）**
- 仓库根目录**没有 `.github/`**；四件套只能手动跑（命令见第 5 节）。
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

### [ ] A7 · 版本声明漂移（P2）

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

### [ ] A9 · 工作区残留清理（P2）

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

---

### [ ] A11 · UI/交互层缺自动化断言（P1）

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

---

## 2. B 类 · 题目与内容质量

> 本节所有数字来自 26 个 `data/*_levels.json` + `data/questions.json` 的全量扫描，
> 口径与复现方法见第 5 节。**题数合计 754**（关卡文件 712 + 通用题库 42），**关卡组 222**。

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

### [ ] B5 · 干扰项改为诊断性干扰项（P1）

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

### [ ] B9 · 轮次标签编号错乱（P0，纯编校，可脚本修）

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

## 3. C 类 · 防刷与经济（跨 A/B）

### [ ] C1 · 重复通关无限刷经验/金币（P0）

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

### [ ] C2 · 星级只升不降 + 免费重试 + 四选一 → 全进度可刷（P0）

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

## 4. 历史遗留与已确认非问题（避免重复排查）

- `ans` 恒为 0 **不是漏答案**：运行时默认打乱选项（754 题仅 1 题关闭）。见 B8。
- 根目录 `*.log` / `衍数阁.pck` **不在版本库**（`.gitignore` 覆盖），`git status` 干净。见 A9。
- `project.godot` 的版本声明**已是 4.7**，漂移只存在于 `docs/环境配置.md` 的旧基线小节。见 A7。
- `line_levels.json` 有 4 轮无 `opts` 属**预期设计**（`type:"interact"` + `gate`），不是缺题。见 B1。

---

## 5. 验收与回归

### 5.1 改完必跑（四件套 + 新增）

| 命令 | 期望 |
|---|---|
| `--headless --path . --script res://tools/check_all.gd` | `CHECKED <N> scripts, 0 failures`（仅 `third_party/` 历史 Parse Error） |
| `--headless --path . res://tests/Tests.tscn` | `TESTS: <N> passed, 0 failed` |
| `--headless --path . res://tools/smoke_scene.tscn` | `SMOKE: <N> ok, 0 fail` |
| `--headless --path . res://tests/LabSmoke.tscn` | 末尾 `TMP_OK` |
| `--headless --path . --script res://tools/check_questions.gd`（**新增，见 A5**） | `QUESTION-CHECK: … / 0 problems` |
| `--headless --path . res://tests/UiSmoke.tscn`（**新增，见 A11**） | `UI-SMOKE: … ok, 0 fail` |

> 引擎：Godot 4.7.2（`D:\Program Files\Godot_v4.7.2-stable_win64.exe`）。该 exe 无 console 变体，
> 无头运行需 `Start-Process -Wait -RedirectStandardOutput/Error` 重定向取输出（GUI 子系统进程直连控制台会丢输出）。
> 换机后的工具链安装与已知坑见 `docs/环境配置.md`。
>
> **换机首次打开**：必须先让 Godot 生成全局类缓存，否则 `class_name`（如 `BossHud`）会连锁报
> `Parse Error: Could not find type "BossHud"`。用编辑器打开一次，或跑
> `& "<godot472.exe>" --headless --editor --path . --quit`。

**当前回归基线**（改完请对照，数字只能升不能降）：
`CHECKED 79 scripts, 0 failures` / `TESTS: 1220 passed, 0 failed` / `SMOKE: 238 ok, 0 fail` / `LabSmoke` 末尾 `TMP_OK`。

### 5.2 本文件基线数字（改完请同步更新）

- 题目总数 **754**（关卡文件 712 + `questions.json` 42）；关卡组 **222**；
  平均 **3.21 题/关**（若按轮次算含 716 轮，即 **3.23 轮/关**，其中 4 轮为无选项的 `interact`）。
- 题型分布：四选一 **752**，多选 **2**，`interact`/`gate` **4**。
- 选项：图片选项 **180** 处（位于 54 道题）；`ans==0` **699/754（92.7%）**。
- 探究轮 **230**，其中题面为陈述句 **221（96%）**。
- 轮次标签编号错位 **约 260 处**（跨 9 个文件，见 B9 表）。
- 经济：`grant_stars` 每次 `+10n` 经验；`add_coins` 每次发全额。

### 5.3 审计数据的复现方法

本轮统计用一次性 Node 脚本完成（**未入库**，若需要建议按 A5 落成 `tools/check_questions.gd` 的 GDScript 版）：

1. 扫描范围：`data/*_levels.json`（26 个）+ `data/questions.json`；
2. 「一题」判定：对象同时含 `q` 与 `opts`；
3. 「一关」判定：顶层键下含 `levels[]` 数组；
4. 统计项：题量、选项数、`ans` 取值分布、选项是否图片（`res://*.png`）、
   题干长度/选项长度均值、`type` 取值、`hint/explain/success/ask` 覆盖率、
   轮次标签编号 vs 关卡序号、图片选项计数、题干重复。
