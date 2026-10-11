# 衍数阁(高中数学闯关游戏)

Godot 4.7(Compatibility / GL)制作的数学闯关学习 App。UI 全程代码绘制(玻璃拟态),数据/题目走 JSON,单个模块带交互探索器。

## 目录结构

```
scenes/          场景 .tscn(主体均由代码构建,tscn 只是空壳挂脚本)
scripts/         总控与共享逻辑
  UI.gd            设计系统:着色 token、字号系数 S(默认 1.4,由 Settings 注入)、fs() 换算、按钮/卡片/弹窗
  Art.gd           美术资源自动加载(有图用图,无图退回代码绘制)
  GameData.gd      全局数据 autoload:课程表/进度/多用户存档/错题统计
  Settings.gd      全局设置 autoload:字号/音效/萌宠/全屏/动效,持久化到 user://settings.json
  Sound.gd         音效 autoload(启动预载,按钮自动接线)
  Toast.gd         飘字提示 autoload
  Pet.gd           萌宠(自主漫游/气泡/庆祝,全代码绘制)
  BootSplash.gd    场景级品牌启动屏(规避引擎启动屏缩放 bug)
  MainHub.gd/Login.gd/WorldMap.gd/UserProfile.gd/SettingsMenu.gd/ChapterNode.gd/TechBg.gd
  conic/ ellipse/ line/ space/ vector/ solid/   六大知识模块
data/            课程表与题库 JSON(curriculum/questions + 各模块 *_levels.json)
art/             美术 PNG/WebP + 公式小图 + Android 图标 + 标题字体(art/fonts/,放入行书 ttf 即自动启用)
audio/           音效 wav
docs/            设计文档 .docx
build/           导出产物(APK,git 忽略)
```

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
- 通用题库:`data/questions.json`;各模块关卡:`line_levels.json / conic_levels.json / ellipse_levels.json / space_levels.json / vector_levels.json`
- 立体几何方法讲解:`data/solid_methods.json` + `scripts/solid/topics/*.gd`