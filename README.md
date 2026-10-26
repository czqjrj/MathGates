# MathGates

# 衍数阁(高中数学闯关游戏)

Godot 4.7(Compatibility / GL)制作的数学闯关学习 App。UI 全程代码绘制(玻璃拟态),数据/题目走 JSON,单个模块带交互探索器。

## 目录结构

```
scenes/          场景 .tscn(主体均由代码构建,tscn 只是空壳挂脚本)
scripts/         总控与共享逻辑(按职责分目录)
  autoload/        GameData.gd(课程表/进度/多用户存档/错题统计)、Settings.gd(字号/音效/萌宠/
				   全屏/动效,持久化到 user://settings.json)、Sound.gd(音效,启动预载/按钮自动接线)、
				   Toast.gd(飘字提示)、Scene.gd(场景跳转)
  ui/              UI.gd(设计系统:着色 token、字号系数 S(默认 1.4,由 Settings 注入)、fs() 换算、
				   按钮/卡片/弹窗)、Art.gd(美术资源自动加载,有图用图无图退回代码绘制)、
				   Palette.gd(绘图统一配色)、Confetti.gd(通关彩带)、Pet.gd(萌宠,全代码绘制)、
				   TechBg.gd(科技背景)、Tts.gd(语音朗读:TTS 子系统,UI.tts_* 为薄转发)、
				   InlineMath.gd(内联公式:{f:名称} 与 data/inline_math.json,UI.inline*/strip_formulas 为薄转发)、
				   TtsOnline.gd(在线语音)、
				   ContentFallback.gd(A18 内容数据异常时的用户可见兜底:兜底卡/主城横幅/复制错误信息)、
				   GuideOverlay.gd(F6 首次引导绘制:多步气泡 + 图例卡 + 帮助面板)
  save/            SaveIO.gd(存档原子读写:临时文件校验 + 备份 + 替换;F5 起还含用户存档读取
				   [升版迁移 + 主档/备份/旧档三级兜底] 与带版本号写入;GameData 存档 IO 委托于此)、
				   SaveMigrate.gd(F5 存档 schema 版本号 + 升版迁移钩子)、
				   ProgressCode.gd(F5 进度导出/导入文本码:单个用户存档 ⇄ 可复制的 `MG1:` 码,不联网)
  screens/         BootSplash.gd(品牌启动屏,规避引擎启动屏缩放 bug)、Login.gd、MainHub.gd、
				   WorldMap.gd、UserProfile.gd、LearningReport.gd(学习报告/家长视图 G3)、
				   SettingsMenu.gd、ChapterNode.gd、
				   StageBase.gd(闯关共享骨架:
				   HUD/答题面板/选项/结算/上下关导航;由 LabStage、Lab3DStage 继承,
				   服务于圆/椭圆/向量/直线及各 LAB 章节,以及立体几何/空间向量的 3D 章节)
				   (历史:原 Battle.gd 通用战斗/占位关卡已于 2026-10-20 随 TODO A3 删除——
				   275 关全部带 scene,回退路径不可达;关卡缺 scene 时现在报错并回主界面)
  modules/         知识模块:conic/ lab/ lab3d/ line/ sequence/ solid/
				   lab/ 为通用三阶段 2D 闯关(LabStage + LabPlane:滑块/拖动实时重绘 + 读数),
				   承载圆/椭圆/向量/直线等章节;line/ 仅余 TheoremTree.gd(被知识树共用);
				   lab3d/ 为通用三阶段真实网格 3D 闯关(Lab3DStage + Lab3DView + SolidBuilder + NumExpr:
				   可旋转/缩放 3D 视口 + 参数滑块实时重建 + 生长/演示动画),
				   承载立体几何初步(solid_basic)与空间向量与立体几何(space)
  rules/           纯规则层(A4 上帝对象拆分的落点:无全局状态、可单测,门面方法留在原文件):
				   PlayerRules(称号/勋章/防刷)、EconomyRules(经济结算)、PetRules/MasteryRules、
				   StageRules(结算/答题乱序/填空解析)、StageText(结算文案:评级/三星提示)、TreeRules(知识树分组/解锁/奖励文案)、
				   CurriculumRules(教材排序/章节合并)、
				   GuideRules(F6 首次引导:步骤表/图例条目/显示判定/重置)、
				   SrsRules/SrsStore(G1 错题间隔重复:阶梯/到期/毕业 + 排程存取)、
				   UserStore(存档层:存档 dict ⇄ 运行时字段转换 + 脏档兜底)、
				   ReportRules/ReportExport(G3 学习报告:日历日/活动日志/汇总/家长视图 + 文本·CSV·JSON 导出)、
				   ContentHealth(A18 内容数据完整性检查:章节结构/关卡 id 唯一/场景存在/内容引用定位);
				   单文件 ≤200 行红线
data/            课程表与题库 JSON(curriculum/questions + 各模块 *_levels.json)
				  + meta.json(A15 元游戏内容:头像/称号/勋章/每日任务/领域/萌宠形态/碑文)
				  + knowledge_map.json / textbooks.json 等;
art/             美术 PNG/WebP + 公式小图 + Android 图标 + 标题字体(art/fonts/,放入行书 ttf 即自动启用)
audio/           音效 wav
tools/           开发/测试脚本:check_all.gd(脚本检查)、check_questions.gd(内容校验器:
				 结构/答案范围/选项与题干重复/轮次编号/公式覆盖 + 内容看板,含基线机制)、
				 check_questions_baseline.txt(已知问题基线)、fix_labels.gd(轮次标签编号批量重编:
				 预览/--apply,文本级替换保留排版)、smoke_scene(全场景冒烟)、
				 pack_math_res(把 gdextension/res 打包为 res.bin,排除 GPLv3 字体)、
				 optimize_art(A13 降采样超大图,默认 dry-run)、check_assets(A13 资源入库/体积护栏)、
				 check_knowledge(E1 知识点覆盖矩阵校验+生成 docs/知识点覆盖矩阵.md,
				 关卡↔知识点同步/未覆盖缺口基线)、knowledge_gaps_baseline.txt(硬缺口基线)、
				 check_content_health(A18 内容数据完整性闸门:章节结构/关卡 id 唯一/场景存在/内容引用定位,
				 CI 与发版前各跑一次,坏数据不许出包)、
				 bump_version(F2 发版:一处改版本,多预设同步)、
				 capture_scene(截图)、dev_seq(单关调试)、
				 lab3d_render_check(立体几何/空间向量 3D 场景渲染自检,需真实窗口)、
				 json_text(G2 JSON 文本级修改工具:括号匹配定位,不重排文件)、
				 LevelPreview.tscn + level_preview.gd(G2 关卡预览器/编辑器,见「关卡作者工具链」)、
				 scaffold_level.gd(G2 关卡脚手架:一键生成新关卡组骨架,默认 dry-run)、
				 check_param_masters.gd + param_master_baseline.txt(B1 参数母版→LabPlane 引擎方言闸门,
				 存量基线,修一条删一行)、fix_param_master_dialect.py(按上述闸门修数据:比较式读数→
				 偏差读数、pow→乘法、繁转简;行级替换不重排 JSON,默认 dry-run)
tests/           回归测试(GameData 纯逻辑)
build/           导出产物(APK,git 忽略)
```

