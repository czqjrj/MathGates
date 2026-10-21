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
| **B1** | 题型单一：把 `interact/gate` 与填空题用起来 | **P0** | 🟡 非四选一 **21.4%**（目标 ≥30%）；填空题已落地 + 题型看板，26/26 章已扫描改写；纯数值转换已到上限，余下需内容重设计。**2026-10-20 起暂缓，先做结构收敛** |
| **B3** | 「探究→建构→迁移」名不副实 | **P0** | 🟡 26/26 章探究轮题面已改写（陈述句 0.0%，验收①达标）；建构/迁移轮深化待续 |
| **B9** | 轮次标签编号错乱（纯编校，可脚本修） | **P0** | ✅ 已完成（`fix_labels.gd`，错位归 0） |
| **C1** | 重复通关无限刷经验/金币 | **P0** | ✅ 已完成（经验仅星升；重复奖励×0.3/日封顶） |
| **C2** | 星级只升不降 + 免费重试 + 四选一 → 进度可刷 | **P0** | ✅ 已完成（当日第 3 次起星级上限 2） |
| **A5** | 关卡 JSON 校验器（schema + 编校） | **P0** | ✅ 已完成（`check_questions.gd` + 基线） |
| **A10** | 公式来源单一化：新数据直接写 LaTeX | **P1** | 🟡 已支持 `$$…$$` 直写 LaTeX（`InlineMath` + 校验器已适配）；旧 `{f:}` 兼容，待存量迁移 |
| **A2** | 遗留模块（`SolidChallenge` / `ConicStage`+C1~C3）定策略 | **P1** | ✅ 已完成（2026-10-21 第二十三轮 `43a11f9` **收编路线**：README 标官方场景 + 文件名↔章节对照表 + `_test_legacy_binding` 13 断言 + UiSmoke 数据载入断言 + 文件头状态标注；迁移到 LabStage 列为长期项） |
| **A3** | `Battle.gd` 死代码处理 | **P1** | ✅ 已完成（2026-10-20 与 A12 合并清理：删除 `Battle.gd` 688 行 + `Battle.tscn`；缺 scene 兜底改为报错/跳回主界面） |
| **A6** | CI（headless 四件套自动化） | **P1** | ✅ 已完成（`.github/workflows/check.yml`） |
| **A11** | UI/交互层缺自动化断言（测试只盖纯逻辑） | **P1** | ✅ 已完成（`tests/UiSmoke`：342 断言 + 反向验证 + 入 CI） |
| **A12** | `questions.json` 变成第二份权威题库（与现行数据冲突） | **P1** | ✅ 已完成（2026-10-20 随 A3 删除：`questions.json` 42 题 + `questions_for()`；跨文件重名 5→0，校验器已兜底） |
| **A13** | 资源体积治理（`.xcf` 入库、13.8MB 字体、未排除） | **P1** | 🟡 部分完成（`.xcf` 出库 + 图标降采样：46.8→29.6MB；残留：字体替换/背景压缩） |
| **A14** | `export_presets.cfg` 残留第三方机器路径 | **P1** | ✅ 已完成（统一 `build/…`） |
| **A15** | 元游戏内容硬编码在 `GameData.gd` | **P2** | 与「改内容只改 JSON」相悖 |
| **A16** | 立几方法关内容在 GDScript（两套内容管线） | **P2** | 🟡 前提部分失效：题目已迁至 `data/solid_methods.json`；`scripts/modules/solid/topics/*.gd`（6 文件 3568 行）现为**纯几何/标注逻辑**（问号 0~1 处、无题干）→ 降级为「3D 场景代码与数据的分层整理」 |
| **A17** | 数据文件命名易混（`conic`/`conics`、`vector`/`vectors`） | **P2** | 🟡 两步已落一（2026-10-21）：`463d06e` 校验器自检（孤儿/近名对半引用即红灯+反向验证）、`43a11f9` README 对照表；余「真重命名」为可选决策（两对文件均在用，重命名收益低） |
| **A18** | 内容数据异常时缺用户可见兜底 | **P1** | ✅ 已完成（2026-10-21 第三十五轮 `rules/ContentHealth.gd` 体检 + `ui/ContentFallback.gd` 兜底卡/横幅 + `tools/check_content_health.gd` CI 闸门；顺带修真 bug：关卡 id `solid_angle` 被两章共用） |
| **A19** | 多用户切换的会话状态残留 | **P2** | 切用户丢萌宠问候 |
| **B2** | 每关题量 3 → 5~8 | **P1** | 🟡 下限全线达标（2026-10-20：27/27 章 ≥ 5.0 题/关，全库平均 3.93；上探 6~7 题/关中段待续）。**2026-10-20 起暂缓，先做结构收敛** |
| **B4** | 实验与追问不闭环 | **P1** | 探究轮形同虚设 |
| **B5** | 干扰项改为诊断性干扰项 | **P1** | ✅ 已完成（2026-10-20 收官：黑名单校验器 + 42 轮整改 + 抽检 30 题；`tools/sample_distractors.gd`） |
| **B6** | 选项过短、退化为结果核对 | **P1** | 概念性误解测不出来 |
| **B7** | 图片选项回归 LaTeX 文本 | **P1** | 180 处图片选项 |
| **B11** | 模块间质量方差过大 | **P1** | 同一品牌下深度差 3 倍 |
| **A4** | 上帝对象拆分（`GameData`/`StageBase`/`TheoremTree`） | **P2** | ✅ 已收口（2026-10-21 第二十五轮 `7b4f8be`）：九刀拆出规则层七文件 696 行，三文件 4725→4311 行；行数红线进 `check_all`（超限即红灯）+ README「代码结构红线」；全程无行为变化、九件套绿 |
| **A7** | 版本声明漂移（文档 vs `project.godot` vs GDExtension） | **P2** | ✅ 已完成（文档基线 + 版本策略已记录） |
| **A8** | 「地图」隐喻套在清单结构上 | **P2** | 产品层，长期方向 |
| **A9** | 工作区残留（`*.log` / `*.pck`） | **P2** | ✅ 已完成（已清理） |
| **B8** | 正确项恒写在第 1 位（92.7%） | **P2** | 编校规范 |
| **B10** | 题干套路化与重复 | **P2** | 编校质量 |
| **B12** | 提示语泄露答案 | **P2** | 编校质量 |
| **B13** | 朗读/无障碍路径不完整且双路径不一致 | **P1** | 🟡 第一步完成（2026-10-21 `94b3acb`：双路径统一走 SpeechRules 转换器，盲点命令 5→0，口播看板进 check_questions）；余人工抽检听感 |
| **D1** | 2D 探究器无过渡动画（拖动=瞬时跳变） | **P1** | ✅ 已完成（2026-10-21）：`LabPlane` 加补间（τ=0.13s）+ 起点残影 + 动点轨迹三层；直接拖拽（分界线/拖点）保持跟手；`Tests._test_plane_motion` 证明中间态存在 |
| **D2** | 演示动画只覆盖 1/26 个关卡文件 | **P1** | ✅ 已完成（2026-10-21）：3D 补 `space_levels` 19 轮；`LabPlane` 新增 2D 播放器 + `LabStage` 演示按钮；2D 补 11 文件 → **13/26**；顺带修收尾帧跳帧 bug、加 `_test_anim_player` 防线 |
| **D3** | 动效全在"结果反馈"，缺"理解型动效" | **P1** | ✅ 已完成（2026-10-21）：`delta_highlight`（读数差量 + ▲/▼）/ `trace`（轨迹）/ `pulse_at`（`pulses`）/ `link_line`（`links` 流动虚线）；椭圆・函数与分段・导数三章试点；README 登记「装饰 vs 表意」语义 |
| **D4** | 动效令牌缺失 + 演示不可控 + 无障碍粒度不足 | **P2** | ✅ 已完成（2026-10-21）：`UI.DUR_*` 8 令牌收敛 47 处、裸时长 0（`check_all` 拦截+反向验证）；2D/3D 演示可暂停/重播/单步；新增「减弱动效」档，表意动效不受开关影响 |
| **E1** | 知识点覆盖矩阵 + 校验器（内容补全的前置） | **P0** | ✅ 已完成（`data/knowledge_map.json` + `check_knowledge` → `docs/知识点覆盖矩阵.md`；硬缺口基线随 E2 收敛，现 2 条） |
| **E2** | 补齐薄弱章节题量（8 章 ≤4 关，最少仅 6 题） | **P0** | ✅ 已完成（2026-10-19）：27 章全部 ≥6 关（知识章 9 章 + 方法章 `function_methods`、`conic` 各补齐到 6 关）；薄弱章节 **11 → 0** |
| **E3** | 补全 15 个整块缺失的教材必学知识点 | **P1** | ✅ 已完成（13 条落成关卡，#1/#11 用户判定教材已删跳过；末两条 `vector_physics`/`prob_simulate` 2026-10-20 收官） |
| **E4** | 方法章/专题章过薄且与知识章脱节 | **P2** | 🟡 function_methods、conic 均已 1→6（2026-10）；余 `thinking` 专题章与知识章引用关系待强化 |
| **E5** | 与 6 版教材对齐的持续核对流程 | **P1** | 换版本只改排序不改覆盖 |
| **F1** | 在线 TTS 的合规与稳定性（外发题目文本） | **P0** | ✅ 客户端策略完成（默认关闭+明示同意+隐私政策）；官方 API/商店表单并入 F2 |
| **F2** | 发布准备（包名/版本/签名/targetSdk） | **P0** | ✅ 包名=cn.edu.mathgates、版本脚本、targetSdk35、签名位就绪；残留 keystore/真机 |
| **F3** | 性能与耗电（3D 视口与背景常驻开销） | **P1** | ✅ 已完成（2026-10-21）：3D 空闲 8s 停自转/10s 停渲染、后台停帧；2D 改按需重绘；`perf_probe` 基线（静止 73ms → 0.26ms/帧）；真机功耗仍需实机 |
| **F4** | 桌面端键盘操作（主流程完全缺失） | **P1** | ✅ 已完成（2026-10-21）：`KeyNav` autoload（数字选项/Enter 三级优先/焦点环/H/WASD 视角）；`StageBase` 零改动；单测 18 条 + 真实 LabStage 冒烟 |
| **F5** | 存档版本化与进度迁移（换机即丢） | **P2** | 无导出/导入 |
| **F6** | 首次引导与机制说明 | **P2** | 无 tutorial |
| **F7** | 授权与第三方声明缺失（LICENSE / 素材来源 / 教材改编） | **P0** | ✅ LICENSE+第三方声明齐备、排除 GPLv3 字体；残留：标题字体替换/素材签字 |
| **G1** | 错题间隔重复（SRS 遗忘曲线排程） | **P1** | ✅ 已完成（2026-10-21 第三十三轮）：Leitner 阶梯 1/3/7/16/35 + 日序号到期 + 连对 4 次毕业 + 今日待复习入口（首页「复习 N」/错题本卡片）；旧档无排程视为立即到期 |
| **G2** | 关卡作者工具链（编辑器 + 实时预览） | **P1** | 🟡 预览器 + 脚手架已落地（`LevelPreview.tscn` + `scaffold_level.gd`，入 CI）；编辑态仅覆盖 q/ask/opts/ans/hint/explain/scene |
| **G3** | 学习报告 / 家长视图（可导出、含趋势） | **P2** | ✅ 已完成（2026-10-21 第三十四轮）：活动日志按天累积（保留 120 天）+ 逐日趋势柱状 + 周报/月报文本 + CSV/JSON 本地导出 + 家长只读摘要（**不含题目原文**，默认不联网）；同轮拆存档层 `rules/UserStore.gd`，GameData 1593 → 1558 行 |
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

- **最后提交**：`12df3c2`（`feat(A18)` 内容数据体检 / 用户可见兜底）；前一提交链：
  `6abe822`（docs ASSETS 口径）→ `3029ee8`（docs 第三十四轮）→ `0d5cde4`（feat G3 学习报告）→
  `8fdc5f0`（feat G1 错题间隔重复）→ `a885756`（docs 第三十三轮）→
  `28a235f`（docs 第三十二轮）→ `b6e98d9`（F3 静止降耗）→…，
  已 push（`main` 与 `origin/main` 同步）。
- **本轮交付（2026-10-21，第三十五轮）**：**A18 内容数据体检 / 用户可见兜底**（`12df3c2`）。
  - **体检规则**：`rules/ContentHealth.gd`（122 行，纯规则：不读文件、不碰 autoload，
    入参 = 章节数组 + 已知场景集合 + 内容组键表）。七种问题码
    `E_EMPTY`/`E_DUP_ID`/`E_NO_LEVEL`/`E_NO_TITLE`/`E_NO_SCENE`/`E_BAD_REF`/`E_LOAD`，
    `MESSAGES` + `describe()` 让 **UI 文案与 CI 输出共用一套**，不再两处各说各话。
  - **运行时（轻量）**：`GameData._load_curriculum()` 失败时写 `content_problems`
    （不再只有 `push_error`），成功后跑一次 `ContentHealth.check(chapters)`；
    门面 `content_ok()` / `content_health()` / `reload_content()`。
    只遍历课程表（O(关卡数) 纯字典操作），**不打开** 26 个 `*_levels.json`，启动开销可忽略。
  - **兜底界面**：`ui/ContentFallback.gd` —— `card()`（人话说明 + 最多 5 条明细 +
    「重试加载」/「复制错误信息」）、`banner()`（主城顶部一句话）、`fill(root)`（铺页）。
    `TheoremTree` 的 `chapters.is_empty()` 从**静默 return** 改为铺兜底卡；
    `MainHub._build_center()` 内容不健康时挂横幅。详情只写本地剪贴板（同 F1 隐私）。
  - **发版闸门**：`tools/check_content_health.gd`（深度：`ResourceLoader.exists` 场景、
    引用定位到组键、孤儿组提示）→ `.github/workflows/check.yml` 新增一步
    （`CONTENT-HEALTH-FAIL` 即红灯）+ `build/run_checks.ps1` 增 `content` 一档。
    本仓库没有自动导出步骤，CI 即「导出前那一次调用」。
  - **顺带修真 bug**：体检首次运行即报 `E_DUP_ID solid_angle` ——`solid` 章「线面角 · 二面角」
    与 `solid_basic` 章「11-1 空间角（几何法）」**共用同一个关卡 id**；星标按 id 存 →
    两关共用一条记录（一关通关另一关跟着亮），`level_name()` 也会取错名字。
    后者改名 `solid_basic_angle`（`lab_ref` 保持 `solid_angle` 不变，
    `data/knowledge_map.json` 与覆盖矩阵同步）。**id 全局唯一已被单测守住**。
  - **测试**：`Tests._test_content_health`（24 断言）+ `UiSmoke._test_content_fallback`（11 断言，
    含「铺页替代空白页」）。
  - **验收实测**：把 `data/curriculum.json` 写成非法 JSON → `content_ok=false` / `chapters=0` /
    `E_LOAD 课程表格式损坏`；还原后 `reload_content()` → `true` / 23 章。
    （「重置内容缓存」未按字面实现：内容是 `res://` 只读，没有可重置的缓存 →
    改为语义正确的「重试加载」+「复制错误信息」，理由记在 §7 A18。）
  - 全量回归绿：`CHECKED 108`（+3 脚本）/ `TESTS 2000`（+24）/ `SMOKE 286` /
    `UI-SMOKE 416`（+11）/ `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` /
    `QUESTION-CHECK 0 new（7 known）` / `KNOWLEDGE hard-gaps=0` /
    `CONTENT-HEALTH 27 chapters / 275 levels / 0 problems (orphans=0)` /
    `ASSETS 30.24 banned=0`。
  - **A18 转 ✅**；⚠️ 行数余量提醒：`GameData 1579/1600`（余 21）、
    `TheoremTree 1544/1550`（余 6）、`StageBase 1197/1200`（余 3）——
    **下一轮若再碰这三个文件，必须先拆纯规则**。
  - **下一项建议**：**A19**（多用户切换的会话状态残留，小而完整）或
    **A10 的存量迁移**（剩余 24 处 `{f:}` 在 `function_lab_levels.json`，脚本化可做）；
    `StageBase 1197/1200` 应优先拆（余量只剩 3 行）。
