# TODO · 关卡游戏化（BOSS 战 → 节奏 → 地图）

> 目标：把「关卡」升级为有**节奏、张力与成长反馈**的游戏体验。
> 本文件是**可跨机器续接**的 runbook；设计稿见 `docs/关卡游戏化方案.md`（P0 已交付）。
> 与 `TODO.md`（MicroTeX 公式运行时渲染）、`TODO-lab.md`（几何章节迁移）相互独立。

---

## 0. 换机器续接指引（先读）

- 克隆 / 切分支后，**必须先让 Godot 生成全局类缓存**，否则新 `class_name BossHud` 会连锁报
  `Parse Error: Could not find type "BossHud"`（连带 `StageBase.gd` / `Battle.gd` 解析失败）：
  - 用编辑器打开项目一次；或跑一次
    `Godot_console.exe --headless --editor --path . --quit`
    （会向 `.godot/global_script_class_cache.cfg` 写入 `BossHud` 条目）。
- 引擎：**本机已升级到 Godot 4.7.2**（`D:\Program Files\Godot_v4.7.2-stable_win64.exe`，
  `project.godot` 的 `config/features` 已是 `"4.7"`）。4.4.1 仅存于下载压缩包、未解压。
  该 exe 无 console 变体：无头运行请用
  `Start-Process -Wait -RedirectStandardOutput/Error` 重定向取输出（GUI 子系统进程直连控制台会丢输出）。
- 回归四件套（改完必跑）：
  | 命令 | 期望 |
  |---|---|
  | `--headless --path . --script res://tools/check_all.gd` | `CHECKED 79 scripts, 0 failures`（仅 `third_party/` 两个历史 Parse Error） |
  | `--headless --path . res://tests/Tests.tscn` | `TESTS: 1220 passed, 0 failed` |
  | `--headless --path . res://tools/smoke_scene.tscn` | `SMOKE: 238 ok, 0 fail` |
  | `--headless --path . res://tests/LabSmoke.tscn` | 末尾 `TMP_OK`（覆盖 `space_boss`） |

---

## 1. 已完成（本次提交）

- [x] **P0 设计稿**：`docs/关卡游戏化方案.md`（现状盘点 + A/D/B/C 分期 + schema + 里程碑）。
- [x] **P1-M1 · BOSS 战层（默认关闭，叠加在 `StageBase`，2D/3D 共享）**
  - [x] `scripts/ui/BossHud.gd`（新）：从 `Battle.gd` 抽出 `HexAvatar`/`HpBar`，新增双方战斗 HUD（推演者 ↔ 守关者 + 连击）。
  - [x] `scripts/screens/Battle.gd`：改用 `BossHud.HexAvatar` / `BossHud.HpBar`（消除重复；`Battle.tscn` 仍是回退占位）。
  - [x] `scripts/screens/StageBase.gd`：Boss 层——`_boss_enabled()/_boss_config()`；`_level_ok` 扣守关者血、`_wrong` 扣推演者血；半血狂暴；推演者血量归零 → 强制失败结算；通关 → 击败演出 + 首通奖励。
  - [x] `data/circle_levels.json` → `circle_boss` 增加 `boss{}` 配置块（作为示范格式）。
- [x] 回归全绿（check_all / Tests / smoke_scene / LabSmoke）。
- [x] **P1-M2 · 5 个 BOSS 关全部成型**
  - [x] 其余 4 关补 `boss{}`：`line_boss` / `space_boss` / `vector_boss` / `ellipse_boss`（称号/皮肤/首通奖励各异）。
  - [x] **BOSS 勋章**：`boss_first`(破阵者) / `boss_all`(无冕之王) **本就已存在并接入** `_medal_met()`，无需新增。
  - [x] `tests/Tests.gd` 增 `_test_boss_data()`：校验 5 个 `boss{}` 结构合法 + `_boss_level_ids()` 恰好覆盖 5 关。
  - [x] 运行期验证（临时探针，已删除）：5 关均 `mode=true` 且 HUD 数值正确（`space_boss`→`Lab3DStage`）；
        普通关 `circle_1_1` `mode=false`；**通关(击败)结算路径 D 已跑通**（`done=true, failed=false, stars=3`）。