### 代码结构红线(A4 验收)

纯逻辑放 `scripts/rules/`(无全局状态、可单测,门面方法留在原文件);三个历史大文件设行数上限,
`tools/check_all.gd` **超限即红灯**(CI 挡合并):

| 文件 | 上限 | 现状(2026-10-21) |
|---|---|---|
| `scripts/rules/*.gd`(每文件) | 200 | 最大 PlayerRules 195 |
| `scripts/autoload/GameData.gd` | 1600 | 1579 |
| `scripts/modules/line/TheoremTree.gd` | 1550 | 1544 |
| `scripts/screens/StageBase.gd` | 1200 | 1197 |

超限的处理:**先拆纯规则**(可单测逻辑进 rules/,门面转发留原处),而不是改上限;
确需上调上限时须在 `TODO.md` 记录理由。

### 动效清单：装饰动效 vs 表意动效（D1~D4）

动效分两类，**语义不同、开关也不同**：

| 类别 | 归属 | 作用 | 可关闭 |
|---|---|---|---|
| **装饰动效** | `scripts/ui/Vfx.gd`（9 原语：`burst`/`star_burst`/`celebrate`/`ring`/`float_text`/`screen_flash`/`wobble`/`shake`/`coin_fly`）+ `Confetti`/`ComboBar`/`BossHud`/`ProgressLine`/`MedalBadge`/`BrandMark` | 强化「对/错」的情绪反馈 | ✅ `UI.animations` |
| **表意动效** | `scripts/modules/lab/LabPlane.gd`（2D）+ `scripts/modules/lab3d/Lab3DView.gd`（3D） | 表达**数学关系**：参数怎么改、图形哪里变 | ❌ 不跟随装饰开关（关掉会丢信息） |

**表意动效原语（2D，均由 `scene` 数据驱动或自动生效）**

| 原语 | 触发 | 数据键 / 实现 | 表达什么 |
|---|---|---|---|
| `tween` | 滑块值变化 | `_disp` + `TWEEN_TAU=0.13s` 指数缓动 | 「量在连续变化」而不是两张静态图 |
| `ghost` | 一次变化开始 | 自动（`_ghost_disp`，0.55→0 淡出） | 「从哪里来」——旧状态浅色轮廓 |
| `trace` | 变化过程中 | 自动（动点屏幕坐标 ≤14 帧，1.6/s 淡出） | 「走过的路」——动点轨迹 |
| `delta_highlight` | 变化过程中 | 自动（对 `readouts` 用旧参数重算比对） | 「哪一项变了、往哪边变」（高亮条 + ▲/▼） |
| `pulse_at` | 停稳后一次 | `"pulses": [{ "p": [x,y], "label": "切点" }]` | 「临界/特殊点在这里」（切线点、最低点…） |
| `link_line` | 常驻 | `"links": [{ "a": [x1,y1], "b": [x2,y2], "label": "|OP|" }]` | 两个几何量的联动（流动虚线） |