- **上一轮（第三十四轮）**：**G3 学习报告 / 家长视图**（`0d5cde4`）。
  - **先还 A4 欠账——存档层拆分**：新增 `rules/UserStore.gd`（140 行）接管存档 dict ⇄ 运行时字段的
    全部转换（`blank_user` / `snapshot` / `parse` / `normalize_wrong_modules`），
    `GameData.gd` 只剩 `_state()` / `_avatar_ids()` 两个薄门面 → **1593 → 1558 行**（红线 1600，余 42）。
    顺手补**脏档兜底**（字段缺失 / `null` / 类型不对 → 默认值）：原实现遇到显式 `null` 会在
    `int(null)` 处整段中止（实测存档直接读成空字典）。
  - **新增时间维度（趋势的前提）**：新存档字段 `activity`，按天一条
    `{date, answered, correct, stars, clears, reviews}`，**保留 120 天**（更早裁掉，存档不无限膨胀）；
    埋点 `record_answer`（answered/correct）、`grant_stars`（星级净增）、
    `record_level_result`（clears）、`_srs_answer`（此前已在复习计划里的题才记 reviews）。
  - **规则分层（守 A4 红线）**：`rules/ReportRules.gd`（150 行：日历日换算 / 活动日志 / 汇总 /
    领域级薄弱点 / 家长视图）+ `rules/ReportExport.gd`（54 行：文本周报 / 家长建议 / CSV / JSON），
    `GameData` 只留**门面**（`report_summary` / `report_weak` / `parent_view` / `parent_advice` /
    `report_text` / `report_csv` / `report_json`）。日期换算按 **UTC 解释的纯日历日**，
    不随时区/夏令时漂移。
  - **界面**：新增 `scenes/LearningReport.tscn` + `scripts/screens/LearningReport.gd`（280 行）——
    学习概览 → **逐日趋势柱状**（沉默的日子也画出来）→ 薄弱领域 → 可分享的报告文本（复制剪贴板）
    → 家长视图只读摘要 → 导出（CSV / JSON / 文本，写到 `user://`）；
    入口：首页顶栏「报告」+ 档案库「学习报告 · 家长视图」卡片；`Scene.SCENE_LABELS` 登记「学习报告」。
  - **隐私最小化（与 F1 一致）**：家长视图只给**汇总量 + 领域级薄弱点名**，不含题目原文 /
    关卡名 / 作答内容；报告**默认本地生成、不联网、不上传**；导出内容只有日期与计数。
  - **测试**：`Tests._test_user_store` / `_test_report_rules` / `_test_report_flow`（+76 断言）+
    `UiSmoke._test_report_screen`（报告页**真实构建** + 周期切换切到 30 天 + 导出按钮 + 隐私说明，+12）+
    `smoke_scene` 新增 `LearningReport.tscn`（285 → 286）。
  - 全量回归绿：`CHECKED 105` / `TESTS 1976`（+76）/ `SMOKE 286` / `UI-SMOKE 405`（+12）/
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new（7 known）` /
    `KNOWLEDGE hard-gaps=0` / `ASSETS 30.20 banned=0`。
  - **G3 转 ✅**；⚠️ 残留：「复习完成率」「错题净增」「薄弱领域环比变化」三项**未单列**
    （复习量按「进入复习计划的题数」计，非到期完成率；薄弱点取的是当前诊断快照，非周期变化量）——
    要补得给 `srs_plan` 与错题账加「上周期领域分布」快照，属独立一轮。
  - **下一项建议**：**G2（关卡作者工具链）**——预览器 `LevelPreview.tscn` 与脚手架
    `tools/scaffold_level.gd` 已落地且入 CI，还差**编辑闭环**（改完即存盘 + 校验）；
    或 **A10 / A18 / A19**（纯 AI 可自动化）。
    同时继续按 A4 拆 `StageBase.gd`（1195/1200，余 5 行）与 `TheoremTree.gd`（1541/1550，余 9 行）。
- **上一轮（第三十三轮）**：**G1 错题间隔重复（SRS 遗忘曲线排程）**（`8fdc5f0`）。
  - **阶梯**：Leitner 5 档 `1/3/7/16/35` 天（`SrsRules.INTERVALS`），`step` 0→4；答对进阶、
    答错回退到 0 并重排 `due_day`；连对 `GRADUATE_OK=4` **毕业**（移出排程，进 `wrong_log` 归档）。
  - **日期用「日序号」不用时间戳**：`GameData.today_day()` 取本地日历日序号（`Time` 零时化后 ÷86400），
    避开时区/夏令时漂移；奖励去重另用日期串 `last_reward_day`。
  - **规则分层（守 A4 红线）**：`rules/SrsRules.gd`（113 行）只算单条排程，
    `rules/SrsStore.gd`（177 行）管整本排程（存/查/推进/迁移/排序/派单），
    `GameData` 只留**门面**（`srs_due_list` / `srs_due_count` / `srs_due_text` / `srs_plan_for` /
    `review_order` / `pet_quests`），行为零变更。
  - **兼容**：`srs_plan` 与旧 `wrong_log` **并存**；旧档无排程者由 `SrsStore.legacy_plan()`
    合成 `due_day = 0` 的「立即到期」计划 → 零迁移、天然兼容；`normalize()` 钳制越界字段。
  - **即时复练语义保留**：今天刚做错的题 `eff_due_day = 今天`（不是明天）→「错题优先」不被推迟。
  - **奖励**：复习答对 `+2`（同题当日只发一次，防刷）、毕业 `+5`；旧「答对清错账」的 `+5`
    提为常量 `GameData.WRONG_CLEAR_COINS`（语义不变）。
  - **入口**：首页顶栏「复习 N」（今日无到期则隐藏）+ 首页「待复习 N」卡片角标 + 错题本
    「今日待复习」卡片（按到期排序 + 一键「开始复习」深链到题号）+ 每条错题标注
    「今天到期 / N 天后复习 / 已逾期 N 天」；萌宠派单也改为到期优先。
  - **测试**：`Tests._test_srs_rules` / `_test_srs_store` / `_test_srs_flow`（+96 断言）+
    `UiSmoke._test_srs_review_entry`（首页与错题本**真实构建** 8 断言）。
  - 全量回归绿：`CHECKED 101` / `TESTS 1900`（+96）/ `SMOKE 285` / `UI-SMOKE 393`（+8）/
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` /
    `KNOWLEDGE hard-gaps=0` / `ASSETS 30.15 banned=0`。
  - **G1 转 ✅**；⚠️ `GameData.gd` 已到 **1593/1600**，下轮动它先拆存档层（见 §7 G1 的 A4 遗留注）。
- **上一轮（第三十二轮）**：**F3 性能与静止降耗**（`b6e98d9`）。
  - **3D**：空闲 8s 停自转、相机稳且空闲 10s → `SubViewport.UPDATE_DISABLED`（保留末帧）；
    停帧后 `_process` early-return；`_wake()` 在拖动/键盘/演示/换场景时立即恢复；
    前后台（PAUSED/FOCUS_OUT）停帧、恢复时重启。
  - **2D（额外发现）**：`LabPlane._process` 原本**无条件 `queue_redraw()`**——静止也在重绘。
    改为按需：入场显现/演示/补间/残影/轨迹/脉冲/流动虚线/拖拽才重画；新增 `redraw_count` 供断言。
  - **TechBg**：动效关闭或后台时 `set_process(false)`（不再每帧空转判断），由设置变化/恢复通知拉起。
  - **基线工具**：`tools/perf_probe.tscn`（headless 可跑）输出 `PERF <case> proc_avg_us …`；
    3D 预热 1700 帧确保已停帧。
  - **实测**：`lab_plane` 静止 **73,430 → 259 µs/帧**；`lab3d` 静止 **70,262 → 251 µs/帧**；
    `idle` 基线 171 µs（headless CPU 处理耗时）。
  - **测试**：`Tests._test_idle_power`（10 断言：自转 8s 停、10s 停渲染、唤醒、后台停/前台恢复、
    TechBg 停/启、2D 静止 20 帧不重绘且变化时恢复）。
  - 全量回归绿：`CHECKED 99` / `TESTS 1804`（+10）/ `SMOKE 285` / `UI-SMOKE 385` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` /
    `KNOWLEDGE hard-gaps=0` / `ASSETS 30.11 banned=0`。
  - **F3 转 ✅**；Android 真机 FPS/功耗/内存仍需真机（headless 无 GPU），已在条目标 🟡。
- **上一轮（第三十一轮）**：**F4 桌面端键盘操作**（`1bd050c`）。
  - 新增 `scripts/autoload/KeyNav.gd` 并注册 autoload：只处理 `_unhandled_key_input`，
    输入框与按钮默认激活不受影响；核心逻辑为 `static func handle(stage, keycode)`，测试可直接驱动。
  - **鸭子类型**取 `_opt_btns/_next/_hint/_kb_confirm/_view3d` → **`StageBase` 零改动**
    （1195/1200 红线不动，无需上调上限）。
  - 键位：`1..9` 选项（同一 `pressed` 回调）、`Enter` 三级优先（确认 → 下一关 → 焦点按钮）、
    `←/→/↑/↓` 焦点环、`H` 提示、`W/A/S/D` 3D 视角、`Esc`/`M` 沿用全局。
  - `Lab3DView.key_pan()` 与鼠标拖动共用 `yaw_goal/pitch_goal`（pitch 夹 ±1.35）。
  - 舞台接线各 2 行：`LabStage`/`Lab3DStage` 把「确认」按钮挂到 `_kb_confirm`，`_load_q` 置空。
  - 测试：`Tests._test_keyboard_nav`（18 断言）+ `UiSmoke._test_keyboard_stage`（真实 LabStage 断言）。
  - 全量回归绿：`CHECKED 98` / `TESTS 1792` / `SMOKE 285` / `UI-SMOKE 385` / `LabSmoke TMP_OK` /
    `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` / `KNOWLEDGE hard-gaps=0` / `ASSETS 30.10 banned=0`。
  - **F4 转 ✅**；焦点顺序是否符合直觉建议 Windows 版上手过一遍（已标 🟡）。
- **上一轮（第三十轮）**：**D4 动效令牌与控制语义**（`aca0897`）——D 类收官。
  - **令牌**：`UI.DUR_TINY/FAST/NORMAL/SLOW/XSLOW/LONG/SCENE/AMBIENT`（0.08→1.7）、
    `EASE_STD/EMPHASIS/SOFT` 与 `UI.ease(tw)`；语义上「时长只有一个来源」。
  - **收敛 47 处**（14 文件）：脚本化只改 `tween_property` 的第 4 实参与 `_scale_to` 的第 3 实参，
    含 3 处 `_scale_to` 与 `MainHub` 的 1.7s 环境律动。
  - **静态防线**：`check_all._check_bare_durations()` 用括号深度扫描取顶层实参，
    裸数字即 `BARE-DURATION`；**反向验证**（Toast 改回 0.14 → 1 failures，恢复 → 0）。
  - **演示控制**：`Lab3DView`/`LabPlane` 均补 `pause/resume/toggle/restart/step`，
    暂停时 `_process` 不推进时间轴；3D 工具条「⏸/↻/⏭」，2D 右上角「↻」+ 主按钮切换暂停/继续。
  - **开关拆两层**：`UI.fx_on() = animations and not reduced_motion` 只管**装饰**动效；
    设置新增**「减弱动效」**档（`Settings.reduced_motion`，持久化）；
    **表意动效（补间/差量/轨迹/脉冲）不读这两个开关**。
  - **测试**：`_test_motion_tokens` / `_test_reduced_motion` / `_test_demo_controls`（+14 断言）；
    全量回归绿：`CHECKED 97` / `TESTS 1774` / `SMOKE 285` / `UI-SMOKE 383` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` /
    `KNOWLEDGE hard-gaps=0` / `ASSETS 30.09 banned=0`。
  - **D 类 4/4 全部 ✅**（D1 补间+残影+轨迹、D2 演示覆盖 13/26、D3 四个表意原语、D4 令牌/控制/开关）。
- **上一轮（第二十九轮）**：**D3 理解型动效**（`439d685`）。
  - **`delta_highlight`（全局自动）**：变化期间用**旧参数重算同一 `readouts` 表达式**比对，
    变了就画高亮条 + ▲/▼ 三角（`draw_colored_polygon`，不赌字体字形）。
  - **`trace`（全局自动）**：D1 动点轨迹，正式登记为表意原语。
  - **`pulse_at`**：数据键 `pulses`，**停稳后**扩散圆环 + 实心点 + 标签，1.2/s 淡出。
  - **`link_line`**：数据键 `links`，相位流动虚线（`fmod(_t*16, dash+gap)`）+ 端点 + 标签。
  - **三章试点**：椭圆 1-1 画 \|OP\|（对照「到焦点距离之和恒定，到中心距离却在变」）；
    函数与分段 3-1 脉冲最低点 `(0,b)`；导数 2-1 脉冲切点 `(1,1)`。
  - **文档**：`README.md` 新增「动效清单：装饰 vs 表意」小节（9 个 Vfx + 6 个表意原语 + 开关语义），
    为 D4 的「表意动效不跟随装饰开关」定调。
  - **顺手修**：`_draw_readouts` 默认标签 mojibake `"ֵ"` → `"值"`。
  - **测试**：`_test_plane_motion` 扩到 16 断言（delta 差值、pulse 触发与结束、
    全库 `links`/`pulses` 端点二元数组校验、试点数量下限）。
  - 全量回归绿：`CHECKED 97` / `TESTS 1760`（+8）/ `SMOKE 285` / `UI-SMOKE 383` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` /
    `KNOWLEDGE hard-gaps=0` / `ASSETS 30.08 banned=0`。
  - **D3 转 ✅**；「学生能否看懂因果」需真人试看后回填（已在条目里标 🟡）。
- **上一轮（第二十八轮）**：**D1 2D 过程表达**（`0711bbf`）。
  - **补间**：`LabPlane` 新增 `_disp` 显示值层，`_process` 内按 `TWEEN_TAU=0.13s` 指数缓动
    （`1-exp(-dt/τ)`，帧率无关）；`_ex_var()` 优先读显示值 → 几何与读数连续变化；
    到位后精确对齐。演示与手拖共用同一通道。
  - **残影**：变化起点快照 `_ghost_disp`，以 0.55→0 透明度重绘旧图形（`_c()` 统一乘 alpha；
    点/向量/标签在残影模式跳过，避免重影）。
  - **轨迹**：变化期间每帧记录 `points` 屏幕坐标（≤14 帧），1.6/s 淡出。
  - **边界**：`begin_break`（分界线）与 `begin_drag`（拖点）是直接操作，清空 `_disp` 保持跟手。
  - **测试**：`Tests._test_plane_motion`（8 断言：中间态严格居中 / 残影激活 / 轨迹非空 /
    精确到位 / 自动淡出 / 换场景清零）；`UiSmoke` 加「演示按钮可见性 + 能启动播放器」（369 → 383）。
  - 全量回归绿：`CHECKED 97` / `TESTS 1752`（+8）/ `SMOKE 285` / `UI-SMOKE 383` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new`（anim 13/26）/
    `KNOWLEDGE hard-gaps=0` / `ASSETS 30.07 banned=0`。
  - **D1 转 ✅**；「像素级截图抓帧」改为状态级中间态断言（headless 取像素不可靠），
    像素观感留人工目视一次。
