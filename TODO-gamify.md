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
- 引擎：`D:\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe`（Godot 4.4.1，GL Compatibility）。
- 回归四件套（改完必跑）：
  | 命令 | 期望 |
  |---|---|
  | `--headless --path . --script res://tools/check_all.gd` | `CHECKED 78 scripts, 0 failures`（仅 `third_party/` 两个历史 Parse Error） |
  | `--headless --path . res://tests/Tests.tscn` | `TESTS: 1074 passed, 0 failed` |
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

---

## 2. 待办

### P1 收尾（仅剩「目视」类验证，需真实窗口）
- [ ] **HUD 观感**：非 headless 截图确认 5 关战斗 HUD 布局（可临时改 `tools/capture_scene.gd` 强制截 `circle_boss`）。
- [ ] **3D 视口**：`space_boss` 血条不挡 3D 交互——已**静态确认**（HUD 根/面板/子控件全部 `mouse_filter=IGNORE`，不拦截输入）；
      仅剩跑一次 `tools/lab3d_render_check.tscn` 目视（**必须真实窗口**，headless 会卡在 `frame_post_draw`）。
- [ ] 移动端窄屏：`view_left..right` 区过窄时 HUD 是否挤压（真机 / 改窗口尺寸验证）。

### P2 · 关卡节奏强化（建议默认关闭、逐关开启）
- [ ] 可见连击条 + 金币倍率（现仅有顶栏小标签 `_combo_lbl`，无进度条/倍率）。
- [ ] 可选限时 / 速度奖励；结算显示用时与最快纪录（存档 `level_records[].best_time`）。
- [ ] 三星条件显式化 + 结算「下一星差在哪」引导。
- [ ] 设置项：计时开关（`Settings`）。

### P3 · 地图冒险化（改 `TheoremTree.gd`）
- [ ] 章节级 `map{}`：分支路线 / 宝箱节点 / 随机事件 / 章节 Boss 门（星数门槛解锁 `*_boss`）。
- [ ] 存档 `chests_claimed{}` / `events_seen{}`。
- [ ] ⚠️ `WorldMap.tscn` == `TheoremTree.gd(kind="method")`，两种 `kind`（method/knowledge）都要回归。

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

// data/*_levels.json 关卡/阶段级（P2）
"rules": { "time_limit": 90, "star_time": 60, "show_combo_bar": true }

// data/curriculum.json 章节级（P3）
"map": {
  "layout": "branch",
  "nodes": [ { "id": "circle_1_1", "type": "level", "x": 0.2, "y": 0.4 },
             { "id": "chest_1", "type": "chest", "reward": { "coins": 100 } } ],
  "edges": [ ["circle_1_1", "circle_1_2"] ],
  "boss_gate": { "level": "circle_boss", "need_stars": 30 }
}
```

---

## 4. 机制速查（`scripts/screens/StageBase.gd`）

- **启用**：`_boss_enabled()` == `archetype==BOSS or cfg.boss is Dictionary`；普通关 `_boss_hud == null`，零副作用。
- **血量**：守关者 = 阶段数（`_level_ok` 每次 −1）；推演者 = 阶段数 + `player_hp_bonus`（`_wrong` 每次 −1）。
- **狂暴**：守关者血量比例 ≤ `enrage_at` 时触发一次（`BossHud.enraged` / 返回值），仅视觉。
- **失败**：推演者 0 血 → `_boss_failed = true` → `_finish()` 强制 `st = 0`（仍 `record_level_result` 记一次尝试）。
- **首通**：`prev_best == 0 and st > 0` → 额外 `reward.first_clear_coins`，结算文案标注。
- HUD 位置：覆盖在图形区顶部（`UI.stage_layout()["view_left"]..right`，`offset_top=70`，高 92），`mouse_filter=IGNORE`。

---

## 5. 涉及文件

- 新：`scripts/ui/BossHud.gd`（+`.uid`）、`docs/关卡游戏化方案.md`、`TODO-gamify.md`
- 改：`scripts/screens/StageBase.gd`、`scripts/screens/Battle.gd`、`data/circle_levels.json`
- 改（P1-M2）：`data/{line,space,vector,ellipse,circle}_levels.json`（`boss{}`）、`tests/Tests.gd`（`_test_boss_data`）
- 后续（P3）：`scripts/modules/line/TheoremTree.gd`