**演示播放（`anim`）**：`scene.anim` 为步骤数组，`Lab3DView.play_anim` 支持
`view`/`rotate`/`vars`/`reveal`/`highlight`/`pulse`；`LabPlane.play_anim` 支持 `vars`/`reveal`
（`view`/`rotate`/`pulse`/`highlight` 在 2D 无对应语义，安全忽略）。覆盖率见 `check_questions` 看板。

**演示控制（D4）**：两个播放器都有 `pause/resume/toggle_pause/restart/step`；
3D 工具条提供「▶ 演示 / ⏸ 暂停 / ↻ 重播 / ⏭ 单步」，2D 右上角提供「▶ 演示（可暂停）/ ↻」。

**动效令牌（D4）**：时长**唯一来源**是 `UI.DUR_*`，新代码禁止裸写秒数——
`tools/check_all.gd` 用括号深度扫描取「顶层第 4 个实参」，裸数字即 `BARE-DURATION` 红灯（已做反向验证）。
缓动统一走 `UI.ease(tw)` / `UI.EASE_*`。

| 令牌 | 秒 | 用途 |
|---|---|---|
| `DUR_TINY` | 0.08 | 即时反馈（按压、闪一下） |
| `DUR_FAST` | 0.14 | 小元素进出 |
| `DUR_NORMAL` | 0.22 | 常规过渡 |
| `DUR_SLOW` | 0.30 | 面板、大块内容 |
| `DUR_XSLOW` | 0.45 | 强调 |
| `DUR_LONG` | 0.70 | 长过渡（Boss 退场） |
| `DUR_SCENE` | 0.85 | 启动/场景级 |
| `DUR_AMBIENT` | 1.7 | 环境律动（标题呼吸） |

**开关语义（D4）**：`UI.animations`（装饰总开关）与 `UI.reduced_motion`（减弱动效档，设置里可开）
都只影响**装饰**动效（`UI.fx_on()`）；**表意动效不读这两个开关**——
减小动效不会关掉「参数怎么变、图形哪里变」的信息。

> 边界：**直接拖拽不补间**。分段函数分界线（`begin_break`）与拖点（`begin_drag`）必须跟手，
> 已清空 `_disp`；补间只用于「间接调参」（滑块）。

## 桌面端键盘操作（F4）

`scripts/autoload/KeyNav.gd`（全局 autoload）只处理**未被 UI 消费**的按键
（`_unhandled_key_input`），所以输入框打字、按钮聚焦时的 Enter/Space 都不受影响。

| 键 | 行为 |
|---|---|
| `1`~`9` | 选中第 n 个选项（与鼠标点击走**同一个** `pressed` 回调） |
| `Enter` | 实验轮「确认」优先 → 其次「下一关」→ 最后激活当前焦点按钮 |
| `←/→/↑/↓` | 在「选项 → 下一关 → 提示」之间移动焦点（焦点环由按钮 focus 样式显示） |
| `H` | 提示 |
| `W/A/S/D` | 3D 关卡调整视角（`Lab3DView.key_pan`，与鼠标拖动共用 `yaw_goal/pitch_goal`） |
| `Esc` / `M` | 返回 / 静音（全局既有处理） |

竞技场（`StageBase` 子类）无需改代码即生效：KeyNav 通过 `stage.get("_opt_btns"/"_next"/"_hint"/"_kb_confirm")`
鸭子类型取控件；实验轮舞台把「确认」按钮挂到 `_kb_confirm` 即可让 Enter 提交。
冒烟覆盖：`Tests._test_keyboard_nav`（18 断言，含 test double 与真实 `Lab3DView`）+
`UiSmoke._test_keyboard_stage`（真实 `LabStage` 上数字键走同一回调）。

## 性能与静止降耗（F3）

静止时**不该有每帧开销**：

| 模块 | 策略 |
|---|---|
| `Lab3DView` | 空闲 8s 停自转；相机稳定且空闲 10s → `SubViewport.UPDATE_DISABLED`（保留最后一帧纹理）；停帧后 `_process` early-return；任何交互/动画 `_wake()` 立即恢复 |
| `LabPlane` | 只在「入场显现 / 演示 / 补间 / 残影 / 轨迹 / 脉冲 / 流动虚线 / 拖拽」时 `queue_redraw()`；静止不重绘（`redraw_count` 可断言） |
| `TechBg` | 动效关闭或后台时 `set_process(false)`（不是每帧空转判断），由 `Settings.changed` / 恢复通知拉起 |
| 前后台 | `NOTIFICATION_APPLICATION_PAUSED/FOCUS_OUT` → 停帧；`RESUMED/FOCUS_IN` → 恢复 |

**基线探针**（headless 可跑，输出 `PERF <case> proc_avg_us …`）：

```
& "<godot4.7.2.exe>" --headless --path . res://tools/perf_probe.tscn
```

2026-10-21 实测（headless，CPU 处理耗时）：`idle` 171 µs；`lab_plane` 静止 259 µs（修复前 ≈73,430 µs）；
`lab3d` 静止 251 µs（修复前 ≈70,262 µs）。
**Android 真机的 FPS / 功耗 / 内存需真机测量**——headless 无 GPU，这里只看 CPU 回归趋势。

## 错题间隔重复（G1）

