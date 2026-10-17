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
				   TtsOnline.gd(在线语音)
  save/            SaveIO.gd(存档原子读写:临时文件校验 + 备份 + 替换;GameData 存档 IO 委托于此)
  screens/         BootSplash.gd(品牌启动屏,规避引擎启动屏缩放 bug)、Login.gd、MainHub.gd、
				   WorldMap.gd、UserProfile.gd、SettingsMenu.gd、ChapterNode.gd、
				   Battle.gd(通用战斗/占位关卡)、StageBase.gd(闯关共享骨架:
				   HUD/答题面板/选项/结算/上下关导航;由 LabStage、Lab3DStage 继承,
				   服务于圆/椭圆/向量/直线及各 LAB 章节,以及立体几何/空间向量的 3D 章节)
  modules/         知识模块:conic/ lab/ lab3d/ line/ sequence/ solid/
				   lab/ 为通用三阶段 2D 闯关(LabStage + LabPlane:滑块/拖动实时重绘 + 读数),
				   承载圆/椭圆/向量/直线等章节;line/ 仅余 TheoremTree.gd(被知识树共用);
				   lab3d/ 为通用三阶段真实网格 3D 闯关(Lab3DStage + Lab3DView + SolidBuilder + NumExpr:
				   可旋转/缩放 3D 视口 + 参数滑块实时重建 + 生长/演示动画),
				   承载立体几何初步(solid_basic)与空间向量与立体几何(space)
data/            课程表与题库 JSON(curriculum/questions + 各模块 *_levels.json)
art/             美术 PNG/WebP + 公式小图 + Android 图标 + 标题字体(art/fonts/,放入行书 ttf 即自动启用)
audio/           音效 wav
tools/           开发/测试脚本:check_all.gd(脚本检查)、check_questions.gd(内容校验器:
				 结构/答案范围/选项与题干重复/轮次编号/公式覆盖 + 内容看板,含基线机制)、
				 check_questions_baseline.txt(已知问题基线)、fix_labels.gd(轮次标签编号批量重编:
				 预览/--apply,文本级替换保留排版)、smoke_scene(全场景冒烟)、
				 pack_math_res(把 gdextension/res 打包为 res.bin,排除 GPLv3 字体)、
				 bump_version(F2 发版:一处改版本,多预设同步)、
				 capture_scene(截图)、dev_seq(单关调试)、
				 lab3d_render_check(立体几何/空间向量 3D 场景渲染自检,需真实窗口)
tests/           回归测试(GameData 纯逻辑)
build/           导出产物(APK,git 忽略)
```

## 自检与 CI

改完**必跑**（顺序任意，全绿才提交）：

```
& "<godot4.7.2.exe>" --headless --path . --script res://tools/check_all.gd
& "<godot4.7.2.exe>" --headless --path . res://tests/Tests.tscn
& "<godot4.7.2.exe>" --headless --path . res://tools/smoke_scene.tscn
& "<godot4.7.2.exe>" --headless --path . res://tests/LabSmoke.tscn
& "<godot4.7.2.exe>" --headless --path . --script res://tools/check_questions.gd
```

- `check_questions.gd`：有**新增**内容问题即退出码 1；存量问题记在
  `tools/check_questions_baseline.txt`（修完删对应行）。
  确认新问题是历史遗留而非本次引入时，可 `-- --write-baseline` 记入基线。
- 以上五条已接入 CI（`.github/workflows/check.yml`，push/PR 自动跑）。

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
- 教材版本(苏教/人教A/人教B/北师大/湘教/沪教):分册、章节排序与章号:`data/textbooks.json`
- 通用题库:`data/questions.json`;各模块关卡:`data/*_levels.json`。几何类章节(圆/椭圆/向量/直线)已统一为 `lab` 三阶段格式,对应 `circle_levels.json / ellipse_levels.json / vector_levels.json / line_levels.json`,场景统一为 `res://scenes/LabStage.tscn`
- 立体几何 / 空间向量章节已统一为 `lab3d` 三阶段真实 3D 格式,对应 `solid_basic_levels.json`(立体几何初步,含「基本事实(公理)」旗舰关 `solid_axiom`)与 `space_levels.json`(空间向量与立体几何),场景统一为 `res://scenes/Lab3DStage.tscn`。3D 场景描述见 `scripts/modules/lab3d/SolidBuilder.gd`
- 立体几何方法讲解:`data/solid_methods.json` + `scripts/modules/solid/topics/*.gd`

## 内容与教材的关系

- 本项目的**课程结构**（分册、章节、顺序）对齐人教A/苏教等人教版教材的**知识点顺序**，便于按教材体系复习；
- **题目均为自编**（题干、选项、解析由项目组撰写），**不逐题复制教材习题**；
- 教材名称与章节名为客观指代，相关著作权归各出版社所有，本项目与出版社无隶属关系。
  详见 `THIRD_PARTY_NOTICES.md` §5。

## 授权与第三方声明

- 项目自身授权：**专有（保留所有权利）**，见根目录 `LICENSE`；
- 第三方组件与素材清单：`THIRD_PARTY_NOTICES.md`；
- 第三方许可全文（Godot / MicroTeX 的 MIT）：`THIRD_PARTY_LICENSES.md`；
- 美术素材来源：`art/SOURCES.md`；音效来源：`audio/SOURCES.md`；
- 隐私政策：`docs/隐私政策.md`（唯一联网功能=可选的在线语音朗读，默认关闭）。

> 待处理（上架前必做）：替换授权不明的标题字体 `art/fonts/aidianqianfengxingshu.ttf`（13.8 MB，见 A13/F7）。

## 发版

版本号一处修改、多预设同步（`version/code`、`version/name` 与 Windows 的 `file/product_version`）：

```
& "<godot4.7.2.exe>" --headless --path . --script res://tools/bump_version.gd -- --bump patch
```

发布签名（release keystore，密钥不入库）与 Android 上架要点见 `docs/环境配置.md` §6.1。
