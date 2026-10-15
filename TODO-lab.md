# TODO · 几何章节迁移到通用 LabStage

> 目标：把「静态几何」知识章节统一到通用 **LabStage + LabPlane**，每关按
> 「实验探究 → 建构知识 → 迁移应用」三阶段组织（探究轮 `type:"explore"` 用滑块/拖动实时重绘 + 追问；其余为 `type:"choice"`）。
> 与 `TODO.md`（MicroTeX 公式运行时渲染 runbook）相互独立。

## 已完成
- [x] 基础设施：`scripts/modules/lab/LabPlane.gd` 扩展了表达式求值（`_num`：`+ - * / ^ ( )`、`sqrt/abs/sin/cos/tan`（角度制）、常量 `pi/e`）、`range`、`ellipses`、`foci`、`readouts` 实时读数；`scripts/modules/lab/LabStage.gd` 支持阶段级 `gate/answers/tol`。
- [x] 圆的方程 `circle_eq`：`data/circle_levels.json`（19 关 × 3 轮）；`data/curriculum.json` 已改 `archetype:LAB, lab:"circle", scene:LabStage`。
- [x] 椭圆 `ellipse`：`data/ellipse_levels.json`（16 关）；curriculum 已改 `lab:"ellipse"`。
- [x] 平面向量 `vector`：`data/vector_levels.json`（19 关）；curriculum 已改 `lab:"vector"`。
- [x] **直线 `line_eq`**：`data/line_levels.json` 已改为 lab 三阶段格式（18 关：`line_1_1`…`line_6_3` + `line_boss`，每关 3~4 轮）；`data/curriculum.json` 中 line_eq 的 18 个关卡改为 `archetype:LAB`（boss 保留 `BOSS`）、`lab:"line"`、`lab_ref:"line_X_Y"`、`scene:res://scenes/LabStage.tscn`。
      专属探索器（`tilt_explorer`、`slope_explorer`、`lineeq_explorer`、`slope_curve`、`distance_explorer`、`dual_explorer`、旧 `drag(constraint:line)`、`interact(param/target/tol)`）统一映射为 lab 滑块 + 表达式 + 实时读数。
- [x] 在 `tests/Tests.gd` 的 `_test_lab_data` 加入 `line_levels.json` 的 18 个 id；`tests/LabSmoke.gd` 加入直线用例。
- [x] **删除迁移后闲置的专属关卡代码/场景**（确认无引用后）：
      - `scripts/modules/circle/{CircleStage,CirclePlane}.gd(+.uid)`、`scenes/CircleStage.tscn`
      - `scripts/modules/ellipse/{EllipseStage,EllipsePlane}.gd(+.uid)`、`scenes/EllipseStage.tscn`
      - `scripts/modules/line/{LineStage,LinePlane,TiltExplorer,SlopeExplorer,LineEqExplorer,SlopeCurve,DistanceExplorer,DualLineExplorer}.gd(+.uid)`、`scenes/LineStage.tscn`
      - `scripts/modules/vector/{VectorStage,VectorPlane}.gd(+.uid)`、`scenes/VectorStage.tscn`
      - ⚠️ 保留 `scripts/modules/line/TheoremTree.gd`（被知识树共用）。
- [x] 更新 `README.md` 中对各 `*_levels.json` / 旧 Stage 的描述。
- [x] 发布前关闭编辑模式：`scripts/autoload/Settings.gd` 的 `DEFAULTS["editor_mode"]` 与 `var editor_mode` 改为 `false`。
- [x] **立体几何 / 空间向量迁移到通用真实 3D 关卡**(`lab3d`)：
      - 基础设施：`scripts/modules/lab3d/{NumExpr,SolidBuilder,Lab3DView,Lab3DStage}.gd` + `scenes/Lab3DStage.tscn`；
        `SolidBuilder` 由 JSON 生成真实网格 3D(坐标轴/网格、命名几何体正方体·棱柱·棱锥·四面体·圆柱·圆锥·台·球、
        顶点/棱/面/向量/圆/球/平面/直角标记/角弧/标注)，支持生长显现、高亮脉冲、参数表达式与固体平移 `at`；
        `Lab3DView` = 内嵌 SubViewport 的可旋转/缩放 3D 视口(相机预设、自动缓转、演示动画)；
        `Lab3DStage` 继承 `StageBase`，沿用「实验探究 → 建构知识 → 迁移应用」三阶段契约(explore/choice)。
      - `data/solid_basic_levels.json`：11 关(`solid_kinds…solid_perp_prop`)，重点`solid_axiom` 旗舰关用 7 轮
        逐条演示 基本事实1(三点定面)/2(线在面内)/3(两平面交于公共直线)/4(平行传递) 与推论、异面直线。
      - `data/space_levels.json`：19 关(`space_1_1…space_boss`)重写为三阶段 3D。
      - `data/curriculum.json`：`solid_basic`(11 关)与 `space`(19 关)改为 `archetype:LAB, lab:..., lab_ref:..., scene:res://scenes/Lab3DStage.tscn`。
      - `tests/Tests.gd` `_test_lab_data` 加入 `space_levels.json`(solid_basic 已有)；`tests/LabSmoke.gd` 新增 `_smoke_3d()` 覆盖全部 30 个 3D 关卡。
      - [x] 删除迁移后闲置的专属关卡代码/场景(确认无引用后)：`scripts/modules/space/{SpaceStage,Space3DView}.gd(+.uid)`、`scenes/SpaceStage.tscn`(`space/` 目录已空)。
      - 回归：`tests/Tests.tscn` **1066 passed / 0 failed**；`LabSmoke` 打印 `TMP_OK` 且 30 关 `view3d=true`；
        `tools/check_all.gd` 78 scripts / 0 failures；`tools/smoke_scene.tscn` **234 ok / 0 fail**。

## 待完成
- [ ] （可选）GUI 下逐章目视复核交互与排版。

## 验证命令
- 回归测试：`godot --headless --path . res://tests/Tests.tscn`（退出码 0 = 全通过，当前 **1066 passed / 0 failed**）
- 运行期冒烟：`godot --headless --path . res://tests/LabSmoke.tscn`（打印 `TMP_OK` 即正常；含 2D + 3D 关卡）
- 脚本检查：`godot --headless --path . -s res://tools/check_all.gd`（当前 78 scripts / 0 failures）
- 全场景冒烟：`godot --headless --path . res://tools/smoke_scene.tscn`（当前 234 ok / 0 fail）
- 3D 渲染自检（需真实窗口）：`godot --path . res://tools/lab3d_render_check.tscn`（输出各 3D 场景内容像素占比 + PNG 到 `build/shots3d/`；当前 49 场景 / 0 空白）