错题不再「错一次就永远排在前面」，而是按**遗忘曲线**排程：答对一次往后推，答错打回重来。

| 环节 | 规则 |
|---|---|
| 间隔阶梯（Leitner 分箱） | 新错 → 明天；每连续答对一次进一档 → **1 / 3 / 7 / 16 / 35 天**（末档夹取） |
| 答错 | 阶梯归零、错次 +1、明天再来；**今天刚错的题今天仍算到期**（保留「错题优先」的即时复练） |
| 毕业 | 连续答对 **4** 次即出计划，不再排程 |
| 奖励 | 复习答对 **+2 金币**（同一题当日只发一次，防刷）；毕业 **+5 金币** |
| 到期日 | 用**日序号**（本地日历日）而非时间戳，避开时区与夏令时漂移 |

**入口**

- 首页顶栏「**复习 N**」——今日有到期错题时才出现，点击直达第一道到期题的关卡与题号；
- 错题本「**今日待复习**」卡片——按到期顺序列出，一键「开始复习」；概览里有「今日待复习」计数；
- 每条错题后标注状态（「今天到期」「3 天后复习」「已逾期 2 天」）；
- 萌宠派单与关卡内复习排序都改成**到期优先**（同到期日按错次多优先）。

**兼容**：`srs_plan` 是**新增**存档字段，与旧 `wrong_log` 并存；旧档只有错题记录、没有排程的，
一律视为「立即到期」，加载即用，不需要迁移脚本。

代码分层（守 A4 行数红线，纯逻辑进 `rules/`）：
`scripts/rules/SrsRules.gd`（单条排程怎么算：阶梯 / 到期 / 毕业 / 当日奖励去重）+
`scripts/rules/SrsStore.gd`（整本排程怎么存怎么查：存档、清单、排序、任务组装）；
`GameData` 只留门面（`srs_due_list()` / `srs_due_count()` / `srs_due_text()` / `review_order()`）。

覆盖：`Tests._test_srs_rules` + `_test_srs_store` + `_test_srs_flow`（模拟 5 天推进 1/3/7/16/35、
答错重置、连对毕业、旧档兜底、当日不重复计奖）+ `UiSmoke._test_srs_review_entry`
（首页「复习 N」按钮与错题本「今日待复习」卡片真实构建）。

## 学习报告 / 家长视图（G3）

学习不再只有「当前状态」一个快照，而是有**时间维度**：每天记一笔活动（作答 / 答对 / 新增星 /
通关 / 复习），攒成可回看的**逐日趋势**；家长侧只看**汇总量与领域级薄弱点**，看不到题目。

| 环节 | 规则 |
|---|---|
| 活动日志 | `activity` 按天一条 `{date, answered, correct, stars, clears, reviews}`，**最多保留 120 天**（更早裁掉，存档不无限膨胀） |
| 报告周期 | 「本周」= 近 7 天、「本月」= 近 30 天；窗口内逐日补行，**沉默的日子也画出来**（空档本身就是信息） |
| 薄弱点 | 取自诊断结果的**领域级**掌握度 + 错次；只有领域名，**不带关卡名与题目原文** |
| 家长视图 | 只读摘要：学习量 / 正确率 / 活跃天数 / 新增星 / 需关注领域 + 一句建议；**默认本地生成、不联网、不上传** |
| 导出 | 文本周报（可复制到剪贴板）、CSV（逐日明细）、JSON（结构化）——都写到应用私有目录 `user://` |

**入口**：首页顶栏「报告」、档案库「学习报告 · 家长视图」卡片 → `res://scenes/LearningReport.tscn`。
报告页从上到下：学习概览 → 逐日趋势柱状图 → 薄弱领域 → 可分享的报告文本 → 家长视图 → 导出数据。

代码分层（守 A4 行数红线，纯逻辑进 `rules/`）：
`scripts/rules/ReportRules.gd`（日历日换算 / 活动日志 / 汇总 / 薄弱点 / 家长视图）+
`scripts/rules/ReportExport.gd`（文本周报 / 家长建议 / CSV / JSON 序列化）；
`GameData` 只留门面（`report_summary()` / `report_weak()` / `parent_view()` / `report_text()` / `report_csv()` / `report_json()`）。

同时完成 **A4 遗留：存档层拆分**——`scripts/rules/UserStore.gd` 接管存档 dict ⇄ 运行时字段的
全部转换（`_blank_user` / `_snapshot` / `_apply` / 错题 module 迁移），`GameData.gd` 从 1593 行降到 1558 行；
脏档兜底（字段缺失 / null / 类型不对 → 取默认值，不让载入炸掉）。

覆盖：`Tests._test_user_store` + `_test_report_rules` + `_test_report_flow`（日历日往返与闰年、
活动日志累加与排序、汇总正确率与活跃天、家长视图**不泄露题号与题目原文**、三种导出可用、存档往返）
+ `UiSmoke._test_report_screen`（报告页真实构建、周期切换切到 30 天、导出按钮存在、隐私说明可见）。

## 存档版本化与进度迁移（F5）