- 回归基线更新：`Tests: 1125 passed, 0 failed`（原 1074，+51 为 BOSS 校验）。

- [x] **P2-M3 · 关卡节奏强化（普惠所有 LAB 关，默认开、限时按关开）**
  - [x] `scripts/ui/ComboBar.gd`（新）：顶栏连击进度条 + 金币倍率。
        `ComboBar.multiplier(2..)=1+0.1*(n-2)`，封顶 `1.5`(MULT_CAP)；
        档位配色 2+金 / 3+橙 / 5+红；`set_streak(n)` 连击≥2 才显示。
  - [x] `scripts/screens/StageBase.gd`：`_combo_lbl` → `_combo_bar`；
        `rules{}` 解析(`_apply_rules`)；计时态 `_timing/_elapsed` + 顶栏计时段
        (`_process` 推进、`_refresh_time`)；结算时
        极速奖励(+40，用时≤`star_time`)、超时降星(超 `time_limit` 且 st>1 → st−1，
        最低保底 1 星)、连击倍率奖励(`round(reward*(mult-1))`)、
        `best_time` 记录与「新速度纪录」、结算「下一星差在哪」引导(`_next_star_hint`)；
        提示卡即时演出(`_use_hint` Vfx)。
  - [x] `scripts/autoload/GameData.gd`：`best_time_of()` / `record_level_time()`
        （`level_records[].best_time`，旧存档缺字段按 0，天然兼容）。
  - [x] `scripts/autoload/Settings.gd` + `scripts/screens/SettingsMenu.gd`：
        新增「关卡计时」总开关 `challenge_timer`（默认开；关闭后一律不计时）。
  - [x] `data/{line,space,vector,ellipse,circle}_levels.json`：5 个 BOSS 关加
        `rules{ star_time:150, time_limit:300, show_combo_bar:true }`。
  - [x] `tests/Tests.gd`：`_test_rhythm()`（倍率映射 / rules 结构 / best_time 读写）。
  - [x] 运行期探针（已删）验证：BOSS `timing/limit` 正确、连击条可见且倍率 1.1/1.2/1.5、
        完美通关 `st=3` 奖励 `237+200(首通)+40(极速)+95(连击×1.2)=572`、`best_time=100.0`、
        普通关不计时且 2/3 零失误给「再 1 轮…升 3 星」引导、关闭计时开关后超时不再降星。
  - 回归基线更新：`CHECKED 79 scripts` / `Tests: 1170 passed` / `SMOKE: 238 ok` / `LabSmoke TMP_OK`。

- [x] **P3 · 地图冒险化（改 `scripts/modules/line/TheoremTree.gd` + `GameData` + `curriculum.json`，全部为关卡级可选字段、缺省即旧行为）**
  - [x] **章节 Boss 门**：关卡加 `gate{ need_stars }` → 解锁改判「本单元累计星数」；
        已通关的关永不回锁；面板显示「Boss 门 · 单元星数 h/n」进度条与「再得 N ★ 即可开启」，未达标时进入按钮置灰。
  - [x] **宝箱节点**：关卡加 `chest{ need_stars, title, reward }` → 节点右下金箱角标
        (条件未达=灰 / 可领取=脉冲 / 已领取=绿)；面板内「开启宝箱」→ `GameData.claim_chest()` 发奖落盘，
        成功后 `Vfx.celebrate` 并重绘地图。
  - [x] **随机事件节点**：关卡加 `event{ title, reward }` → 节点左上菱形(未触发=青色呼吸环 / 已触发=灰)；
        面板**首次**打开即 `mark_event_seen()` 触发一次并发放奖励，重复打开不再发奖。
  - [x] **分支路线**：关卡加 `optional: true` + `after: "<level_id>"` → 该关从主蛇形路径抽离，
        归入底部「支线探索」行，并画一条二次贝塞尔弧连回 `after` 节点（主路径 Catmull 不再穿过支线点）。
  - [x] **装饰动效**：可领取宝箱脉冲环、事件菱形呼吸环、「支线」标签、**解锁礼花**
        （仅进度刷新时对本次**新解锁**的节点放一次；首次/切章重绘只登记不放）。
  - [x] **存档**：`GameData.chests_claimed{}` / `events_seen{}`（`_blank_user` / `_snapshot` / `_apply` 三处同步，旧档缺字段按空）。
  - [x] `tests/Tests.gd`：`_test_adventure()` —— 5 个几何章节的 `gate/chest/event/optional` 结构齐全、
        `optional.after` 指向存在的关卡、`stars_of` / `claim_chest` 去重 / `mark_event_seen` 幂等 / `grant_reward` 发奖。
  - [x] 运行期探针（临时工具，已删）：`P3 PROBE: 24 passed, 0 failed` —— 12 星时 Boss 锁定（`gate 12/15`）、16 星解锁；
        宝箱可领→领取后 `+120 金币`且角标转已领；事件面板首开触发 `+1 coin_boost`、二次打开不重复发奖；
        `line_6_3` 为支线节点且底部存在「支线探索」标题条。
  - [x] 真实窗口截图（`build/shots_p3/*.png`）：地图顶部 / 底部支线行 / Boss 门面板 / 宝箱面板 / 事件面板。
  - ⚠️ **范围**：`WorldMap.tscn` == `TheoremTree.gd(kind="method")`，代码同一条路径（两类章节无分支逻辑差异）。
  - ⚠️ **实现选型**：采用**关卡级**字段而非设计稿的**章节级** `map{}` —— 部分教材会把多章合并成一张卡片
        （如「圆锥曲线与方程」），章节级数据在合并下无法定位；关卡字段随合并原样保留，天然不受影响。
  - 回归基线更新：`CHECKED 79 scripts` / `Tests: 1220 passed` / `SMOKE: 238 ok` / `LabSmoke TMP_OK`。