- **上一轮（第二十七轮）**：**D2 演示动画补齐（1/26 → 13/26）**（`110b0a3`）。
  - **3D**：`space_levels.json` 19 个关卡各补 1 段 `anim`；只用 `vars`/`view`/`rotate`/`reveal`
    （不依赖图元 id，避免发明 id），全部 `vars` 目标经脚本校验「滑块存在 + 不越界」。
  - **2D 播放器（从零）**：`LabPlane` 新增 `play_anim()`/`_tick_demo()`/`_demo_apply()`/`_anim_set_slider()`，
    支持 `vars`（参数补间，**不吸附 step**）与 `reveal`（复用逐图元显现补间）；
    `LabStage` 接「▶ 演示」按钮（本轮 scene 带 `anim` 才显示）。
  - **2D 数据 11 个文件**：直线/圆/椭圆/向量/三角/函数/数列/导数/抛物线/双曲线/数学思想，
    各挑一条 explore 轮按教学意图设计轨迹（如导数同时改 k、b 落到 (1,1) 切线；椭圆让 P 绕行一周印证距离和为定值）。
  - **修一处真 bug**：3D 与 2D 播放器都在收尾帧前整帧 `advance`，导致参数停在目标 ~80%
    （`k` 最高 0.8）。改为「先累加时间 → 到点强制 `k=1.0` → 再推进」，两处同步修正。
  - **自动化防线**：`Tests._test_anim_player`（播放/自动停止/set_scene 中断 + 全库 `anim` 数据
    「滑块存在且不越界」校验）。
  - 全量回归绿：`CHECKED 97` / `TESTS 1744`（+161，含拉取带入的规则层测试）/ `SMOKE 285` /
    `UI-SMOKE 369` / `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new`
    （**anim 覆盖 13/26**）/ `KNOWLEDGE hard-gaps=0` / `ASSETS 30.06 banned=0`。
  - **D2 转 ✅**；余 13 个无滑块 2D 文件（可先用 `reveal`）列为可选扩展。
- **上一轮（第二十六轮）**：**B13 第一步——朗读双路径统一**（`94b3acb`）。
  - 新建 `scripts/rules/SpeechRules.gd`（**165 行**，规则层第八文件，≤200 红线自动覆盖）：
    `$$LaTeX$$` / `{f:名称}` / Unicode 数学符号 → 中文口播的统一转换器（映射注入，纯函数）；
    `InlineMath.strip_formulas` 薄转发，删三份重复实现。
  - **修复双路径不一致**：追问轮 `_q_speak` 曾直用未转换 `ask`；现与普通轮共用同一出口。
  - **转换扩展，盲点 5 种 → 0**：`\dfrac`、下标（曾剥成「an」）、`\vec`/`\bar`/`\hat`、`\mathbb`、
    `\Rightarrow`/`\forall`/`\exists`、角度（幂替换前特判）、`\overline` 共轭、`\cdots`/`\triangle`/
    `\varnothing`、Unicode 下标字母；`x^{2}` 念「平方」。
  - **口播看板**进 `check_questions`：1296 公式段 / 716 文本字段 / 盲点 0 种。
  - 全量回归绿：`CHECKED 97` / `TESTS 1583`（+27）/ `SMOKE 285` / `UI-SMOKE 369` / `LabSmoke TMP_OK` /
    `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` / `KNOWLEDGE hard-gaps=0` / `ASSETS banned=0`。
  - B13 改 🟡 第一步完成；余「20 关人工听感抽检」（AI 无法替代）。
- **第二十五轮（2026-10-21）**：**A4 收口完成**（`7b4f8be`）。
  - **`check_all.gd` 内置行数红线**：`scripts/rules/*.gd` 每文件 ≤200（自动覆盖未来新增规则文件）、
    GameData ≤1600、TheoremTree ≤1550、StageBase ≤1200；超限打 `OVERLIMIT` 并计入 failures，
    CI 挡合并。**反向验证**：MasteryRules 注水 207 行 → `OVERLIMIT 1 failures`，恢复后 0 failures。
  - **README**：目录结构补 `rules/` 纯规则层条目；新增「代码结构红线（A4 验收）」小节
    （上限表 + 处置规则：先拆纯规则而非改上限，上调须在 TODO 记录理由）。
  - 全量回归绿：`CHECKED 96` / `TESTS 1556` / `SMOKE 285` / `UI-SMOKE 369` / `LabSmoke TMP_OK` /
    `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` / `KNOWLEDGE hard-gaps=0` / `ASSETS banned=0`。
  - **A4 全条目 ✅**：九刀累计规则层七文件 696 行、三文件 4725→4311 行，全程无行为变化。
- **第二十四轮（2026-10-21）**：**A4 第九刀——教材重排/章节合并迁入 CurriculumRules**（`022e038`）。
  - 新建 `scripts/rules/CurriculumRules.gd`（**100 行**，纯静态、教材定义显式传参不读全局）：
    `apply_order`（方法在前/版本序/未列出补齐/重复列出不重复）、`group_chapters`（同分册+同章号
    合并为单元卡，返回 chapters+members）、`group_key_of`、`unit_title`、`book_of_chapter`、
    `chapter_no`、`chapter_in_domain`。
  - GameData 七个函数改薄转发（1647 → **1575**），TheoremTree 等调用方零改动。
  - **先测后搬**：Tests 新增 `_test_curriculum_rules` 纯单测（约 24 断言）；既有 996-1044 整材
    集成测试（6 版本 × 章号/分册/合并数）兜底真实数据。
  - 全量回归绿：`CHECKED 96`（+1 规则文件）/ `TESTS 1556` / `SMOKE 285` / `UI-SMOKE 369` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` / `KNOWLEDGE hard-gaps=0` /
    `ASSETS banned=0`。
  - **A4 累计九刀**：规则层**七文件 696 行**，三文件合计 **4311 行**（第一刀前 4725，−414）。
- **第二十三轮（2026-10-21）**：**A2 收编落地**（`43a11f9`）。
  - **README**：两场景从「遗留关」改口径为**官方收编场景**；新增**文件名 ↔ 场景/章节对照表**
    （即 A17 第二步的对照表部分），含 `conic/conics`、`vector/vectors`、`solid_basic/solid_methods`
    易混警示与校验器兜底说明。
  - **Tests 新增 `_test_legacy_binding`（13 断言）**：课程表引用的 `method`/`conic` key 必须在对应
    数据文件存在（打错 key = 静默空关）；两类场景保持在用（实测 6 关/3 关）。
  - **UiSmoke `_test_legacy` 升级**：「能构建」→「构建 + 关卡数据已载入」（`_stages` 非空），
    UI-SMOKE 367 → **369**。
  - **两文件头部补状态标注**（A2 验收项）：「官方场景（A2 已收编）… 迁移列长期项」。
  - 全量回归绿：`CHECKED 95` / `TESTS 1533`（+13）/ `SMOKE 285` / `UI-SMOKE 369` / `LabSmoke TMP_OK` /
    `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` / `KNOWLEDGE hard-gaps=0` / `ASSETS 30.04 banned=0`。
- **第二十二轮（2026-10-21）**：**A17 第一步——数据文件命名/映射自检进 check_questions**（`463d06e`）。
  - **`check_questions.gd` 新增 `_check_naming()`**（+94 行）：① 章节 `lab` → `data/<lab>_levels.json`
    存在性（缺失 = LabStage 静默空章，记错）；② 递归扫 `scripts/tests/tools` 的 `*.gd`，
    显式 `res://data/*.json` 路径登记为已引用；③ 孤儿 `*_levels.json`（无任何引用）记错；
    ④ 单复数近名对**只有一半被引用即记错**，均在用上看板（现状 `conic/conics`、`vector/vectors` 均在用）。
  - **反向验证**：植入假孤儿文件 → 2 new / EXIT=1；删除恢复 0 new / EXIT=0——自检真能红灯。
  - 全量回归绿：`CHECKED 95` / `TESTS 1520` / `SMOKE 285` / `UI-SMOKE 367` / `LabSmoke TMP_OK` /
    `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 26 files 0 new` / `KNOWLEDGE hard-gaps=0` / `ASSETS 30.04 banned=0`。
  - 余下（真重命名 + README 对照表）待 A2 收编/迁移决策后一并做。
- **第二十一轮（2026-10-21）**：**A4 第八刀——填空解析并入 StageRules + 修分数 bug**（`cb6a915`）。
  - **StageRules.gd 126 → 155 行**：新增 `norm_math`（√/²/³/×/÷/π/隐式乘法归一化）+
    `parse_math`（归一化后 Expression 求值，空串/语法错/非数值 null）。
  - **去重**：`StageBase` 删 `_norm_math`/`_parse_math`；**`SolidChallenge` 删同名重复副本**（约 40 行），
    容差判定改用 `StageRules.num_ok`——填空解析自此单一来源（对 A2 收编也更有利）。
  - **fix(B1)**：`parse_math` 内整数字面量统一转 float（前后视保护小数），修复 Expression 整数除法
    把 `1/2` 算成 0 导致**分数填空被误判错**（本次搬移测试时发现的存量学生侧 bug）。
  - **测试**：`_test_stage_rules` 扩充约 24 条（小数/分数/上下标/幂/乘除号/负号/括号/√/π/空串/
    非法式/连续除法左结合/小数不受 float 化影响）。
  - 全量回归绿：`CHECKED **95**` / `TESTS **1520**`（+24）/ `SMOKE 285` / `UI-SMOKE 367` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` / `QUESTION-CHECK 1057 题 0 new` /
    `KNOWLEDGE 275 点 hard-gaps=0` / `ASSETS 30.03（3109 files，banned=0）`。
- **第二十轮（2026-10-21）**：**A4 第七刀——TheoremTree 解锁判定并入 TreeRules**（`8092fa4`）。
  - **TreeRules.gd 97 → 126 行**：新增 `region_stars`（本单元累计星数，等价原 `GameData.stars_of` 求和）、
    `level_li_by_id`（按 id 查索引，找不到 -1）、`level_unlocked`（自由模式/首关恒开；已通关可重玩；
    Boss 门 `gate.need_stars>0` 以本单元累计星数为唯一条件；否则要求上一关 ≥1 星）。
  - **TheoremTree.gd 1563 → 1541 行**：`_region_stars`/`_level_li_by_id`/`_level_unlocked` 改为薄委托，
    8 处调用面不动，行为零变化。注意 `GameData.is_level_unlocked` 是跨章节判定（含章节解锁），语义不同**不合并**。
  - **测试**：`_test_tree_rules` 扩充约 15 条（首关/自由模式/越界/已通关重玩/Boss 门不足与达标/
    `gate=0` 回退上一关/区域星数/按 id 查索引）。
  - 全量回归绿：`CHECKED **95**` / `TESTS **1496**`（+15）/ `SMOKE 285` / `UI-SMOKE 367` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` / `QUESTION-CHECK 1057 题 0 new` /
    `KNOWLEDGE 275 点 hard-gaps=0` / `ASSETS 30.03（3109 files，banned=0）`。
- **第十九轮（2026-10-21）**：**A4 第六刀——TheoremTree 布局纯规则 TreeRules**（`56f1e23`）。
  - **新增** `scripts/rules/TreeRules.gd`（97 行）：`disasm_groups`（显式 `group` 优先 / "N-M" 按 N 分单元 /
    无编号用顺序号 "01" / Boss 殿后 / 组名回退 `group_names`→模块名→「单元 N」，元数据
    li/code/title/technique/optional/after 透传）+ `catmull_rom`（路径平滑，首尾保留、每段 per_seg 采样）。
  - **TheoremTree.gd 1655 → 1563 行**：删除 `_disasm_groups`（约 72 行）与 `_catmull_rom`（约 26 行），
    改调 `TreeRules`；节点创建/绘制/滚动不动，行为零变化。
  - **测试**：`_test_tree_rules` 约 39 条构造断言（三种分组路径/Boss 殿后/单组与多组标题回退/空列表/
    元数据透传/曲线端点与直线性/per_seg=1 恒等）。踩坑：`"3-1 推理"` 有编号应保持 "3-1"，
    顺序号仅用于无编号关卡（首版测试预期写错已改）。
  - 全量回归绿：`CHECKED **95**`（0 failures）/ `TESTS **1481**`（+39）/ `SMOKE 285` / `UI-SMOKE 367` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` / `QUESTION-CHECK 1057 题 0 new` /
    `KNOWLEDGE 275 点 hard-gaps=0` / `ASSETS 30.03（3109 files，banned=0）`。
- **第十八轮（2026-10-21）**：**A4 第五刀——StageBase 答题/选项乱序并入 StageRules**（`02cc149`）。
  - **`StageRules.gd` 72 → 112 行**：`shuffle_allowed`（题面 `shuffle:false`/`fixed:true`、<2 选项、
    顺序相关标记「以上/都对/都错/都正确/都不正确/上述/以下」自动关闭）、`order_for`（显示位置→原始下标，
    关闭时恒等）、`multi_ok`（多选集合语义判定，顺序无关、重复选不凑数）、`num_ok`（填空容差判定）。
  - **StageBase.gd 1257 → 1235 行**：删除 `_shuffle_allowed` 私有实现；`_opt_order_for`/`_multi_confirm`/
    `_submit_input` 改走规则层；选项展示与作答反馈的 UI 标记/动效不动，行为零变化。
  - **测试**：`_test_stage_rules` 增补约 23 条断言（乱序开关/标记黑名单/排列不丢不重/集合语义/容差含负数）；
    `UiSmoke` 改引 `StageRules.shuffle_allowed`（原直接调 StageBase 私有方法）。踩坑：容差边界断言
    需用二进制精确可表示值（1.05−1.0 有浮点误差），已改 1.5/1.0 边界。
  - 全量回归绿：`CHECKED **94**`（0 failures）/ `TESTS **1442**`（+23）/ `SMOKE 285` / `UI-SMOKE 367` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` / `QUESTION-CHECK 1057 题 0 new` /
    `KNOWLEDGE 275 点 hard-gaps=0` / `ASSETS 30.02（3107 files，banned=0）`。
- **第十七轮（2026-10-21）**：**A4 第四刀——StageBase 结算纯规则 StageRules**（`b17edfc`）。
  - **新增** `scripts/rules/StageRules.gd`（72 行）：星级判定 `judge_stars`（正确率 0.8/0.6 分界 →
    陷阱扣 1 → 超时降 1 保底 1 星 → 守关失败归 0 → 当日重试上限，返回 `time_capped`/`star_capped`）；
    奖励合成 `compose_reward`（基础 30 + 零失误×15 + 星级×20 + 满星 60 + 无陷阱 30 + 连击×3 +
    首通 → 极速 40 → 连击倍率 → 金币翻倍，返回 `speed_bonus`/`combo_bonus`）；评级 `grade`（S/A/B/C）；
    Boss 首通 `boss_first_clear` 与极速奖励 `speed_bonus_ok` 判定。
  - **StageBase.gd 1291 → 1257 行**：`_finish` 的星级/超时/重试标记与奖励/极速/连击加成全部改走
    `StageRules`（`combo_mult` 仍取 `ComboBar.multiplier`），`_grade` 门面委托；HUD/存档/结算面板
    文案与动画不动，行为零变化（SMOKE/UI-SMOKE 覆盖关卡结算流程）。
  - **新测试**：`_test_stage_rules()` 约 41 条构造断言——星级各降级路径/保底/限时边界、奖励
    219→311→622 链式合成、首通 365、评级、首通/极速判定。
  - 全量回归绿：`CHECKED **94**`（0 failures）/ `TESTS **1419**`（+41）/ `SMOKE 285` / `UI-SMOKE 367` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` / `QUESTION-CHECK 1057 题 0 new` /
    `KNOWLEDGE 275 点 hard-gaps=0` / `ASSETS 30.02（3107 files，banned=0）`。
- **第十六轮（2026-10-21）**：**A4 第三刀——萌宠养成 PetRules + 掌握度 MasteryRules 双切**（`09540b4`）。
  - **新增** `scripts/rules/PetRules.gd`（49 行）：好感分层（投喂 3/8 次）、饥饿判定（0.35）、状态标签、
    跨会话衰减 `decay`（饱食 −0.32/天地板 0.15、心情向 0.55 回落/地板 0.2、离线天数 lerp 封顶 1 天）、
    投喂效果（饱食置满、心情 +0.12 封顶）。
  - **新增** `scripts/rules/MasteryRules.gd`（24 行）：单关掌握度公式（0.65 星级分 + 0.25 清关质量 −
    错题惩罚封顶 0.4，未通关恒 0）、错题权重（0.1/次封顶 0.5）、领域均值除零守卫、
    达标/生疏阈值 `MASTERY_UNLOCK`/`MASTERY_STALE` 0.5/0.35 随规则迁出。
  - **GameData.gd 1670 → 1647 行**：6 个萌宠门面（tier/饿/心情/饱食标签/衰减/投喂）与
    `_recompute_mastery`/`_eval_mastery`/`pet_stale_domains` 委托规则层，行为零变化；
    `UserProfile` 阈值引用同步改引 `MasteryRules`（门面签名不变，Pet/UserProfile 调用方零改动）。
  - **新测试**：`_test_pet_rules` + `_test_mastery_rules` 约 40 条构造断言——衰减边界（0 天原样/地板/半天
    lerp 0.725）、加权公式、除零守卫、惩罚过深 clamp 下界等。
  - 全量回归绿：`CHECKED **93**`（0 failures）/ `TESTS **1378**`（+40）/ `SMOKE 285` / `UI-SMOKE 367` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` / `QUESTION-CHECK 1057 题 0 new` /
    `KNOWLEDGE 275 点 hard-gaps=0` / `ASSETS 30.01（3105 files，banned=0）`。