存档**带 schema 版本号**，载入时自动升版；进度可**导出为一段 `MG1:` 文本码**、在另一台设备导入恢复，
不引入账号体系、不联网。换手机 / 重装 / 清数据前导出一段码即可保住 228 关星级、勋章、萌宠与错题本。

| 环节 | 规则 |
|---|---|
| 版本号 | 存档顶层 `schema` 整数（当前 `SaveMigrate.CURRENT`）；**每次改存档结构必须 +1 并补一段迁移** |
| 迁移 | `SaveMigrate.migrate()` 把任意版本升到当前；无 `schema` 的历史档视为版本 **0**（字段全靠默认值兜，0→1 仅登记版本、不动数据） |
| 高版本档 | 来自更新版本的存档**不静默降级**：照读但 `downgraded=true`，由上层警示（避免「新设备导出、旧版导入」悄悄丢字段） |
| 三级兜底 | 载入顺序：主档 → 备份 → 旧版单人档（`save.json` → 迁移为「推演者」）；从备份恢复后立即写回主档 |
| 导出/导入 | `ProgressCode` 把**单个用户**的存档编成 `MG1:` + Base64(JSON)；导入时解码 + 升版，重名自动加 ` (2)` 后缀，**绝不覆盖既有进度** |
| 隐私 | 文本码是**明文**（Base64 只是编码，非加密），界面提示用户「像密码一样保管、勿公开分享」；全程本地、不上传 |

**入口**：档案库页「进度备份 · 跨设备迁移」卡片——「导出进度码」复制到剪贴板并写一份到 `user://progress_<用户名>.txt`；
「从进度码导入」弹出多行输入框，粘贴后先给出摘要（★数 / 作答 / 错题 / 勋章 / 萌宠形态）供确认，再新建用户。

代码分层（守 A4 行数红线）：`scripts/save/SaveMigrate.gd`（schema + 迁移钩子）+ `scripts/save/ProgressCode.gd`
（文本码编解码 / 摘要 / 命名去重）纯规则；`SaveIO.load_users()` / `write_users()` 接管用户存档的读取（含迁移 + 三级兜底）
与写入；`GameData` 只留门面（`export_code()` / `import_code()`），用户列表聚合下沉到 `UserStore.list_summaries()`。

覆盖：`Tests._test_save_migrate`（旧档→0 版本、幂等、高版本降级标记、不就地改入参）+ `Tests._test_progress_code`
（encode/decode 往返、摘要不含题号与用户名、折行容忍、六类坏码一律拒绝、命名去重、`GameData` 导出→导入完整恢复）。
**未覆盖（人工验收）**：真机两台设备间导出→导入的端到端目视核对（F5 验收项中的人工部分）。

## 首次引导与机制说明（F6）

新用户第一次进来时，以前的机制说明是**分散且隐式**的：关卡里的 `tip`/`hint`、探究轮的 `goal`、
萌宠台词——都得学生自己先点出来才看得到。现在：**一次性引导**在首次进入时自动讲清玩法，
「? 帮助 / ? 图例」按钮让它**随时可回看**，设置页可**重置**。

| 环节 | 做法 |
|---|---|
| 第一关引导 | 4 步气泡：① 先动手调一调（拖滑块/拖点，图立刻重画）→ ② 提交答案（选选项或填答案）→ ③ 看解析（提示会扣评分）→ ④ **三星怎么拿**（全对且无提示＝三星，错一点＝两星，通关＝一星） |
| 地图图例 | 首次进入知识体系页弹一次，讲清四类标记：**Boss 门**（本单元累计星数达标解锁）/ **宝箱**（星数门槛后可开启）/ **随机事件**（通关触发一次）/ **支线**（选做路线，不影响主线） |
| 随时回看 | 关卡动作条「? 帮助」回看第一关引导；地图顶栏「? 图例」回看图例；两者都**不改变**「已看过」状态 |
| 重置引导 | 设置页「重置引导」清空已看过记录，下次进入关卡/地图重新弹出 |
| 动效解耦 | 引导属**表意内容**：关掉「界面动效」只弱化入场动画，**文字照常显示**（与 D4 语义一致） |
| 状态存放 | 引导状态是**设备级 UI 偏好**，存 `Settings.seen_guides`（`user://settings.json`），**不进学生存档**、不动 F5 的存档 schema |

代码分层（守 A4 行数红线）：`scripts/rules/GuideRules.gd`（步骤表 / 图例条目 / 显示判定 / 重置 / 标记，纯数据）
+ `scripts/ui/GuideOverlay.gd`（气泡与图例卡绘制）；`Settings` 提供 `guide_needed()` / `mark_guide_seen()` / `reset_guides()`。
顺带把两个纯逻辑从大文件下沉（A4）：`StageRules.next_star_hint()` → 新文件 `scripts/rules/StageText.gd`
（结算文案，与星级判定分离）、`TheoremTree._reward_text()` → `TreeRules.reward_text()`（宝箱/事件共用）。