- [x] **P4 · 窄屏 / 多分辨率验证（临时探针，已删）**
  - 结论：**出货配置下不存在窄屏挤压**。`project.godot` 为
    `window/stretch/mode="canvas_items"` + `base 1280×720` + `aspect="expand"`，
    逻辑视口宽**恒 ≥1280**（更宽的屏只加宽，4:3/竖屏只加高）：
    | 窗口 | 逻辑视口 | 顶栏 avail / need | 余量 |
    |---|---|---|---|
    | 1920×864 (20:9) | 1600×720 | 1548 / 1097 | +451 |
    | 1600×720 | 1600×720 | 1548 / 1097 | +451 |
    | 1280×720 | 1280×720 | 1228 / 1097 | +131 |
    | 1024×600 | 1280×750 | 1228 / 1097 | +131 |
    | 800×600 (4:3) | 1280×960 | 1228 / 1097 | +131 |
  - `space_boss` 顶栏 `need=1109`（较 circle_boss +12），1280 宽仍余 +119；相邻控件无横向重叠。
  - 地图面板：`line_boss`(Boss 门) / `line_3_3`(宝箱) 在 1280×720 与强制 900 宽下均 `right_over=0`
    （面板宽度自适应铺满，无溢出）。
  - 临界值（仅供参考）：**强制关闭等比缩放**（`content_scale_mode=DISABLED`，逻辑视口=窗口像素）时
    顶栏 `need=1097`，逻辑宽 **<~1149** 才会把最右侧「计时」挤出窗口（实测 900 宽时「计时 0.7s」被裁切）；
    出货配置不会走到该路径。
  - 截图：`build/shots_narrow/ship_*.png`（出货比例）、`reflow_*.png`（强制重排临界，含裁切反例）。

---

## 2. 待办

### P1 收尾（仅剩「目视」类验证，需真实窗口）
- [x] **HUD 观感**：非 headless 截图确认 5 关战斗 HUD 布局（临时工具已跑，产物 `build/shots_p12/*_hud.png`，`line/space/vector/ellipse/circle` 五关 HUD 均正常：六边形头像、双血条、狂暴阈值、顶栏连击读数）。
- [x] **3D 视口**：`space_boss` 血条不挡 3D 交互——已**静态确认**（HUD 根/面板/子控件全部 `mouse_filter=IGNORE`，不拦截输入）；
      并已在**真实窗口**用 `Lab3DStage` 抓到 `space_boss_hud.png`：3D 视口有内容、血条浮于其上不遮挡交互。
      数值化自检 `tools/lab3d_render_check.tscn`（内容像素占比）为可选项，未跑。