- **第十五轮（2026-10-21）**：**A4 第二刀——经济结算纯规则 EconomyRules**（`41f879e`）。
  - **新增** `scripts/rules/EconomyRules.gd`（48 行，无状态静态纯函数）：星级经验公式（`EXP_PER_STAR`，
    只按新增星计发）、每日登录（`next_login_streak` 断签归 1 + `login_reward` 基数 50/20 每日 +20%）、
    通关结算纯判定 `settle_grant`（首达全额 / 重复折扣 / 跨天重置，把 level_records 字段读写收成纯函数）、
    消费判定 `can_spend`、每日任务进度 `mission_progress`。
  - **GameData.gd 1681 → 1670 行**：`grant_stars` 经验、`spend_coins`、`settle_level`、`claim_daily`、
    `daily_mission_progress` 五处门面委托，行为零变化（`_test_economy`/`_test_anti_farm`/`_test_daily` 回归保护）。
  - **消灭第二份公式**：`MainHub._maybe_daily` 原在 UI 侧本地复算 `mult/50/20` 登录奖励，
    改与 `claim_daily` 同源 `EconomyRules`（单一来源）。
  - **新测试**：`Tests._test_economy_rules()` 约 38 条构造断言——首达不动 paid 字段、当日封顶不再计数、
    跨天重置、负基数守卫、断签归 1、任务进度封顶/回退守卫等。
  - 全量回归绿：`CHECKED **91**`（0 failures）/ `TESTS **1338**`（+38）/ `SMOKE 285` / `UI-SMOKE 367` /
    `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` / `QUESTION-CHECK 1057 题 0 new` /
    `KNOWLEDGE 275 点 hard-gaps=0` / `ASSETS 30.00（3101 files，banned=0）`。
- **第十四轮（2026-10-20）**：**A4 第一刀——纯规则层 PlayerRules**（`af14e73`；称号/勋章/等级/
  星级统计/防刷公式切出，GameData 1779→1681；CHECKED 90 / TESTS 1300；踩坑：headless 跑 .gd 必须 `--script`）。
  - **新增** `scripts/rules/PlayerRules.gd`（194 行，无状态静态纯函数）：称号阶梯 `RANKS`、勋章定义与达成判定
    `MEDALS`/`medal_met(ctx)`、玩家等级曲线（每 8 星）、星级统计（chapter_stars / 满星 / boss / 整章满星）、
    防刷公式 `star_cap` / `repeat_grant`。
  - **`GameData.gd` 1779 → 1681 行**：`rank_*`/`medal_*`/`chapter_stars`/`star_cap_for_attempt` 等门面原地保留、
    内部委托，调用方面零破坏；`_medal_met` 改为 `_medal_ctx()` 一次汇总统计快照 + 纯函数判定
    （勋章循环内不再每枚重复遍历课程表）；新增公开进度门面 `cleared_level_count()` 等 4 个。
  - **调用方同步**：`Achievements`/`UserProfile` 改用 `PlayerRules.MEDALS` 与进度门面，`StageBase` 改用
    `PlayerRules.STAR_CAP_REPEAT`/`REPEAT_REWARD_RATE`；`Tests` 旧私有 API 引用改新 API。
  - **新测试**：`Tests._test_player_rules()` 约 55 条构造数据断言——称号边界（6%/15%/满星）、等级曲线、
    星级统计、勋章达成/未达/边界（50 题门槛、boss 课程 0 枚不达成）、防刷公式（第 3 次降上限、每日 3 次封顶、负基数守卫）。
  - **踩坑（重要）**：headless 跑 `*.gd` 脚本**必须带 `--script`**——位置参数会把工程当游戏正常跑起来
    （Login 场景 headless 空转、无输出、零 CPU，形似假死），本轮曾因此误判 `.godot` 损坏并重建；
    正确姿势以 CI 为准：先 `--import`（生成类缓存）再 `--script`。
  - 全量回归绿：`CHECKED **90**`（89 + PlayerRules，0 failures）/ `TESTS **1300**`（+55）/ `SMOKE 285` /
    `UI-SMOKE 367` / `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` /
    `QUESTION-CHECK 269 关 1057 题 0 new（warn 3 与基线同）` / `KNOWLEDGE 275 点 hard-gaps=0` /
    `ASSETS 29.99（3099 files，banned=0）`。
- **第十三轮（2026-10-20）**：**A3 + A12 合并清理双清**（死代码与第二份题库一次清零，`375eb1a`）。
  - **删除**（−1225 行 / −14.9KB）：`scripts/screens/Battle.gd`（688 行）+ `Battle.gd.uid`、
    `scenes/Battle.tscn`、`data/questions.json`（42 题）、`GameData._load_questions()` / `questions_for()`
    / `QUESTIONS_PATH` / `_questions`。
  - **兜底改造**（前置风险全部落地）：`GameData` 4 处 `"res://scenes/Battle.tscn"` 默认值改为——
    `_enter_level` 校验 `scene` 非空且 `ResourceLoader.exists`，坏数据 `push_error` + 跳回主界面；
    `_level_nav` 缺 scene 返回 `{}`（与「关卡不存在」同语义，`pet_quests` 等既有 is_empty 过滤直接复用）；
    两处推荐关卡（弱领域推荐 / `_first_unmastered_level`）缺 scene 直接 `continue` 不入推荐；
    `TheoremTree._enter` 原地报错 + Toast「该关卡缺少场景数据」（校验前置于 `start_level`，不污染当前上下文）。
  - **工具/测试同步**：`smoke_scene.gd` / `capture_scene.gd` / `UiSmoke.gd` 的 Battle 默认值改为空则跳过，
    `UiSmoke` legacy 列表只剩在用的 `ConicStage`/`SolidChallenge`；补交 `sample_distractors.gd.uid`（此前漏交）。
  - **文档同步**：`README.md`（模块树与「改内容」段落：全仓只有一份权威题库 `data/*_levels.json`）、
    `docs/关卡游戏化方案.md`（现状发现①/场景表/关卡进入/§9 决策记录第 5 条 → 2026-10-20 修订为删除）。
  - **A12 验收自动兜底确认**：「跨文件重名关卡数据」检查已在 `check_questions.gd`（`_check_cross_file_dups`），
    删后输出 **0 组**（此前 5 组全部来自 `questions.json` ↔ `set_logic_levels.json`）。
  - 验收达成：`grep Battle`/`questions.json` 在代码中只剩说明性注释；curriculum 复核 **275/275 全带 scene**。
  - 全量回归绿：`CHECKED **89**`（90 − Battle.gd）/ `TESTS 1245` / `SMOKE 285` / `UI-SMOKE 367`（fail=0，
    移除 Battle legacy 样本）/ `LabSmoke TMP_OK` / `LEVEL-PREVIEW-SMOKE 7474` /
    `QUESTION-CHECK 269 关 1057 题 0 new（warn 3 与基线同）` / `KNOWLEDGE 275 点 hard-gaps=0` /
    `ASSETS 29.97（3097 files，banned=0）`。
  - 第十二轮（上游）：**B2 扩题 13 章收官（27/27 章 ≥5.0 题/关）+ E3 验收补齐 #2/#3 + TODO 改结构优先**；
    第十一轮：B5 收官（`6fb59c7`：抽检 30 题 + `sample_distractors.gd`）；
    第十轮：B5 批次二（`32f064e`）；第九轮：B5 批次一（`0ddf55e`）；
    第八轮：E3 全条收官 `vector_physics` #14（`7f94b7c`）、`prob_simulate` #15（`9534189`）；
    第七轮：E3 #13 `93240c1`；第六轮：#12 `0a3aae0`；第五轮：#10 `b3205f0`；第四轮：#9 `0bb0a2e`；
    第三轮：#7/#8 `5d784bb`；第二轮：#6/#4 `017f04b`/`d4a6a40`、#5 `1630a99`。
- **下次建议顺序**（按性价比）：
  > **2026-10-20 用户决策：暂停题目扩产，先做结构收敛。** B2 下限已全线达成（27/27 章 ≥ 5.0 题/关），
  > B1（21.4% → ≥30%）与 B2「上探 6~7 题/关中段」均为**纯内容批量生产**，可随时回归；当前转向 A/D/F 类结构问题。
  1. **G1 已完成**（第三十三轮）→ 接下来 **G3 学习报告/家长视图**（纯逻辑与数据展示，可自动化验证、不依赖真机）；
     若先做内容侧，则 **A13 字体替换 + F7 素材签字 + F2 keystore/真机**（需人工决策/下载/目视）。
  2. 决策项待拍板：**G4/G5**；**A17 是否真重命名**（低优先）；**A2 迁移到 LabStage**（长期项）。
  3. 内容项回归：**B1 达标**（21.4% → ≥30%）、**B2 中段**（6~7 题/关）、**B6 理由选项占比**，
     结构收敛后按章继续（新题模板仍须内建 B5 规范）。
  > A4/A2/A17/D1~D4/F3/F4/G1 已于第二十二~三十三轮全部收口；`check_all`（行数 + 裸时长）、
  > `check_questions` 映射自检、`_test_anim_player` / `_test_plane_motion` / `_test_demo_controls` /
  > `_test_keyboard_nav` / `_test_idle_power` / `_test_srs_rules` / `_test_srs_store` / `_test_srs_flow`
  > 让结构、动效、输入、耗电与复习排程不回退。
  > ⚠️ `GameData.gd` 已到 **1593/1600** 行——下一个动它的条目**先拆存档层**（见 §7 G1 的 A4 遗留注）。
- **第三十三轮（2026-10-21）**：**G1 错题间隔重复（SRS）收官**——`rules/SrsRules.gd` + `rules/SrsStore.gd`
  两层纯规则 + `GameData` 门面 + 首页/错题本「今日待复习」入口；九件套全绿
  （`CHECKED 101` / `TESTS 1900` / `SMOKE 285` / `UI-SMOKE 393` / `TMP_OK` / `7474` / `0 new` / `hard-gaps=0` / `banned=0`）。
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

### [x] A2 · 遗留关卡模块定策略（P1）✅ 2026-10-21 第二十三轮收编完成（`43a11f9`）

**现状（证据）**
- 当前 275 个关卡里：`LabStage` **229**、`Lab3DStage` **31**、`SequenceStage` 6、`SolidChallenge` **6**、`ConicStage` **3**。
- **2026-10-20 实测修正**：`SolidChallenge` 与 `ConicStage` **仍在活跃使用**（分别 6 关 / 3 关），
  不是可以直删的死代码——旧描述「遗留模块」易被误读为已废弃。
- 遗留实现：`scripts/modules/solid/SolidChallenge.gd`（977 行）、`scripts/modules/conic/ConicStage.gd`（528 行）
  + `scripts/modules/conic/scenes/C1.gd`（672 行）/`C2.gd`（337）/`C3.gd`（256），均为自绘关卡，不走 `StageBase`。
- 几何章节迁移（圆/椭圆/向量/直线/立体几何/空间向量）已完成，但这两块没动。

**做法（二选一，明确写进 README）**
- **迁**：按 A1 的做法迁到 `LabStage`/`Lab3DStage`（若几何演示可用 `LabPlane` 表达）；成本高（约 2770 行自绘代码）。
- **收编（推荐先做）**：保留实现，但明确为「正式场景」——补进 `StageBase` 体系的测试与文档，
  在 `README.md` 标注它们是**在用模块**而非遗留；把迁移列入长期项。
- **冻结**（不推荐）：会在 9 个在用关卡上标「冻结」，语义混乱。

**验收**
- `README.md` 的模块说明与代码现状一致；遗留文件顶部有明确状态标注（或已删除）。

**已实施（记录，2026-10-21 第二十三轮，`43a11f9`）**
- **采用「收编」路线**：
  - `README.md`：两场景改口径为**官方收编场景**；新增**文件名 ↔ 场景/章节对照表**（顺带完成 A17
    第二步的对照表），含近名文件警示。
  - `Tests._test_legacy_binding`（13 断言）：课程表 `method`/`conic` key 必须在
    `solid_methods.json`/`conic_levels.json` 存在（打错 key = 静默空关），且两场景保持在用。
  - `UiSmoke._test_legacy`：「能构建」→「构建 + `_stages` 数据已载入」（367→369）。
  - 两文件头部加状态标注：官方场景、被 N 关活跃引用、迁移列长期项。
- **迁移作为长期项**挂在 A16（3D 场景代码与数据分层整理）语境下，不阻塞任何里程碑。

---

### [x] A3 · `Battle.gd` 死代码处理（P1）✅ 2026-10-20 与 A12 合并清理完成（第十三轮，`375eb1a`）

**现状（证据）**
- `scripts/screens/Battle.gd`（**688 行**，TODO 旧记 614 行）仅在关卡**没有** `scene` 字段时作为回退占位
  （`GameData.gd:490 / 1339 / 1482 / 1498`，另 `TheoremTree.gd` 1 处）。
- **2026-10-20 实测**：`curriculum.json` 的 275 个关卡**全部带 `scene`**（`scene` 字段 275 处 / 关卡 id 275 个），
  `Battle` 被 **0 个关卡引用** → 回退路径实际不可达。
- `Battle.gd:50` 是 `GameData.questions_for()` 的**唯一调用点**；`data/questions.json`（14.9 KB）
  仅由 `GameData._load_questions()` 读入 → **A3 与 A12 同源，应合并清理**。
- `docs/关卡游戏化方案.md` §9 决策记录第 5 条（旧决策）：保留 `Battle.tscn` 作回退占位；
  `HexAvatar`/`HpBar` 已抽到 `scripts/ui/BossHud.gd`，`Battle.gd` 改为引用它。

**做法（推荐：删除，与 A12 合并）**
- 删除 `Battle.gd`/`Battle.tscn`、`data/questions.json`、`GameData._load_questions()` 与 `questions_for()`。
- **必须同步改 4 处兜底默认值**（`GameData.gd:490/1339/1482/1498` 的 `"res://scenes/Battle.tscn"`）：
  改为 `push_error` + 跳回知识体系，否则坏数据会指向不存在的场景。
- 若仍想保留回退能力：保留脚本，但补一条 `Tests.gd` 用例证明「缺 scene 的关卡能进 Battle 且不报错」，
  并在文件头写清它是**回退关**而非历史遗留。