覆盖：`Tests._test_guide_rules`（步骤 3~4 步与顺序、图例四类、文案拼接、看过/未看过判定、
`mark_seen`/`reset` 不就地改入参、关动效仍判定显示）+ `Tests._test_stage_rules`（`next_star_hint` 六种局面）
+ `Tests._test_tree_rules`（`reward_text` 五种组合）+ `UiSmoke._test_guides`（关卡页确实弹出遮罩与首步文案、
动作条有「? 帮助」、地图页有「? 图例」且首进弹出图例卡、设置页有「重置引导」）。
**未覆盖（人工验收）**：全新安装的学生「仅凭引导完成第一关并说清三星怎么来」的端到端目视核对。

## 内容数据体检 / 用户可见兜底（A18）

内容数据一旦出问题（课程表损坏、关卡 id 撞车、题目引用指向不存在的组），以前的表现是
控制台一句 `push_error` + **一张空白页**——学生只看到没有任何解释的空知识体系。
现在：**体检**把坏数据翻译成问题码，**运行时**给说人话的兜底卡，**发版前**由 CI 闸门挡住。

| 环节 | 做法 |
|---|---|
| 体检规则 | `scripts/rules/ContentHealth.gd`（纯规则，可单测）：课程表非空、每章至少 1 关、**关卡 id 全局唯一**、关卡有名字与场景、场景文件存在、内容引用（lab/sequence/conic/method）能定位到数据文件里的组键 |
| 问题码 | `E_EMPTY` / `E_DUP_ID` / `E_NO_LEVEL` / `E_NO_TITLE` / `E_NO_SCENE` / `E_BAD_REF` / `E_LOAD`——UI 文案与 CI 输出**共用一套**，不两处各说各话 |
| 运行时兜底 | 内容坏掉时知识体系页不再空白：铺一张兜底卡（发生了什么 / 出在哪 / 怎么办），主城顶部挂一条横幅；动作有「**重试加载**」与「**复制错误信息**」 |
| 隐私 | 错误详情**只写进用户自己的剪贴板**，不联网、不上传（与 F1 一致）；详情里只有内容结构信息，不含任何作答数据 |
| 发版闸门 | `tools/check_content_health.gd`：深度体检（场景文件是否存在、引用能否定位）+ 孤儿组提示；接进 CI（`CONTENT-HEALTH-FAIL` 即红灯），坏数据不许出包 |

体检**运行时只做轻量版**（只查课程表结构，启动开销小），深度版留给 CI 与发版前。

代码分层（守 A4 行数红线）：判定全在 `scripts/rules/ContentHealth.gd`（不读文件、不碰 autoload，
入参是章节数组 + 已知场景集合 + 内容组键表）；`GameData` 只留门面
（`content_ok()` / `content_health()` / `reload_content()`）；界面兜底在 `scripts/ui/ContentFallback.gd`
（兜底卡 / 主城横幅 / 复制文本）。

**体检一上线就抓到一个真 bug**：`solid_angle` 这个关卡 id **被两个章节同时占用**
（`solid` 章的「线面角 · 二面角」与 `solid_basic` 章的「11-1 空间角（几何法）」）——
星标按 id 存，两关共用一条记录，一关通关另一关会跟着亮。已把后者改名为 `solid_basic_angle`
（知识点覆盖矩阵同步更新），并用单测**守住「id 全局唯一」**。

覆盖：`Tests._test_content_health`（空表 / 重复 id / 空章节 / 缺名字 / 缺场景 / 场景不存在 /
引用定位不到 / 引用映射 / 真数据必须体检通过）+ `UiSmoke._test_content_fallback`
（兜底卡文案与按钮、主城横幅、铺页替代空白页、复制文本只含结构信息）。

## 自检与 CI

