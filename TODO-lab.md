# TODO · 几何章节迁移到通用 LabStage

> 目标：把「静态几何」知识章节统一到通用 **LabStage + LabPlane**，每关按
> 「实验探究 → 建构知识 → 迁移应用」三阶段组织（探究轮 `type:"explore"` 用滑块/拖动实时重绘 + 追问；其余为 `type:"choice"`）。
> 与 `TODO.md`（MicroTeX 公式运行时渲染 runbook）相互独立。

## 已完成
- [x] 基础设施：`scripts/modules/lab/LabPlane.gd` 扩展了表达式求值（`_num`：`+ - * / ^ ( )`、`sqrt/abs/sin/cos/tan`（角度制）、常量 `pi/e`）、`range`、`ellipses`、`foci`、`readouts` 实时读数；`scripts/modules/lab/LabStage.gd` 支持阶段级 `gate/answers/tol`。
- [x] 圆的方程 `circle_eq`：`data/circle_levels.json`（19 关 × 3 轮）；`data/curriculum.json` 已改 `archetype:LAB, lab:"circle", scene:LabStage`。
- [x] 椭圆 `ellipse`：`data/ellipse_levels.json`（16 关）；curriculum 已改 `lab:"ellipse"`。
- [x] 平面向量 `vector`：`data/vector_levels.json`（19 关）；curriculum 已改 `lab:"vector"`。
- [x] 回归测试 `tests/Tests.tscn` 986 passed / 0 failed；运行期冒烟 `tests/LabSmoke.tscn` 无脚本错误。

## 待完成
- [ ] **直线 `line_eq`**：把 `data/line_levels.json` 改成 lab 三阶段格式；`data/curriculum.json` 中 line_eq 的 18 个关卡改为 `archetype:LAB`（boss 保留 `BOSS`）、`lab:"line"`、`lab_ref:"line_X_Y"`、`scene:res://scenes/LabStage.tscn`。
      需映射的专属探索器 → lab 滑块/读数：`tilt_explorer`、`slope_explorer`、`lineeq_explorer`、`slope_curve`、`distance_explorer`、`dual_explorer`、旧 `drag(constraint:line)`、`interact(param/target/tol)`。
- [ ] 在 `tests/Tests.gd` 的 `_test_lab_data` 加入 `line_levels.json` 的 19 个 id；`tests/LabSmoke.gd` 加入直线用例。
- [ ] **删除迁移后闲置的专属关卡代码/场景**（确认无引用后）：
      - `scripts/modules/circle/{CircleStage,CirclePlane}.gd(+.uid)`、`scenes/CircleStage.tscn`
      - `scripts/modules/ellipse/{EllipseStage,EllipsePlane}.gd(+.uid)`、`scenes/EllipseStage.tscn`
      - `scripts/modules/line/{LineStage,LinePlane,TiltExplorer,SlopeExplorer,LineEqExplorer,SlopeCurve,DistanceExplorer,DualLineExplorer}.gd(+.uid)`、`scenes/LineStage.tscn`
      - `scripts/modules/vector/{VectorStage,VectorPlane}.gd(+.uid)`、`scenes/VectorStage.tscn`
      - ⚠️ 保留 `scripts/modules/line/TheoremTree.gd`（被知识树共用）。
- [ ] 更新 `README.md` 中对各 `*_levels.json` / 旧 Stage 的描述。
- [ ] 发布前关闭编辑模式：`scripts/autoload/Settings.gd` 的 `DEFAULTS["editor_mode"]` 与 `var editor_mode` 改为 `false`。
- [ ] （可选）GUI 下逐章目视复核交互与排版。

## 验证命令
- 回归测试：`godot --headless --path . res://tests/Tests.tscn`（退出码 0 = 全通过）
- 运行期冒烟：`godot --headless --path . res://tests/LabSmoke.tscn`（打印 `TMP_OK` 即正常）