**验收**
- 二选一落定，`README.md` 有说明；`check_all.gd` 0 failures。

**已实施（记录，2026-10-20 第十三轮）**
- **采用「删除」路线**（与 A12 合并，commit `375eb1a`，−1225 行）：
  - 删除 `scripts/screens/Battle.gd`（688 行）+ `Battle.gd.uid` + `scenes/Battle.tscn`；
  - **4 处兜底默认值全部改造**（`GameData._enter_level` 校验 scene 非空且路径存在，坏数据
    `push_error` + 跳回主界面；`_level_nav` 缺 scene 返回 `{}`，与「关卡不存在」同语义；
    弱领域推荐与 `_first_unmastered_level` 缺 scene 直接 `continue`；`TheoremTree._enter`
    校验前置于 `start_level`，坏数据原地报错 + Toast，不污染当前上下文）；
  - 同步：`smoke_scene.gd` / `capture_scene.gd` / `UiSmoke.gd` 空 scene 跳过，`UiSmoke` legacy
    列表只剩在用的 `ConicStage`/`SolidChallenge`；`README.md` 模块树与 `docs/关卡游戏化方案.md`
    （现状发现①/场景表/关卡进入/§9 决策记录第 5 条）全部改为与现状一致。
- 验收达成：`check_all` 0 failures（`CHECKED 89` = 90 − Battle.gd）；curriculum 复核 **275/275 全带 scene**；
  `grep Battle` 在代码中只剩说明性注释；`BossHud`（BOSS 关在用）不受影响。

---

### [x] A4 · 上帝对象拆分（P2）✅ 2026-10-21 第二十五轮收口（`7b4f8be`）

**收口记录（2026-10-21 第二十五轮，`7b4f8be`）**
- 九刀累计：规则层从无到**七文件 696 行**（PlayerRules/EconomyRules/PetRules/MasteryRules/
  StageRules/TreeRules/CurriculumRules），三文件 4725 → **4311 行**（−414）。
- **验收两项均达成**：① 行数上限写进 README「代码结构红线」（规则层每文件 ≤200、
  GameData ≤1600、TheoremTree ≤1550、StageBase ≤1200）；② 拆分全程四件套全绿、无行为变化。
- **机制化防回退**：`check_all.gd` 内置行数红线（自动覆盖未来新增的 rules/ 文件），
  超限打 `OVERLIMIT` 并计入 failures，CI 挡合并；已反向验证（注水到 207 行 → 红灯）。
- 处置规则写明：超限**先拆纯规则**而非改上限；上调须在本清单记录理由。
- 余下三大文件内容主要是 UI 面板代码（非纯逻辑），如需继续收敛见 A16 语境，不阻塞任何里程碑。

**现状（证据）**
- `scripts/autoload/GameData.gd` **1575 行**（A4 九刀后；原 1779，称号/勋章/等级/星级统计/防刷公式
  已切到 `scripts/rules/PlayerRules.gd`、经济结算到 `EconomyRules.gd`、萌宠养成/掌握度到
  `PetRules.gd`/`MasteryRules.gd`、教材重排/章节合并到 `CurriculumRules.gd`；旧记 1548）：
  课程表 + 进度 + 存档 IO + 勋章 + 称号 + 领域掌握度
  + 萌宠 + 每日任务 + 经济 + 地图宝箱/事件 + 错题本 + 多用户，全在一个 autoload 类里。
- `scripts/modules/line/TheoremTree.gd` **1541 行**（旧记 1496；A4 第六/七刀切出 `TreeRules` 后 −114）：
  同一脚本同时充当 `WorldMap.tscn`（`kind="method"`）与 `TheoremTree.tscn`（`kind="knowledge"`）；
  余下主要是 `_open_panel` 面板 UI（非纯逻辑）。
- `scripts/screens/StageBase.gd` **1195 行**（旧记 1092；A4 第四/五/八刀切出结算/答题/填空解析规则后 −40）：
  HUD + 答题 + 选项乱序 + BOSS 层 + 节奏/计时 + 结算 + 导航；
  被 **12 处**引用，是关卡基类，改动面最大。
- `scripts/modules/solid/SolidChallenge.gd` **1017 行**（第八刀删重复 `_parse_math`/`_norm_math` 副本后）：
  与 StageBase 独立实现，A2 收编决策相关。
- 三文件合计 **4311 行**（2026-10-21 九刀后实测 1575+1541+1195；第一刀前 4725）。规则层七文件合计 696 行。

**进度**
- 2026-10-21 第二十四轮 · **第九刀（`022e038`）**：教材重排/章节合并（`apply_order`/`group_chapters`/
  `group_key_of`/`unit_title`/`chapter_in_domain`/`book_of_chapter`/`chapter_no`）迁入
  `CurriculumRules.gd`（新文件 100 行），GameData 七函数改薄转发 1647→1575；`_test_curriculum_rules`
  纯单测约 24 断言（TESTS 1556 / CHECKED 96）。
- 2026-10-21 第二十一轮 · **第八刀（`cb6a915`）**：填空解析（`norm_math`/`parse_math`）并入 `StageRules`
  （126→155），StageBase 1235→1195，**SolidChallenge 删重复副本**（约 40 行，容差判定改走
  `StageRules.num_ok`）；顺带 **fix(B1)** 整数字面量转 float，修复 Expression 整数除法把 `1/2` 算成 0
  的分数填空误判（搬移测试时发现的存量 bug）；`_test_stage_rules` 扩充约 24 断言
  （TESTS 1520 / CHECKED 95）。
- 2026-10-21 第二十轮 · **第七刀（`8092fa4`）**：TheoremTree 解锁判定（`region_stars`/`level_li_by_id`/
  `level_unlocked`）并入 `TreeRules`（97→126），TheoremTree 1563→1541；`_test_tree_rules` 扩充约 15 断言
  （TESTS 1496 / CHECKED 95）。跨章节判定 `GameData.is_level_unlocked` 语义不同，不合并。
- 2026-10-21 第十九轮 · **第六刀（`56f1e23`）**：知识树布局纯规则 `scripts/rules/TreeRules.gd` 切出
  （关卡分组/组名回退/Catmull-Rom 平滑），TheoremTree 1655→1563；`_test_tree_rules` 约 39 断言
  （TESTS 1481 / CHECKED 95）。
- 2026-10-21 第十八轮 · **第五刀（`02cc149`）**：答题/选项乱序纯逻辑并入 `scripts/rules/StageRules.gd`
  （`shuffle_allowed`/`order_for`/`multi_ok`/`num_ok`），StageBase 1257→1235，删私有 `_shuffle_allowed`；
  `UiSmoke` 改引规则层；`_test_stage_rules` 增补约 23 断言（TESTS 1442 / CHECKED 94）。
- 2026-10-21 第十七轮 · **第四刀（`b17edfc`）**：结算纯规则 `scripts/rules/StageRules.gd` 切出
  （星级判定/奖励合成/评级/首通/极速判定），StageBase 1291→1257；`_test_stage_rules` 约 41 断言，
  HUD/存档/面板零改动（TESTS 1419 / CHECKED 94）。
- 2026-10-21 第十六轮 · **第三刀（`09540b4`）**：萌宠养成 `scripts/rules/PetRules.gd` + 领域掌握度
  `scripts/rules/MasteryRules.gd` 双切（好感/饥饿/标签/衰减/投喂 + 单关掌握度/错题权重/领域均值/阈值），
  `MASTERY_*` 阈值迁出 GameData；`_test_pet_rules`/`_test_mastery_rules` 约 40 断言，
  门面零破坏（TESTS 1378 / CHECKED 93）。
- 2026-10-21 第十五轮 · **第二刀（`41f879e`）**：经济结算纯规则 `scripts/rules/EconomyRules.gd` 切出
  （星级经验/登录连击与奖励/结算判定/消费判定/任务进度），`MainHub` 重复登录奖励公式并案消灭；
  `Tests._test_economy_rules()` 约 38 断言，门面零破坏（TESTS 1338 / CHECKED 91）。
- 2026-10-20 第十四轮 · **第一刀（`af14e73`）**：纯规则层 `scripts/rules/PlayerRules.gd`（称号/勋章/等级/
  星级统计/防刷公式）切出，`Tests._test_player_rules()` 先行约 55 断言，GameData 门面零破坏、
  全量九件套绿（CHECKED 90 / TESTS 1300）。后续按同一手法增量继续，不必一次到位。

**做法（增量，不必一次到位）**
- `GameData` → 组合子对象：`Curriculum`（课程/教材/章节）、`Progress`（星级/记录/掌握度）、
  `Economy`（金币/经验/道具/商店）、`Pet`、`Adventure`（宝箱/事件）、`WrongBook`。保持 `GameData.xxx()` 门面不破坏调用方。
- `StageBase` → 把 BOSS 层（`BossHud` 交互）、节奏层（`ComboBar`/计时/`_grade`/`_next_star_hint`）、
  结算面板（`_victory*`）拆成独立 `Control` 子类。
- `TheoremTree` → 抽出「章节数据源 + 布局」与「两种呈现」；或因 A8 另立新场景。

**验收**
- 单文件行数上限约定（如 ≤ 600）写进 `README.md`；拆分后四件套全绿、无行为变化。
  ~~已达成（2026-10-21）~~：上限表在 README「代码结构红线」，`check_all` 红线兜底。

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
  9. legacy 场景（`ConicStage`/`SolidChallenge`；原含 `Battle`，已随 A3 删除后移出冒烟范围）能构建出子节点。
- **反向验证通过**：临时注释 `StageBase._ready()` 的 `_build_ui()`，`UiSmoke` 立即红灯（`EXIT=1`，14 条节点断言失败），恢复后回到全绿。
- 已纳入 CI（`.github/workflows/check.yml` 新增 UiSmoke 步骤，`pipefail` + 断言 `0 fail`）。
- 说明：`Battle.tscn` 无课程表样本（占位/死代码，见 A3；**已于 2026-10-20 随 A3 删除**），用任意真实关卡上下文实例化验证。

---

### [x] A12 · `questions.json` 变成第二份权威题库（P1）✅ 2026-10-20 随 A3 删除完成（第十三轮，`375eb1a`）

**现状（证据）**
- `data/questions.json`（12 组 / 42 题，**14.9 KB**）的唯一消费者是 `GameData.questions_for()`，
  而后者**只被 `scripts/screens/Battle.gd:50` 调用**；`Battle` 仅在关卡缺 `scene` 时回退，
  而 `curriculum.json` 的 **275 个关卡全部带 `scene`**（2026-10-20 实测）→ 该通道整体不可达（与 A3 同源）。
- 更关键：其 12 组 key 里有 **5 组与 `data/set_logic_levels.json` 同名**
  （`set_ops` / `set_interval` / `logic_cond` / `logic_neg` / `logic_special`），
  但**逐题比对 5/5 组内容完全不同**（题面、题量都不同：`questions.json` 每组 5 题、
  `set_logic_levels.json` 每组 6~8 轮）。
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

**已实施（记录，2026-10-20 第十三轮，commit `375eb1a`）**
- **采用「删除」**：`data/questions.json`（42 题 / 14.9KB）与 `GameData._load_questions()` /
  `questions_for()` / `QUESTIONS_PATH` / `_questions` 全部删除——随 A3 删 Battle 后该通道彻底不可达。
- 「跨文件重名关卡数据」检查确认已在 `check_questions.gd`（`_check_cross_file_dups`，A5 已建）：
  删除前 5 组重名全部来自 `questions.json` ↔ `set_logic_levels.json`，删除后输出 **0 组**。
- 全仓现在只有一份权威题库 `data/*_levels.json`；`README.md`「改内容」段落已同步。
- 附带影响：B7 的图片选项范围缩小（`questions.json` 的 66 处随文件移除，关卡文件剩 114 处）；
  B5 审计中的「`prob_freq` 无数个」题随文件一并移除。

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
- **2026-10-20 实测修正**：这 6 个脚本合计 **3568 行**（`geom_sphere.gd` 595、`vector_sphere.gd` 379、
  `anglepyramid.gd` 290、`complement.gd` 341、`insphere.gd` 340、`inout.gd` 369），但**已不含题干内容**
  （问号 0~1 处、中文字符仅几何标注）——**题目已迁至 `data/solid_methods.json`**（B2 本轮的题目就加在那里）。
- 因此本条**前提部分失效**：不再存在「有内容没有内容」的两套管线，剩下的是**图形构建代码 vs JSON 描述**
  的分层差异（同类内容在 `lab3d` 里由 `SolidBuilder.gd` 按 JSON 生成网格）。
- 对应关系已核对无缺口：curriculum 的 `solid_complement/vector/geom/insphere/inout/angle`
  六个关卡 ↔ `solid_methods.json` 的 6 个 method ↔ 6 个 topic 脚本。

**做法（降级）**
- 短期只需在 `README.md` / `docs` 明确「立几方法关：题目在 `solid_methods.json`，图形在 `topics/*.gd`」，
  避免后来者再在代码里找题目。
- 长期（非必需）再评估把 6 个 topic 的几何构建迁到 `lab3d` 的 JSON 描述能力。

**验收**
- 文档写清 6 关的「数据/图形」分工；后续新增题目只改 JSON。

---

### [ ] A17 · 数据文件命名易混（P2）

**现状（证据）**
- 同时存在且都在用的近似名：
  - `data/conics_levels.json`（圆锥曲线综合，现行 `archetype:LAB`）
    vs `data/conic_levels.json`（`C1`~`C6`，旧 `ConicStage` 专用）——**两章都会出现在章节看板**
    （`圆锥曲线综合` 与 `圆锥曲线`），题量各自独立。
  - `data/vectors_levels.json`（`vec_*`，平面向量初步章节）
    vs `data/vector_levels.json`（`vector_*`，平面向量章节）
  - 另有 `data/functions_levels.json` vs `data/function_lab_levels.json`（函数与分段章节）。
  - 以及 `data/solid_basic_levels.json`（立体几何初步）vs `data/solid_methods.json`（立体几何 `solid`）。
- 改动时极易改错文件，且错改后**静默失效**（另一份没人用/或用了另一份）。
- **2026-10-20 已实际致误一次**：B2 扩题按文件名推进时改的是 `conics_levels.json`，
  而章节看板里的「圆锥曲线」实际是 `conic_levels.json`，导致该章长期停留在 6/24 未被发现。

**做法**
- **第一步（低成本、零风险）**：把 `curriculum.json` 的「数据 key → 文件名 → 章节」映射做成
  `tools/check_questions.gd` 的一条自检输出（或在 `check_knowledge` 里），
  让「某章节由哪些文件构成」可一键查询；同时输出「仅差复数/后缀的成对文件」清单。
- 第二步：结合 A2/A16 的决策统一命名（旧模块加 `_legacy` 后缀，或直接删除）。
- 在 `README.md`「改内容」小节列出「文件名 ↔ 章节」对照表；由 A5 校验器兜底跨文件重名。

**完成记录（2026-10-21）**
- 第一步（`463d06e`，第二十二轮）：`check_questions.gd` 新增 `_check_naming()`——① 章节 `lab` →
  `data/<lab>_levels.json` 存在性（缺失 = LabStage 静默空章，记错）；② 递归扫 `scripts/tests/tools`
  的 `*.gd`，显式 `res://data/*.json` 路径登记为已引用；③ 孤儿 `*_levels.json` 记错；④ 单复数近名对
  只有一半被引用即记错（另一半 = 改错文件名的受害者），均在用上看板。
  **反向验证**：植入假孤儿文件 → 2 new / EXIT=1；删除恢复 0 new / EXIT=0。
- 第二步对照表部分（`43a11f9`，第二十三轮）：README 新增「文件名 ↔ 场景/章节对照表」+ 近名警示。
- **余「真重命名」为可选决策**：`conic/conics`、`vector/vectors` 两对均在用且语义确实不同，
  重命名收益低于风险，建议保持现状由校验器兜底。