- [x] 移动端窄屏：`view_left..right` 区过窄时 HUD 是否挤压 —— 已用**多分辨率真实窗口**验证，
      **出货配置下不存在窄屏挤压**（见 §1「P4 · 窄屏/多分辨率验证」）。

### P2 · 关卡节奏强化（已交付，见 §1；仅剩目视）
- [x] 可见连击条 + 金币倍率（`ComboBar`，顶栏，连击≥2 显示）。
- [x] 限时 / 极速奖励；结算显示用时与最快纪录（`level_records[].best_time`）。
- [x] 三星条件显式化 + 结算「下一星差在哪」引导。
- [x] 道具即时演出：提示卡使用时的 `Vfx` 反馈。
- [x] 设置项：关卡计时总开关（`Settings.challenge_timer`）。
- [x] **目视**：连击条在顶栏的观感已确认真实窗口可读（`circle_boss_hud.png` 显示「连击 x4 ×1.2」），
      计时读数（`计时 137.0s`，未超星时为金色）与 BOSS HUD 并存不冲突；
      结算（`circle_boss_result.png` 三星含连击/极速/首通奖励；`circle_1_1_result.png` 二星显示「再 1 轮零失误即可升到 3 星」引导）。
      窄屏已补验（见 §1 P4）：连击条固定宽 168px，但顶栏在最小逻辑宽 1280 下仍余 131px（circle_boss）/ 119px（space_boss）。
- [ ] ℹ️ 范围说明：本层只改 `StageBase`（LAB 2D/3D，含 5 BOSS，覆盖绝大多数关卡）。
      `SequenceStage` / `SolidChallenge` / `ConicStage` 是**独立实现**（`extends Control`，
      各带自己的 `_finish`，无 `_streak`），如需同等节奏体验须另行移植（未纳入 P2 范围）。

### P3 · 地图冒险化（改 `TheoremTree.gd`）
- [x] 分支路线 / 宝箱节点 / 随机事件 / 章节 Boss 门（星数门槛解锁 `*_boss`）。
      ⚠️ 实现用**关卡级** `gate/chest/event/optional` 字段，**未**用章节级 `map{}`（多教材章节合并下章节级不可靠）。
- [x] 存档 `chests_claimed{}` / `events_seen{}`。
- [x] ⚠️ `WorldMap.tscn` == `TheoremTree.gd(kind="method")`：两者走同一 `_build_map` 路径，P3 逻辑不分 `kind`，两种 `kind` 均已回归。
- [x] 剩余目视项：移动端窄屏（地图节点/面板）——与 P1/P2 一并补验，面板宽度自适应、无溢出（见 §1 P4）。

---

## 3. 数据 schema（全部为**新增可选字段**，缺省即沿用旧行为，无需迁移）

```jsonc
// data/*_levels.json 关卡级
"boss": {
  "title": "圆之试炼",          // HUD 中央称号
  "name": "圆关守",             // 守关者名(血条标签)
  "avatar": "圆",               // 六边形头像字符
  "color": "#FFB35C",
  "player_hp_bonus": 1,        // 推演者血量 = 阶段数 + 该值
  "enrage_at": 0.5,            // 守关者血量比例 ≤ 此值触发狂暴(仅视觉)
  "reward": { "first_clear_coins": 200 }
}

// data/*_levels.json 关卡级（P2；仅关卡级，未做阶段级覆盖）
"rules": { "time_limit": 300, "star_time": 150, "show_combo_bar": true }

// data/curriculum.json 关卡级（P3；挂在每个 level 条目上，随章节合并原样保留）
"gate":   { "need_stars": 15 },                              // 章节 Boss 门：本单元累计星数门槛
"chest":  { "need_stars": 9, "title": "斜率补给箱",
            "reward": { "coins": 120 } },                     // 宝箱：达标可领，一次
"event":  { "title": "限时金币加成",
            "reward": { "coin_boost": 1 } },                   // 随机事件：首开触发一次
"optional": true, "after": "line_6_2"                         // 支线：抽离主路径，弧线连回 after 关
```

> P3 全部为可选字段，缺省即旧行为。设计稿里的章节级 `map{ layout/nodes/edges/boss_gate }` **未采用**：
> 部分教材（如「圆锥曲线与方程」）会把多章合并成一张卡片，章节级数据在合并下无法定位；
> 关卡字段随 `duplicate(true)` 合并原样保留，天然不受影响。