**一条命令跑完全部 11 项**（自动找 Godot 4.7.2、自动 `--import`、失败给日志路径、全绿退出码 0）：

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_checks.ps1        # 约 150 秒
powershell -ExecutionPolicy Bypass -File tools\run_checks.ps1 -Fast  # 跳过 UI-SMOKE / LEVEL-PREVIEW
powershell -ExecutionPolicy Bypass -File tools\run_checks.ps1 -Godot "<godot472.exe>"   # 引擎不在常见路径时
```

换机后**先跑它**：全绿说明环境与基线一致。不绿先解决环境，别动代码。

单项手工跑（顺序任意，全绿才提交）：

```
& "<godot4.7.2.exe>" --headless --path . --script res://tools/check_all.gd
& "<godot4.7.2.exe>" --headless --path . res://tests/Tests.tscn
& "<godot4.7.2.exe>" --headless --path . res://tools/smoke_scene.tscn
& "<godot4.7.2.exe>" --headless --path . res://tests/LabSmoke.tscn
& "<godot4.7.2.exe>" --headless --path . --script res://tools/check_questions.gd
& "<godot4.7.2.exe>" --headless --path . --script res://tools/check_content_health.gd
& "<godot4.7.2.exe>" --headless --path . --script res://tools/check_param_masters.gd
```

- `check_questions.gd`：有**新增**内容问题即退出码 1；存量问题记在
  `tools/check_questions_baseline.txt`（修完删对应行）。
  确认新问题是历史遗留而非本次引入时，可 `-- --write-baseline` 记入基线。
- `check_content_health.gd`：内容数据完整性闸门，输出
  `CONTENT-HEALTH: N chapters / N levels / 0 problems`；有问题是 `CONTENT-HEALTH-FAIL` + 非零退出。
  改 `curriculum.json` / `*_levels.json` 后**必跑**（改坏了的引用与重复 id 靠它兜）。
- `check_param_masters.gd`：**B1 参数母版脚手架 → 引擎方言**闸门，输出
  `PARAM-CHECK: N files / N levels / N scenes / 0 new / N known / N warnings`。
  这批 `data/param_master*.json` / `data/*_param_auto.json` **不以 `_levels.json` 结尾**，
  上面两个闸门的扫描口径都不覆盖它们——字段写成引擎不认识的样子时**不会有任何红灯**，
  接进关卡才是静默坏给学生看（视野中断 / 曲线全画成正弦波 / 读数恒为 0 / 门控永远不过）。
  存量 96 条记在 `tools/param_master_baseline.txt`，**改一条删一行**；删干净才谈接入。
  其中「不需要设计决策」的两类已由 `tools/fix_param_master_dialect.py` 修掉（155 → 96）。
  白名单（曲线类型 / 表达式函数）由 `_self_check()` 回读 `LabPlane` 源码核对，防口径漂移。
- 以上检查已接入 CI（`.github/workflows/check.yml`，push/PR 自动跑）：五件套 + UiSmoke + check_assets +
  check_questions + check_knowledge + check_content_health + check_param_masters +
  LevelPreview 自检（`-- --smoke`）+ scaffold dry-run。

## 关卡作者工具链（G2）

写/改关卡不再手抄 JSON，推荐流程：

1. **脚手架**生成骨架（免手抄样板，并自动挂 curriculum + 知识点）：
   ```
   & "<godot4.7.2.exe>" --headless --path . --script res://tools/scaffold_level.gd -- `
	   --file=inequalities_levels --key=ineq_demo --chapter=inequalities --apply
   ```
   默认 dry-run 只打印骨架；`--chapter` 会同步追加 `curriculum.json` 该章 levels 与
   `knowledge_map.json` 该章 points（E1 联动，漏挂知识点 CI 会红）。
2. **预览器**里「选关 → 看效果 → 改题干/选项/ans/scene → 写回 JSON → 立即刷新」：
   ```
   & "<godot4.7.2.exe>" --path . res://tools/LevelPreview.tscn
   ```
   - 右侧用**真实舞台**渲染（LabStage/Lab3DStage/SequenceStage 等），所见即学生所见；
   - 数据文件被外部修改后 ~0.7s **自动热重载**；
   - 内置 A5 轻量校验（轮次编号/ans 范围/选项重复/题干缺失），写回后自动复检；
   - 写回走 `tools/json_text.gd` **文本级修改**，只动目标字段、不重排文件（diff 最小）；
   - 代码驱动的官方收编关（SolidChallenge 方法关 / ConicStage C1~C3，TODO A2 收编）只读预览。
3. 填完内容后按「自检与 CI」一节跑全量校验，别忘了 `fix_labels --apply` 规范轮次标签。

## 运行

本项目引擎 exe 在 `Downloads\Godot_v4.7.2-stable_win64.exe\` 目录内部:

```
& "C:\Users\Administrator\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path . --editor
& "C:\Users\Administrator\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path . --import
```

## 导出 Android(离线关键点)

- 本机无法访问 `services.gradle.org`,**必须** `use_gradle_build=false`(直接模板打包)。
- 同理由此 `compress_native_libraries=false`。
- 编辑器设置(全局):`export/android/android_sdk_path=C:\Android\Sdk`、`export/android/java_sdk_path=C:\Android\jdk17`。
- 导出命令:
  ```
  & "…\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path . --export-debug "Android" "build/衍数阁.apk"
  ```
- `android/` 与 `build/` 是导出工作目录,可随时删除,下次导出自动重建。

## 手机适配约定

- 画布 1280x720,`canvas_items` 拉伸 + `expand`。
- 字号经 `UI.fs()`(系数 `UI.S`)换算,调大 `S` 即可整体放大;勿在代码里写裸字号。
- 已锁定横屏(`sensor_landscape`)。
- 启动屏:场景级 `BootSplash` 显示文字标语;安卓原生启动屏图标为透明占位(避免引擎启动屏"小图→放大"问题),`splash_screen/disable_godot_boot_splash=true`。

## 改内容

- 课程/章节/解锁关系:`data/curriculum.json`
- **元游戏内容(A15)**:头像、称号阶梯、勋章(展示字段 + 达成规则)、每日任务、知识领域、萌宠形态名、馆灵碑文,全部在 `data/meta.json`。改文案/加勋章/调阈值**不用改代码**;勋章 `id` 是存档契约(`medals{}`/`pet_parts{}` 按 id 存),**改名必须配迁移**。改完 `check_content_health` 会验 id 唯一/必填字段/称号比例单调/领域↔碑文一一对应。
- 教材版本(苏教/人教A/人教B/北师大/湘教/沪教):分册、章节排序与章号:`data/textbooks.json`
- 各模块关卡:**全仓只有一份权威题库 `data/*_levels.json`**(原通用题库 `data/questions.json` 与 Battle 兜底关卡已于 2026-10-20 随 TODO A3/A12 删除——其 42 题仅被 Battle.gd 消费且 275 关全部带 scene,通道不可达)。几何类章节(圆/椭圆/向量/直线)已统一为 `lab` 三阶段格式,对应 `circle_levels.json / ellipse_levels.json / vector_levels.json / line_levels.json`,场景统一为 `res://scenes/LabStage.tscn`
- 立体几何 / 空间向量章节已统一为 `lab3d` 三阶段真实 3D 格式,对应 `solid_basic_levels.json`(立体几何初步,含「基本事实(公理)」旗舰关 `solid_axiom`)与 `space_levels.json`(空间向量与立体几何),场景统一为 `res://scenes/Lab3DStage.tscn`。3D 场景描述见 `scripts/modules/lab3d/SolidBuilder.gd`
- 立体几何方法讲解:`data/solid_methods.json` + `scripts/modules/solid/topics/*.gd`
- **文件名 ↔ 场景/章节对照表（A17 防呆）**：

  | 场景 | 数据文件 | 关卡字段 |
  |---|---|---|
  | `LabStage.tscn` | `data/<lab>_levels.json`（`set_logic`/`functions`/`vector`/`line`/`ellipse`/`circle`…） | `lab` |
  | `Lab3DStage.tscn` | `data/<lab>_levels.json`（`solid_basic`/`space`） | `lab` |
  | `SequenceStage.tscn` | `data/recurrence_levels.json` | `sequence` |
  | `SolidChallenge.tscn`（**官方收编**，A2） | `data/solid_methods.json`（嵌套 `methods.{id}.levels`） | `method` |
  | `ConicStage.tscn`（**官方收编**，A2） | `data/conic_levels.json` | `conic` |

  ⚠️ **易混文件名**：`conic_levels.json`（ConicStage 专用）≠ `conics_levels.json`（圆锥曲线综合章）；
  `vector_levels.json`（平面向量章）≠ `vectors_levels.json`（平面向量初步章）；
  `solid_basic_levels.json`（立体几何初步章）≠ `solid_methods.json`（方法章）。
  改错文件会**静默失效**——`check_questions` 已加自检兜底（章节 lab→文件存在性 / 孤儿文件 /
  近名对半引用即红灯）。
- **公式写法(A10)**:新题/文案里的数学式子**直接写 LaTeX,并用 `$$…$$` 包裹**(运行时由 MicroTeX 渲染成内联公式图)。例:`"q": "不等式 $$x^{2}-2x-3>0$$ 的解集是?"`。**存量迁移已完成**——全库 `data/*.json` 已无 `{f:}` 引用,`FORMULA_LATEX`/`FORMULA_SPEECH` 命名表已清空(**不再新增命名**),也不再写 Unicode 数学片段(`²`/`≤`/`α` 等;`data/inline_math.json` 已冻结为历史兼容层)。`{f:}` 机制仍在,但数据里一旦引用未声明的名字,`check_questions.gd` 会**直接报错**(根治「运行时静默变『公式』、题目不可答」);`$$…$$` 区段则被校验器忽略(见 A5/A10)。

## 内容与教材的关系

- 本项目的**课程结构**（分册、章节、顺序）对齐人教A/苏教等人教版教材的**知识点顺序**，便于按教材体系复习；
- **逐章知识点覆盖矩阵**（教材小节 → 知识点 → 关卡 id，含未覆盖缺口清单）：`docs/知识点覆盖矩阵.md`（数据源 `data/knowledge_map.json`，由 `tools/check_knowledge.gd` 校验并生成）；
- **题目均为自编**（题干、选项、解析由项目组撰写），**不逐题复制教材习题**；
- 教材名称与章节名为客观指代，相关著作权归各出版社所有，本项目与出版社无隶属关系。
  详见 `THIRD_PARTY_NOTICES.md` §5。

## 授权与第三方声明

- 项目自身授权：**专有（保留所有权利）**，见根目录 `LICENSE`；
- 第三方组件与素材清单：`THIRD_PARTY_NOTICES.md`；
- 第三方许可全文（Godot / MicroTeX 的 MIT）：`THIRD_PARTY_LICENSES.md`；
- 美术素材来源：`art/SOURCES.md`；音效来源：`audio/SOURCES.md`；
- 隐私政策：`docs/隐私政策.md`（唯一联网功能=可选的在线语音朗读，默认关闭）。

## 资源体积

- 美术**源文件**（`.xcf` 等）不入库，统一放 `assets_src/`（已 gitignore）；导出也排除。
- 降采样：`tools/optimize_art.gd`（默认 dry-run，加 `-- --apply` 写回）。
- 护栏：`tools/check_assets.gd`（源文件入库 / 体积预算，已进 CI）。
- 详见 `docs/资源优化.md`。

> 待处理（上架前必做）：替换授权不明的标题字体 `art/fonts/aidianqianfengxingshu.ttf`（13.8 MB，见 A13/F7）。

## 发版

版本号一处修改、多预设同步（`version/code`、`version/name` 与 Windows 的 `file/product_version`）：

```
& "<godot4.7.2.exe>" --headless --path . --script res://tools/bump_version.gd -- --bump patch
```

发布签名（release keystore，密钥不入库）与 Android 上架要点见 `docs/环境配置.md` §6.1。