**验收**
- 不再存在仅差复数/后缀的成对数据文件；README 有对照表。
- ~~第一步自检~~ ✅ 已完成；余下（真重命名 + README 对照表）待 A2 收编/迁移决策后一并做。

---

### [x] A18 · 内容数据异常时缺用户可见兜底（P1）

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

**实施记录（2026-10-21 第三十五轮）**
- **体检规则**：`scripts/rules/ContentHealth.gd`（122 行，纯规则：不读文件、不碰 autoload，
  入参 = 章节数组 + 已知场景集合 + 内容组键表）。七种问题码
  `E_EMPTY`/`E_DUP_ID`/`E_NO_LEVEL`/`E_NO_TITLE`/`E_NO_SCENE`/`E_BAD_REF`/`E_LOAD`，
  UI 文案与 CI 输出**共用一套**（`MESSAGES` + `describe()`）。
- **运行时**（轻量）：`GameData._load_curriculum()` 失败时写 `content_problems`（不再只有 `push_error`），
  成功后跑一次 `ContentHealth.check(chapters)`；门面 `content_ok()` / `content_health()` / `reload_content()`。
  只查课程表结构（O(关卡数) 的纯字典遍历），**不打开** 26 个 `*_levels.json`，启动开销可忽略。
- **兜底界面**：`scripts/ui/ContentFallback.gd` —— `card()`（兜底卡：人话说明 + 最多 5 条明细 +
  「重试加载」/「复制错误信息」）、`banner()`（主城顶部一句话横幅）、`fill(root)`（铺页）。
  `TheoremTree._ready()` 的 `chapters.is_empty()` 分支从「静默 return」改为铺兜底卡；
  `MainHub._build_center()` 在内容不健康时加横幅。
- **发版闸门**：`tools/check_content_health.gd`（深度：场景文件 `ResourceLoader.exists`、
  引用能否定位到数据文件组键、孤儿组提示）→ 接进 `.github/workflows/check.yml`
  （`CONTENT-HEALTH-FAIL` 即红灯）与 `build/run_checks.ps1`。CI 即「导出流程前的那一次调用」
  （本仓库没有导出步骤，发版走本地 `bump_version` + Godot 导出；CI 是唯一的自动闸门）。
- **验收实测**：把 `data/curriculum.json` 写成非法 JSON →
  `content_ok=false`、`chapters=0`、问题 `E_LOAD/课程表格式损坏`；还原文件后 `reload_content()` → `true`、23 章。
  （「重置内容缓存」未按字面实现：内容是 `res://` 只读，没有可重置的缓存；改为语义正确的
  「重试加载」+「复制错误信息」，理由记在此处。）
- **顺带修真 bug**：体检首次运行即报 `E_DUP_ID solid_angle` —— `solid` 章「线面角 · 二面角」与
  `solid_basic` 章「11-1 空间角（几何法）」**共用同一个关卡 id**；星标按 id 存 → 两关共用一条记录
  （一关通关另一关跟着亮），`level_name()` 也会返回错的名字。已把后者改名 `solid_basic_angle`
  （`lab_ref` 保持 `solid_angle` 不变，`data/knowledge_map.json` 与覆盖矩阵同步）。
- **测试**：`Tests._test_content_health`（24 断言：空表 / 重复 id / 空章节 / 缺名字 / 缺场景 /
  场景不存在 / 引用定位不到 / 引用映射 / **真数据必须体检通过**）+
  `UiSmoke._test_content_fallback`（11 断言：兜底卡文案与按钮、横幅、铺页替代空白页、复制文本只含结构信息）。
- **回归**：`check_all` 108 scripts 0 failures / `Tests` 2000 passed / `SMOKE` 286 / `UI-SMOKE` 416 /
  `LabSmoke TMP_OK` / `QUESTION-CHECK` 无新增 / `KNOWLEDGE` 硬缺口 0 /
  `CONTENT-HEALTH` 27 chapters 275 levels 0 problems / `ASSETS` ≈30.23 MB banned=0 /
  `LEVEL-PREVIEW-SMOKE` 7474 ok。

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

> 本节所有数字来自 26 个 `data/*_levels.json` + `data/questions.json` 的全量扫描
> （**注**：`questions.json` 已随 A12 于 2026-10-20 删除，涉它的数字只剩历史意义；现行为 1057 题 / 269 组），
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
- 当前：单选 **834** / 多选 **4** / `interact` **4** / 填空 **219** → 非四选一 **21.4%**（目标 ≥30%；
  2026-10-20 起 B2 扩题新增轮次以填空为主，覆盖复数/圆锥曲线（`conic_levels.json` 与 `conics_levels.json` 两处）/
  递推求通项/随机变量/函数与分段/不等式/立体几何初步/导数及其应用/数学思想综合/集合与逻辑/平面向量初步/
  立体几何 `solid`/成对数据的统计分析 等章，已使占比回升约 2.3 个点）。

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
- ✅ 集合与逻辑章（`set_logic_levels.json`）：`set_ops`/`set_interval`/`logic_cond`/`logic_neg`/`logic_special`
  各 3 轮 → 各补 2 轮，30 → **40 题（5.0 题/关）**（第 6/7/8 组原已 5 轮）；
  新增 10 轮为 2 填空 + 8 四选一，覆盖并交集辨析、德摩根律、并集区间与补集端点开闭、集合包含判充分条件、
  由充分条件反求参数、全称命题否定、存在命题求上界、举反例与特殊值排除。
- ✅ 圆锥曲线章（`conic_levels.json`，`curriculum.json` 的 `conic`，关卡 C1~C6，**与 `conics_levels.json` 不同！**）：
  C1 补 2 轮、C2 补 2 轮、C3 补 3 轮，24 → **31 题（约 5.2 题/关）**（C4/C5/C6 原已 5 轮）；
  新增 7 轮为 2 填空 + 5 四选一，覆盖椭圆/双曲线定义的三态限制、去绝对值的双曲线一支、
  e 值判类型与 e→0 趋于圆、斜率积符号与曲线类型、定值斜率积求椭圆方程、双曲线斜率积具体求值。
  注意本文件 C1~C3 为旧式 `mode` 写法（无 `type`/`explain`），C4~C6 为新式 `$$…$$`；新轮沿用所在组风格，
  且**不得引用不存在的公式图**（`art/conic/formulas/` 仅有 `opt_conic_neg/pos/negab.png` 等）。
- ✅ 平面向量初步章（`vectors_levels.json`，`curriculum.json` 的 `vectors`，关卡 `vec_*`）：
  `vec_ops`/`vec_coord`/`vec_dot`/`vec_collinear` 各 3 轮 → 各补 2 轮，27 → **35 题（5.0 题/关）**
  （`vec_basis`/`vec_tri`/`vector_physics` 原已 5 轮）；新增 8 轮为 4 填空 + 4 四选一，
  覆盖线性组合与平行四边形对角线、由模长反求参数、中点坐标、a·a=|a|²、展开 |a+b|²、共线充要条件、
  三点共线求参。
- ✅ 立体几何章（`solid_methods.json`，`curriculum.json` 的 `solid`，关卡 `solid_complement` 等 6 关）：
  本章题目**不在 `*_levels.json`**，而在 `data/solid_methods.json` 的嵌套结构 `{"methods":{id:{levels:[…]}}}`，
  由 `check_questions.gd` 的 `_solid_method_counts()` 单独统计（**不计入全库 `_n_questions`**）。
  `complement` 原 4 题（第 1 关为无 `opts` 的 `pick` 交互）→ 补 2 题，6 关共 29 → **31 题（约 5.2 题/关）**
  （`vector_sphere`/`geom_sphere`/`insphere`/`inout`/`anglepyramid` 原已 5 题）；新增 2 题为四选一，
  覆盖补形法适用前提（三条棱两两垂直且共顶点）、由三条棱长 2/4/4 直接求外接球半径 R=3。
  注意：本文件选项多为 `res://art/formulas/*.png` 图片，**新增题一律用纯文本选项**，不得发明未注册图名。
- ✅ 成对数据的统计分析章（`corr_data_levels.json`，`curriculum.json` 的 `corr_data`）：
  `cd_scatter`/`cd_regress`/`cd_indep` 各 3 轮 → 各补 2 轮，30 → **36 题（约 5.1 题/关）**
  （`cd_resid` 已 6 轮、`cd_rprops`/`cd_chi`/`cd_corr_coef` 已 5 轮）；新增 6 轮为 2 填空 + 4 四选一，
  覆盖相关关系与函数关系的识别、由 r=−0.98 判读走向、回归系数的平均含义、由样本中心反求截距、
  2×2 列联表行合计、未达临界值时「不能拒绝 H₀ ≠ 证明独立」。**本章为 B2 下限收官章。**
- 🎉 **B2 下限全线达成**：截至本轮，`check_questions` 章节看板**全部 27 章均 ≥ 5.0 题/关**
  （最薄一批均为 6/30 = 5.00）；B2「每关 5~8 题」的**下限已 100% 达标**，
  后续转向把各章上探到区间中段（6~7 题/关）并主攻 B1。
- ⚠️ **口径纠偏（重要）**：B2「题量最薄章节」应以 `check_questions.gd` 的**章节看板**为准（由 `curriculum.json`
  反查「数据 key → 教材章节」，见该脚本 `_chapter_board`），而非各数据文件的分组轮数。同一关卡 key 可能落在
  不同文件中（如 `conic` vs `conics`、`solid` vs `solid_basic`/`solid_methods`），此前按文件名推进漏了
  `conic_levels.json`。

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
  无穷多」的真实误解，判定为**合格错误路径，不改**；该文件已随 A12 于 2026-10-20 整体删除（第十三轮）。
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
  `questions.json` 66 处（其中 15 道题**四个选项全是图片**；**已随 A12 删除，B7 现存范围只剩关卡文件 114 处**）。
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

### [ ] B13 · 朗读/无障碍路径不完整，且两条路径行为不一致（P1）🟡 第一步完成（2026-10-21 `94b3acb`）

**完成记录（2026-10-21 第二十六轮，`94b3acb`）——双路径统一 + 转换器进规则层**
- **现状条目已过时一半**：`strip_formulas` 早已不是「整段剥掉」（已有 FORMULA_SPEECH/LaTeX 通用转换），
  但**双路径不一致是真的**：追问轮 `_set_followup_question` 直接 `_q_speak = ask`（未转换，
  Unicode/公式按原字符念出乱码式听感）——已修复，两轮统一走 `UI.strip_formulas`。
- `scripts/rules/SpeechRules.gd`（**165 行**，A4 规则层第八个文件，≤200 红线自动覆盖）：
  `$$LaTeX$$` / `{f:名称}` / Unicode 数学符号 → 中文口播的**统一转换器**（纯函数，
  FORMULA_* 映射由 InlineMath 注入）；`InlineMath.strip_formulas` 改薄转发，
  删除重复的 `_dollar_speech`/`_formula_speech`/`_latex_to_speech` 三份实现。
- **转换扩展（盲点 5 种 → 0 种）**：`\dfrac`、下标 `a_{n}`/`a_n`（曾被剥成「an」读「安」）、
  `\vec`/`\bar`/`\hat` 记号、`\mathbb` 数集、`\Rightarrow`/`\Leftrightarrow`/`\forall`/`\exists`、
  `\chi` 卡方、`90^{\circ}` 角度（须在幂替换前特判，否则念「的circ次方」）、`\overline` 复数共轭、
  `\cdots`/`\triangle`/`\varnothing`、Unicode 下标字母（ₙ 等）；`x^{2}` 也念「平方」。
- **口播看板**进 `check_questions`：每个文本字段统计公式段与盲点命令——现状 **1296 公式段 /
  716 文本字段 / 盲点 0 种**；删除过时的「speak 字段计数」（自动转换路线取代数据字段）。
- Tests 新增 `_test_speech_rules` 约 30 断言（含旧行为回归）；TESTS 1556 → **1583**。
- **余下（第二步）**：人工抽检 20 关真机听感（AI 无法替代）；`ask`/`tip`/选项文本口播质量持续抽查。

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
- ~~双路径统一~~ ✅ 已达成；~~盲点命令~~ ✅ 看板显示 0 种；~~覆盖率看板~~ ✅ 已进 check_questions。
  余「20 关人工听感抽检」（需真人/真机）。

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

### [x] D1 · 2D 探究器没有过渡动画（拖动 = 瞬时跳变）（P1）

**现状（证据）**
- 2D 几何的渲染器 `scripts/modules/lab/LabPlane.gd`：滑块变化后直接 `queue_redraw()` 立即重绘，
  **没有补间、没有轨迹、没有残影**（全文件无 `create_tween`）。
- 对比 3D：`scripts/modules/lab3d/Lab3DView.gd` 有完整的补间播放器（`_tick_anim`）。
- 覆盖范围：138 处滑块分布在 2D 几何全部章节。

**落地（2026-10-21，第二十八轮）**
- **① 补间**：新增 `_disp`（显示值）层，`_process` 里按时间常数 `TWEEN_TAU=0.13s`
  做指数缓动（`1-exp(-dt/τ)`，与帧率无关）；`_ex_var()` 优先读 `_disp`，
  因此所有几何/读数都随显示值连续变化。到位后自动精确对齐，不留残余误差。
  演示播放（`_anim_set_slider`）与手动拖滑块共用同一条通道。
- **② 残影**：一次变化的**起点快照**存入 `_ghost_disp`，以 0.55 起、1.1/s 衰减的透明度
  重绘一遍旧图形（`_c()` 在残影模式下统一乘 alpha；点/向量/标签在残影模式下跳过，避免重影干扰）。
- **③ 轨迹**：变化过程中每帧记录 `points` 图元的屏幕坐标（最多 14 帧），
  以青蓝色小圆点按 1.6/s 淡出——看得到"动点走过的路"。
- **明确不做补间的地方**：`begin_break`（分段函数分界线）与 `begin_drag`（拖点）是**直接操作**，
  必须跟手，已清空 `_disp` 保持瞬时；否则会像拖橡皮筋。
- **验证**：
  - `Tests._test_plane_motion`：目标 1→3 后单帧显示值严格落在 (1,3) 区间（**证明中间态存在**）、
    残影被激活、轨迹有帧；40 帧后精确到位、残影与轨迹自动清空；换场景状态清零。
  - `UiSmoke` 新增「演示按钮可见性 + 能真正启动 2D 播放器」断言（369 → **383**）。
  - 至少 3 个知识点实测具备三层（圆/椭圆/向量等含 `points` 的章节均有轨迹）。
- **全量回归绿**：`CHECKED 97` / `TESTS 1752`（+8）/ `SMOKE 285` / `UI-SMOKE 383` /
  `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new`（anim 13/26）/
  `KNOWLEDGE hard-gaps=0` / `ASSETS 30.07 banned=0`。

**验收**
- ✅ 补间 + 差量高亮（残影）+ 残影/轨迹 三层已落地，且**全局生效**（所有滑块章节，非仅 3 个）；
- 🟡 「用 A11 截图回归抓帧间差异」：headless 无法可靠取像素，改为**状态级中间态断言**
  （显示值严格居中 + 轨迹帧数 > 0）作为可回归替代；像素级观感仍需人工目视一次。

---

### [x] D2 · 演示动画只覆盖 1/26 个关卡文件（P1）

**现状（证据，已实测）**
- 数据层 `anim` 字段原本**只出现在 `solid_basic_levels.json`（27 处）**，
  其余 **25 个 `*_levels.json` 全为 0** → 228 个关卡里约 **12 关（5%）** 有「▶ 演示」。
- 能力本身是完整的（`Lab3DView.play_anim` 支持 7 种步骤）：
  `highlight` 50 / `view` 38 / `reveal` 25 / `a` 22（按阶段嵌套）/ `vars` 21 / `rotate` 7 / `pulse` 4。