---

## 4. 机制速查（`scripts/screens/StageBase.gd`）

- **启用**：`_boss_enabled()` == `archetype==BOSS or cfg.boss is Dictionary`；普通关 `_boss_hud == null`，零副作用。
- **血量**：守关者 = 阶段数（`_level_ok` 每次 −1）；推演者 = 阶段数 + `player_hp_bonus`（`_wrong` 每次 −1）。
- **狂暴**：守关者血量比例 ≤ `enrage_at` 时触发一次（`BossHud.enraged` / 返回值），仅视觉。
- **失败**：推演者 0 血 → `_boss_failed = true` → `_finish()` 强制 `st = 0`（仍 `record_level_result` 记一次尝试）。
- **首通**：`prev_best == 0 and st > 0` → 额外 `reward.first_clear_coins`，结算文案标注。
- HUD 位置：覆盖在图形区顶部（`UI.stage_layout()["view_left"]..right`，`offset_top=70`，高 92），`mouse_filter=IGNORE`。

### P2 · 节奏层（`ComboBar.gd` + `StageBase`）

- **连击条**：顶栏 `ComboBar`，`_refresh_combo()` 更新；`show_combo_bar`（默认 true）关闭时恒隐藏。倍率 `ComboBar.multiplier(streak)`：≥3 起 +0.1/连击，封顶 1.5。
- **计时**：`_apply_rules()` 读 `rules{time_limit,star_time}`；仅当 `Settings.challenge_timer` 开且任一 >0 时 `_timing=true`，`_process` 累计 `_elapsed`，顶栏显示 `计时 %.1fs`（超星时转金、超时限转红）。
- **结算(在既有 `st`/`reward` 管线内叠加，顺序：陷阱→超时→boss)**：
  - 超时降星：`st>0 且 _elapsed>time_limit` → `st-=1`（保底 1 星），`_time_capped=true`。
  - 极速奖励：`st>0 且 _elapsed<=star_time` → `+40`。
  - 连击奖：`+round(reward*(mult-1))`，`mult=ComboBar.multiplier(_max_streak)`。
  - 最快用时：`st>0` 时 `GameData.record_level_time(lid,_elapsed)`（刷新纪录才写）。
  - 引导：`_next_star_hint()` → 结算 `_v_guide`「下一星差在哪」。
- **兼容**：无 `rules{}` 的关卡 `_timing=false`、无超时/极速/用时，连击条照常显示；旧存档 `best_time` 缺省 0。`Settings.challenge_timer=false` 时全部限时行为关闭。

---

## 5. 涉及文件

- 新：`scripts/ui/BossHud.gd`（+`.uid`）、`docs/关卡游戏化方案.md`、`TODO-gamify.md`
- 改：`scripts/screens/StageBase.gd`、`scripts/screens/Battle.gd`、`data/circle_levels.json`
- 改（P1-M2）：`data/{line,space,vector,ellipse,circle}_levels.json`（`boss{}`）、`tests/Tests.gd`（`_test_boss_data`）
- 新（P2）：`scripts/ui/ComboBar.gd`（+`.uid`）
- 改（P2）：`scripts/screens/StageBase.gd`、`scripts/autoload/GameData.gd`（`best_time`）、
  `scripts/autoload/Settings.gd`、`scripts/screens/SettingsMenu.gd`、
  `data/{line,space,vector,ellipse,circle}_levels.json`（`rules{}`）、`tests/Tests.gd`（`_test_rhythm`）
- 后续（P3）：`scripts/modules/line/TheoremTree.gd`
- 改（P3）：`scripts/modules/line/TheoremTree.gd`（节点类型/布局/面板/解锁/庆祝）、
  `scripts/autoload/GameData.gd`（`chests_claimed{}`/`events_seen{}`、`stars_of`、`claim_chest`、
  `is_chest_claimed`、`is_event_seen`/`mark_event_seen`、`grant_reward`）、
  `data/curriculum.json`（5 个 Boss `gate`、5 组 `chest`/`event`、5 个 `optional`+`after`）、
  `tests/Tests.gd`（`_test_adventure`）