**落地（2026-10-21）**
- **3D 全量补齐**：`space_levels.json` 19 个关卡各补 1 段 `anim`（19 轮），
  只用不需 id 的步骤 `vars` / `view` / `rotate` / `reveal`，避免发明图元 id；
  全部 `vars` 目标值经脚本校验「滑块存在 + 不越界」。
- **2D 播放器从零补齐**：`LabPlane` 新增 `play_anim()` / `_tick_demo()` / `_demo_apply()`，
  支持 `vars`（滑块补间，参数变→图形联动，**不吸附 step**，避免一跳一跳）与
  `reveal`（复用既有「逐图元错峰显现」补间重演）；`view`/`rotate`/`pulse`/`highlight`
  在 2D 无对应语义，安全忽略。`LabStage` 接「▶ 演示」按钮（仅本轮 scene 带 `anim` 时显示）。
- **2D 数据补 11 个文件**（各挑一条 explore 轮，按教学意图设计参数轨迹）：
  直线（倾斜角 30→150→45）、圆（半径→圆心）、椭圆（P 绕行一周而 |PF₁|+|PF₂| 不变）、
  向量（模长→1 落到单位圆）、三角（θ 旋转看对称）、函数（b 平移看值域色带）、
  数列（公差转负看散点转向）、导数（k、b 同步 → 落到 (1,1) 切线）、
  抛物线（p 控制开口）、双曲线（a 控制顶点）、数学思想（a 变号→开口翻转、a=0 退化）。
- **顺带修掉一个真 bug（3D 也中）**：两个播放器的收尾帧被整帧跳过（`k` 最高只到 ~0.8，
  参数停在目标 80% 处）。改为「先累加时间 + 到点强制 k=1.0」，`Lab3DView._tick_anim`
  与 `LabPlane._tick_demo` 同步修正。
- **自动化防线**：`tests/Tests.gd` 新增 `_test_anim_player`（播放/终止/中断断言 +
  全库 `anim` 数据的 `vars` 目标「滑块存在且不越界」校验）。

**验收**
- ✅ `anim` 覆盖文件数 **1/26 → 13/26**；`check_questions.gd` 输出「anim 演示覆盖: 13/26 文件」。
- 剩余 13 个 2D 文件（多为无滑块的概念章）为**可选扩展**：可先用 `reveal` 挂演示，不阻塞本条。

---

### [x] D3 · 动效全在「结果反馈」，缺「理解型动效」（P1）

**现状（证据）**
- `scripts/ui/Vfx.gd`（376 行，9 个原语）里，**8 个是答题结果的情绪反馈**；
  其余 `Confetti`/`ComboBar`/`BossHud`/`ProgressLine`/`MedalBadge`/`BrandMark` 同属元游戏/情绪层。
- **没有任何一类动效用于表达数学关系**（无差量、无轨迹、无临界点标记、无联动连线）。

**落地（2026-10-21，第二十九轮）**
- **四个表意原语全部实现**（都在 `LabPlane`，随 D1 的补间层工作）：
  1. `delta_highlight`（自动）：变化期间用**旧参数重算同一个 `readouts` 表达式**并比对，
     变了就画高亮条 + ▲/▼ 方向三角（三角用 `draw_colored_polygon` 画，不依赖字体字形）。
     直接消费 86 处 `readouts`，无需改数据。
  2. `trace`（自动）：D1 的动点轨迹（≤14 帧，1.6/s 淡出）。
  3. `pulse_at`：数据键 `"pulses": [{ "p": [x,y], "label": "切点" }]`，**停稳后**脉冲一次
     （扩散圆环 + 实心点 + 标签），1.2/s 淡出。
  4. `link_line`：数据键 `"links": [{ "a": …, "b": …, "label": "|OP|" }]`，
     画**相位流动的虚线**（`fmod(_t*16, dash+gap)`）+ 端点小圆 + 标签。
- **真实章节试点（3 章 ≥ 验收要求 2 章）**：
  - 椭圆 1-1：`link_line` 画 \|OP\|（对照「到两焦点距离之和恒定」——到中心距离却在变，纠正常见误解）；
  - 函数与分段 3-1：`pulse_at` 标最低点 `(0,b)`（随 b 平移）；
  - 导数 2-1：`pulse_at` 标切点 `(1,1)`（直线调参到位后提示"就是这里相切"）。
- **语义分层已落文档**：`README.md` 新增「动效清单：装饰动效 vs 表意动效」小节，
  列全 9 个 `Vfx` 原语 + 6 个表意原语，并明确**表意动效不跟随 `UI.animations` 开关**（为 D4 的开关拆分定调）。
- **顺手修一处上游乱码**：`_draw_readouts` 的默认标签原为 mojibake `"ֵ"`，改为 `"值"`。
- **测试**：`_test_plane_motion` 扩到 16 断言（新增 delta 差值可算、停稳触发 pulse、pulse 自动结束、
  全库 `links`/`pulses` 端点必须是二元数组、试点数量下限）。
- **全量回归绿**：`CHECKED 97` / `TESTS 1760`（+8）/ `SMOKE 285` / `UI-SMOKE 383` /
  `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` /
  `KNOWLEDGE hard-gaps=0` / `ASSETS 30.08 banned=0`。

**验收**
- ✅ 3 个章节用上理解型动效（椭圆 / 函数与分段 / 导数），且 `delta_highlight` 与 `trace` 为全局自动；
- ✅ 原语清单与用途登记进 `README.md`（含「装饰 vs 表意」开关语义）；
- 🟡 「抽查学生能看懂因果」属人工教学验证，需真人试看后回填结论。

---

### [x] D4 · 动效令牌缺失 + 演示不可控 + 无障碍粒度不足（P2）

**现状（证据）**
- **无动效设计令牌**：44 处 `tween_property(...)` **直接写裸时长**；缓动写法散落。
  `scripts/ui/UI.gd` 已是设计系统，但**没有动效章节**。
- **演示不可控**：`Lab3DView.play_anim()` 只能整体播一次，用户**无法暂停 / 重播 / 逐步看**。
- **无障碍粒度不足**：全项目 20+ 处检查 `UI.animations`（单一总开关），关闭后**连表意动效一起关**。

**落地（2026-10-21，第三十轮）**
- **令牌（`UI.gd`）**：`DUR_TINY 0.08 / FAST 0.14 / NORMAL 0.22 / SLOW 0.30 / XSLOW 0.45 /
  LONG 0.70 / SCENE 0.85 / AMBIENT 1.7`；缓动 `EASE_STD_* / EASE_EMPHASIS_* / EASE_SOFT_*`
  与链式助手 `UI.ease(tw)`；**语义上「时长只有一个来源」**。
- **收敛**：脚本化替换 **47 处**（14 个文件，含 `_scale_to` 的 3 处与 `MainHub` 的 1.7s 环境律动）。
- **静态防线**：`check_all.gd` 新增 `_check_bare_durations()`——按**括号深度扫描**取
  `tween_property` 第 4 个实参 / `_scale_to` 第 3 个实参，裸数字即 `BARE-DURATION` 红灯。
  **反向验证**：把 Toast 的 `UI.DUR_FAST` 改回 `0.14` → `BARE-DURATION 1` / `1 failures`；恢复 → 0。
- **演示可暂停/重播/单步**：`Lab3DView` 与 `LabPlane` 均补
  `pause_anim / resume_anim / toggle_anim_pause / restart_anim / step_anim(dt) / is_anim_paused`；
  `_process` 在暂停时不再推进时间轴。
  3D 工具条新增「⏸ 暂停 / ↻ 重播 / ⏭ 单步」（按钮文案随状态切换 ▶/⏸/继续），
  2D 右上角新增「↻」并让主按钮变「暂停/继续」。
- **开关拆两层**：`UI.fx_on() = animations and not reduced_motion` 统一判定**装饰**动效；
  新增设置项**「减弱动效」**（`Settings.reduced_motion`，默认关，写入 `user://` 配置）；
  **表意动效（补间/差量/轨迹/脉冲）不读这两个开关**——减弱档下数学信息不丢。
- **测试**：`_test_motion_tokens`（8 个令牌单调递增 + `UI.ease` 链式）、
  `_test_reduced_motion`（两档开关语义 + 减弱档下补间仍生效）、
  `_test_demo_controls`（2D/3D 的暂停、单步、重播各 7 断言）。
- **全量回归绿**：`CHECKED 97`（含新静态检查）/ `TESTS 1774`（+14）/ `SMOKE 285` /
  `UI-SMOKE 383` / `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` /
  `KNOWLEDGE hard-gaps=0` / `ASSETS 30.09 banned=0`。

**验收**
- ✅ `UI.DUR_*` 成为唯一时长来源，全仓裸时长 **0**（`check_all` 持续拦截，已反向验证）；
- ✅ 3D/2D 演示可暂停、重播、单步；
- ✅ 「减弱动效」档下关键信息不丢失（`_test_reduced_motion` 断言补间仍生效）。

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

### [x] F3 · 性能与耗电（3D 视口与背景常驻开销）（P1）

**现状（证据）**
- `Lab3DView` 的 SubViewport 是 `UPDATE_ALWAYS`（每帧渲染）+ `auto_rotate := true` 默认自转；
- `TechBg._process` 每帧全屏重绘，`set_process(true)` 常驻；
- **额外发现（本轮实测）**：`LabPlane._process` **无条件 `queue_redraw()`**——2D 关卡静止时也在每帧重绘。

**落地（2026-10-21，第三十二轮）**
- **3D 静止停帧**：新增 `_idle_t` / `_idle_stopped` 与两个阈值
  `IDLE_ROTATE_STOP=8s`（停自转）、`IDLE_RENDER_STOP=10s`（相机稳且空闲 → `UPDATE_DISABLED`）。
  `UPDATE_DISABLED` 保留最后一帧纹理，画面不变；任何交互/动画调用 `_wake()` 立即恢复。
  停帧后 `_process` 直接 early-return，连相机与材质参数都不再算。
- **前后台**：`_notification` 处理 `APPLICATION_PAUSED/FOCUS_OUT` → 停渲染，
  `RESUMED/FOCUS_IN` → 恢复。`TechBg` 同样处理，并在动效关闭时 **`set_process(false)`**
  （不是每帧空转判断），由 `Settings.changed` / 恢复通知重新拉起。
- **2D 按需重绘**：只有「入场显现（前 2.5s）/ 演示播放 / 补间 / 残影 / 轨迹 / 脉冲 /
  流动虚线（links）/ 拖拽脉冲」才 `queue_redraw()`；静止时完全不画。
  新增 `redraw_count` 计数供测试断言。
- **性能基线工具**：新增 `tools/perf_probe.gd` + `.tscn`（headless 可跑），
  输出 `PERF <case> proc_avg_us / proc_p95_us / frame_avg_us / mem_kb`。
  三种场景：`idle` / `lab_plane` / `lab3d`（3D 预热 1700 帧 ≈ 11s，确保已停帧）。

**实测（headless，2026-10-21）**

| 场景 | 修复前 proc_avg | 修复后 proc_avg |
|---|---|---|
| `lab_plane`（静止） | ≈ 73,430 µs | **259 µs** |
| `lab3d`（静止 10s+） | ≈ 70,262 µs | **251 µs** |
| `idle` 基线 | 171 µs | 171 µs |

**验收**
- ✅ 静止 10s 后 3D 视口停止渲染、自转停止（`Tests._test_idle_power` 断言 `UPDATE_DISABLED`）；
- ✅ 后台停帧、回前台恢复（同测试断言）；2D 静止不重绘（`redraw_count` 连续 20 帧不增）；
- 🟡 **Android 真机**的 FPS / 功耗 / 内存仍需真机测量（headless 无 GPU，只能量 CPU 处理耗时）。

---

### [x] F4 · 桌面端键盘操作（P1）

**现状（证据）**
- 项目发布 Windows 桌面版，但主流程**完全没有键盘支持**：`StageBase` / `LabStage` / `Lab3DStage` /
  `TheoremTree` / `MainHub` 里搜不到任何 `InputEventKey` / `KEY_*` 处理。
- 全局仅两处键盘：`Sound.gd`（`M` 静音）、`Scene.gd`（`ui_cancel` = Esc 返回）。
- 后果：桌面用户答选择题必须逐个鼠标点击，不能按数字选项、不能 Enter 提交/下一题。

**落地（2026-10-21，第三十一轮）**
- **新增 `scripts/autoload/KeyNav.gd`（163 行，autoload）**：只处理 `_unhandled_key_input`，
  因此**输入框打字与按钮默认激活都不受影响**；核心逻辑做成 `static func handle(stage, keycode) -> bool`，
  便于无头测试直接驱动，不必伪造 `InputEvent`。
- **鸭子类型取控件**：`stage.get("_opt_btns")` / `_next` / `_hint` / `_kb_confirm`，`_view3d`，
  所以 **`StageBase` 一行没改**（1195/1200 行红线不动，无需上调上限），全部子类自动获得。
- **键位**：`1..9` 选项（走与鼠标同一个 `pressed` 信号）、`Enter`（确认 → 下一关 → 焦点按钮三级优先）、
  `←/→/↑/↓` 焦点环、`H` 提示、`W/A/S/D` 3D 视角、`Esc`/`M` 沿用全局。
- **焦点可见**：选项按钮与 `UI.ghost_button`/`primary_button` 早已有 `focus` StyleBox，
  KeyNav 只负责 `grab_focus()`——键盘能看见选到哪。
- **3D 视角**：`Lab3DView.key_pan(dx, dy)` 改 `yaw_goal/pitch_goal`（pitch 夹到 ±1.35），
  与鼠标拖动共用同一状态，缓动与自动缓转行为一致。
- **舞台接线（各 2 行）**：`LabStage` / `Lab3DStage` 把实验轮的「确认」按钮挂到 `_kb_confirm`，
  并在 `_load_q` 置空避免悬空引用。
- **测试**：`Tests._test_keyboard_nav`（18 断言：数字选择与越界、Enter 三级优先、H、
  焦点前后移动、W/D 改视角、空舞台不崩）+ `UiSmoke._test_keyboard_stage`
  （真实 `LabStage` 上数字键确实走 `_on_choice`，`_last_picked == 0`）。
- **全量回归绿**：`CHECKED 98`（+1 新脚本）/ `TESTS 1792`（+18）/ `SMOKE 285` /
  `UI-SMOKE 385`（+2）/ `LabSmoke TMP_OK` / `LEVEL-PREVIEW 7474` / `QUESTION-CHECK 0 new` /
  `KNOWLEDGE hard-gaps=0` / `ASSETS 30.10 banned=0`。

**验收**
- ✅ 纯键盘可完成：数字选答 → Enter 提交/下一关 → 结算（焦点环可见）；
- ✅ 键盘与鼠标走同一条回调（`_on_choice`），行为一致（UiSmoke 真实舞台断言）；
- 🟡 全流程手感（焦点顺序是否符合直觉）建议在 Windows 版上手过一遍。

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
> **进度**：G1 ✅ / G3 ✅（2026-10-21 第三十三、三十四轮）；**G2 未开工**（作者工具链，
> 见 §7 G2）；G4 / G5 是决策项，暂不实施。

### [x] G1 · 错题间隔重复（SRS 遗忘曲线排程）（P1）

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

**实施记录（2026-10-21 第三十三轮）**
- **数据分层**：`srs_plan`（新存档字段）与 `wrong_log`（旧错题账，语义不动）**并存**，
  旧档缺排程者由 `SrsStore.legacy_plan()` 合成 `due_day = 0` 的「立即到期」计划 → **零迁移、天然兼容**。
  存档字段：`step / ok_streak / interval_days / due_day / last_wrong_day / first_wrong_at /
  last_review_at / wrong_count / last_reward_day`。
- **规则层（守 A4 红线，纯逻辑进 `rules/`）**：
  - `scripts/rules/SrsRules.gd`（113 行）——单条排程怎么算：阶梯 `INTERVALS = [1,3,7,16,35]`、
    `advance()`（答对进阶 / 答错重置 / 连对 `GRADUATE_OK=4` 毕业）、`eff_due_day()`（今天刚错过 → 今天到期，
    保留即时复练）、`is_due()` / `plan_less()`（到期日 → 错次 → 题号三级排序）、`rewarded_today()`（当日去重）。
  - `scripts/rules/SrsStore.gd`（177 行）——整本排程怎么存怎么查：`answer()`（推进 + 奖励 + 毕业）、
    `due_list()` / `plan_for()` / `normalize()`（存档迁移与钳制）、`review_order()`（到期前置 + 深链置顶）、
    `pet_quests()`（到期优先 + 未到期错题补位）。
  - `GameData` 只留**门面**（`srs_due_list()` / `srs_due_count()` / `srs_due_text()` / `srs_plan_for()` /
    `review_order()` / `pet_quests()`），行为零变更。
- **到期日用「日序号」而非时间戳**：`GameData.today_day()` 取本地日历日序号（`Time` 零时化后 ÷86400），
  避开时区与夏令时漂移；奖励去重另用日期串 `last_reward_day`。
- **奖励**：复习答对 `+2`（同题当日只发一次，防刷）、毕业 `+5`；旧「答对还清错账」的 `+5` 提为常量
  `GameData.WRONG_CLEAR_COINS`（语义不变）。
- **入口**：首页顶栏「复习 N」（今日无到期则隐藏）+ 错题笔记卡片角标「待复习 N」（动态刷新）；
  错题本新增「今日待复习」卡片（按到期顺序 + 一键「开始复习」深链到题号）+ 概览「今日待复习」计数 +
  每条错题标注「今天到期 / N 天后复习 / 已逾期 N 天」。
- **排序联动**：关卡内复习排序（`review_order`）与萌宠派单（`pet_quests`）均改为**到期优先**。
- **验收覆盖**：`Tests._test_srs_rules`（阶梯 / 5 天推进 / 答错重置 / 到期判定 / 排序 / 当日去重）、
  `Tests._test_srs_store`（存档层：建计划 / 推进 / 毕业 / 迁移钳制 / 排序 / 任务组装）、
  `Tests._test_srs_flow`（门面全流程 + 旧档兜底 + 每日不重复计奖）、
  `UiSmoke._test_srs_review_entry`（首页按钮与错题本卡片**真实构建** 8 断言）。
- **回归基线**：`CHECKED 101 scripts, 0 failures` / `TESTS: 1900 passed, 0 failed` /
  `SMOKE: 285 ok, 0 fail` / `UI-SMOKE: 393 ok, 0 fail` / `LabSmoke TMP_OK` /
  `LEVEL-PREVIEW-SMOKE: 7474 ok, 0 fail` / `QUESTION-CHECK 0 new（7 known）` /
  `KNOWLEDGE hard-gaps=0` / `ASSETS 30.15 MB（3122 files）banned=0`。
- ⚠️ **A4 遗留**：`GameData.gd` 已到 **1593/1600** 行（距红线仅 7 行）。下一个动 `GameData` 的条目
  **必须先拆存档层**（`_blank_user` / `_snapshot` / `_apply` / `_normalize_*` ≈ 80 行 → `scripts/rules/UserStore.gd`），
  否则立刻超限。
  - ✅ **已于 2026-10-21 第三十四轮（G3）兑现**：存档层拆到 `scripts/rules/UserStore.gd`，
    `GameData.gd` 回到 **1558/1600**。

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

### [x] G3 · 学习报告 / 家长视图（P2）

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

**实施记录（2026-10-21 第三十四轮）**
- **先还 A4 欠账——存档层拆分**：新增 `scripts/rules/UserStore.gd`（140 行）接管存档 dict ⇄ 运行时字段的
  **全部转换**（`_blank_user` / `_snapshot` / `_apply` / 错题 `module` 迁移），`GameData.gd` 只剩
  `_state()` / `_avatar_ids()` 三个薄门面 → **1593 → 1558 行**（红线 1600，余量 42 行）。
  顺手补了**脏档兜底**：字段缺失 / `null` / 类型不对一律取默认值（`_int_of` / `_float_of` / `_str_of` /
  `_dict_of`），手改过的存档不该让载入炸掉——实测原实现遇到显式 `null` 会在 `int(null)` 处整段中止。
- **新增时间维度——活动日志**：新存档字段 `activity`，按天一条
  `{date, answered, correct, stars, clears, reviews}`，**最多保留 120 天**（更早裁掉，存档不无限膨胀）。
  埋点：`record_answer()` 记 `answered`/`correct`，`grant_stars()` 记星级**净增**，
  `record_level_result()` 记 `clears`，`_srs_answer()` 对**此前已在复习计划里**的题记 `reviews`。
- **规则层（守 A4 红线，纯逻辑进 `rules/`）**：
  - `scripts/rules/ReportRules.gd`（150 行）——日历日换算（`date_of` / `index_of` / `recent_dates`，
    按 **UTC 解释的纯日历日**，不随时区/夏令时漂移）、活动日志（`bump` / `day_record`）、
    汇总（`summarize`：正确率、活跃天、逐日补行）、`weak_points`（**领域级**，不带关卡名）、
    `parent_view`（家长只读摘要）。
  - `scripts/rules/ReportExport.gd`（54 行）——文本周报 / 家长建议 / CSV / JSON 序列化。
  - `GameData` 只留**门面**（`report_summary` / `report_weak` / `parent_view` / `parent_advice` /
    `report_text` / `report_csv` / `report_json`）。
- **界面**：新增 `scripts/screens/LearningReport.gd`（280 行）+ `scenes/LearningReport.tscn`，
  自上而下：学习概览 → **逐日趋势柱状图**（沉默的日子也画出来，空档本身就是信息）→ 薄弱领域 →
  可分享的报告文本（可复制到剪贴板）→ 家长视图只读摘要 → 导出数据（CSV / JSON / 文本，写到 `user://`）。
  入口：**首页顶栏「报告」** + 档案库「学习报告 · 家长视图」卡片；`Scene.SCENE_LABELS` 登记「学习报告」。
- **隐私最小化**：家长视图只给**汇总量 + 领域级薄弱点名**，**不含题目原文 / 关卡名 / 作答内容**；
  报告默认**本地生成、不联网、不上传**（与 F1 策略一致），导出内容只有日期与计数。
- **验收覆盖**：`Tests._test_user_store`（存档层：空白档 / 快照 / 载入钳制 / 迁移 / 脏档兜底）、
  `Tests._test_report_rules`（日历日往返与闰年 / 活动日志累加与排序 / 汇总正确率与活跃天 /
  家长视图不泄露关卡名 / 三种导出可用）、`Tests._test_report_flow`（门面全流程 + **家长视图不泄露题号与
  题目原文** + 存档往返）、`UiSmoke._test_report_screen`（报告页**真实构建** + 周期切换切到 30 天 +
  导出按钮存在 + 隐私说明可见）。
- **回归基线**：`CHECKED 105 scripts, 0 failures` / `TESTS: 1976 passed, 0 failed`（+76）/
  `SMOKE: 286 ok, 0 fail` / `UI-SMOKE: 405 ok, 0 fail`（+12）/ `LabSmoke TMP_OK` /
  `LEVEL-PREVIEW-SMOKE: 7474 ok, 0 fail` / `QUESTION-CHECK 0 new（7 known）` /
  `KNOWLEDGE hard-gaps=0` / `ASSETS ≈30.2 MB（3131 files）banned=0`（末位随测试产物微漂移）。
- ⚠️ **残留**：「复习完成率」「错题净增」「薄弱领域变化（环比）」三项**未单列**——
  当前复习量按「进入复习计划的题数」计，不是「到期且已复习」的完成率；
  薄弱点取的是**当前诊断**（领域级快照），不是周期内的**变化量**。若要补，需要给
  `srs_plan` 与错题账补「上周同期的领域分布」快照，属独立一轮。

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

> 引擎：Godot 4.7.2（本机 `D:\Program Files\Godot_v4.7.2-stable_win64.exe`——注意它是**可执行文件**
> 而不是目录；且只有 GUI 子系统版本，**没有** console 变体），
> 直连控制台取输出会丢，须用 `Start-Process -Wait -RedirectStandardOutput/Error` 重定向。
> 换机后的工具链安装与已知坑见 `docs/环境配置.md`。
>
> **换机首次打开**：必须先让 Godot 生成全局类缓存，否则 `class_name`（如 `BossHud`、`SrsStore`）会连锁报
> `Parse Error: Could not find type "BossHud"`。用编辑器打开一次，或跑
> `& "<godot472.exe>" --headless --path . --import`（新增 `class_name` 文件后同样要跑一次）。

**当前回归基线**（改完请对照，数字只能升不能降；2026-10-21 G3 学习报告 / 家长视图后）：
`CHECKED 105 scripts, 0 failures`（含 D4 裸时长拦截）/ `TESTS: 1976 passed, 0 failed` / `SMOKE: 286 ok, 0 fail` /
`UI-SMOKE: 405 ok, 0 fail`（取样漂移，见下方注）/ `LabSmoke` 末尾 `TMP_OK` /
`LEVEL-PREVIEW-SMOKE: 7474 ok, 0 fail`（G2 预览器自检：数据定位回归 + 编辑往返 + 舞台抽样）/
`QUESTION-CHECK: 26 files / 269 levels / 1057 questions / 0 new / 7 known / 3 warnings`
（A5 校验器，存量问题见下方基线；看板另有「干扰项黑名单命中 0 处」见 B5、「anim 演示覆盖 **13/26 文件**」见 D2）/
`PERF idle 171 / lab_plane 259 / lab3d 251`（µs，headless CPU 处理耗时，见 `tools/perf_probe.tscn`）/
`ASSETS: ≈30.2 MB over 3131 files … banned=0, oversize=0`（A13 护栏；末位随测试产物微漂移，
看 `banned` / `oversize` 即可）/
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

- 题目总数 **1057**（全仓唯一权威题库 `data/*_levels.json`；原 `questions.json` 42 题已随 A12 于 2026-10-20 删除）；关卡组 **269**；
  平均 **3.93 题/关**（`check_questions` 口径：1057 = 单选 834 + 多选 4 + 填空 219；无选项 `interact` 4 另计）。
- 题型分布（`check_questions.gd` 看板）：单选 **834**，多选 **4**，`interact` **4**，填空 **219**；
  非四选一占比 **21.4%**（B1 目标 ≥30%；B2 扩题时新增轮次一律用填空/多选/`interact`，可同步抬高此值）。
- 选项：图片选项 **114** 处（位于 36 道题）；`ans==0` **757/834（90.8%）**（B8 偏高；新题已刻意分散 ans 位置）。
- 探究轮 **273**，其中题面为陈述句 **0（0.0%）**（`check_questions.gd` 口径；B3 目标 <20%；原始人工口径 221/230）。
- 轮次标签编号错位 **0 处**（B9 已修复：`tools/fix_labels.gd` 批量重编，规范 `<关卡序号>-<轮次> <阶段名>`）。
- 资源体积（A13 已治理）：仓库 tracked 合计 **29.6MB**（治理前 48.4MB；`art/` 已无 `.xcf`，源文件移至 `assets_src/`，
  标题字体 13.5MB 待替换）；APK（debug）旧基线 **60.9MB**（新基线待重新导出）。见 A13。
- 知识点矩阵（E1 已建立，E2/E3 已补齐）：`data/knowledge_map.json` 27 章 / **275 个知识点**（每关一挂）；
  **硬缺口 0**、选学/旧课标 8（基线 `tools/knowledge_gaps_baseline.txt`；2026-10-19 两角和差/二倍角清零）；
  关卡 id 跨章重名 **0 处**（2026-10-21 A18 体检发现 `solid_angle` 被两章共用，后者改名 `solid_basic_angle`）。见 E1/E2/E3。
- 数据一致性：`curriculum` 关卡 275 / 关卡数据组 269，`lab_ref` 动态映射覆盖其余；
  跨文件重名关卡数据 **0 组**（原 5 组全部来自已删除的 `questions.json` ↔ `set_logic_levels.json`，随 A12 清零）。见 A12。
- 口播字段 `speak`：**0 处**。见 B13。
- 动效：`anim` 演示覆盖 **13/26** 个关卡文件（D2：`solid_basic_levels.json` 27 处、
  `space_levels.json` 19 轮 3D，另有 11 个 2D 章节各 1 轮）；
  3D 播放器 `Lab3DView.play_anim` 支持 7 种步骤，2D 播放器 `LabPlane.play_anim` 支持 `vars` / `reveal`；
  **2D 过程表达（D1）**：参数补间 τ=0.13s + 起点残影（1.1/s 淡出）+ 动点轨迹（≤14 帧，1.6/s 淡出），
  直接拖拽（分界线/拖点）不补间；**表意原语（D3）**：`delta_highlight`（读数差量 + ▲/▼，全局自动）、
  `pulse_at`（数据键 `pulses`，停稳后脉冲）、`link_line`（数据键 `links`，相位流动虚线）；
  椭圆/函数与分段/导数三章已试点。**令牌（D4）**：`UI.DUR_*` 8 档为唯一时长来源，
  裸时长 **0**（`check_all` 括号深度扫描拦截）；2D/3D 演示支持暂停/重播/单步；
  「减弱动效」档只关装饰动效，表意动效常开。
- 经济（C1/C2 已修复）：`grant_stars` 经验仅随星级提升发放；`settle_level` 首达全额、重复通关 ×0.3 且每日最多 3 次；
  同一关当日第 3 次尝试起星级上限降为 2（`Tests._test_anti_farm` 覆盖）。
- 学习报告（G3 已建立）：新存档字段 `activity`（按天一条
  `{date, answered, correct, stars, clears, reviews}`，**保留 120 天**）——旧档缺该字段时天然为空，
  载入即用、无需迁移；报告窗口「本周 7 天 / 本月 30 天」，导出 CSV/JSON **只含日期与计数**，
  家长视图**只含汇总量与领域级薄弱点名**（无题目原文 / 关卡名）。见 G3。
- 内容数据体检（A18 已建立）：`tools/check_content_health.gd` 输出
  `CONTENT-HEALTH: 27 chapters / 275 levels / 0 problems (orphans=0)`——
  27 章 / 275 关全部有名字与场景、场景文件都存在、内容引用（lab/sequence/conic/method）都能定位到组键、
  关卡 id 全局唯一、无孤儿组。运行时只做轻量版（课程表结构），深度版在 CI 与发版前。见 A18。
- 代码结构红线（A4，2026-10-21 A18 后）：`scripts/rules/*.gd` 每文件 ≤200（当前最大 **PlayerRules 195**，
  本轮新增 `ContentHealth 122`；`UserStore 164` / `ReportRules 168` / `ReportExport 54`）、
  `GameData.gd` ≤1600（当前 **1579**，存档层已拆到 `rules/UserStore.gd`）、
  `TheoremTree.gd` ≤1550（**1544**）、`StageBase.gd` ≤1200（**1197**）。
  `tools/check_all.gd` 超限即红灯。

### 9.3 审计数据的复现方法

本轮统计用一次性 Node 脚本完成（**未入库**，若需要建议按 A5 落成 `tools/check_questions.gd` 的 GDScript 版）：

1. 扫描范围：`data/*_levels.json`（26 个；`questions.json` 已随 A12 删除）；
2. 「一题」判定：对象同时含 `q` 与 `opts`；
3. 「一关」判定：顶层键下含 `levels[]` 数组；
4. 统计项：题量、选项数、`ans` 取值分布、选项是否图片（`res://*.png`）、
   题干长度/选项长度均值、`type` 取值、`hint/explain/success/ask` 覆盖率、
   轮次标签编号 vs 关卡序号、图片选项计数、题干重复。
