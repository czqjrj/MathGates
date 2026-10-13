# TODO · MicroTeX 运行时公式渲染（GDExtension）

> 目的：把公式从「预渲染 PNG + name→{p,w,h} 映射」升级为「LaTeX 源码 → 运行时渲染成 ImageTexture → 缓存」，
> 通过 GDExtension 封装 MicroTeX，Windows 本地跑通后再交叉编译 Android arm64。
> 本文件是可跨机器续接的 runbook：换电脑后按「续接指引」克隆/切分支，再从当前未打勾项继续。

---

## 0. 当前基线（改动前请先读）

- 公式现状：
  - `scripts/ui/InlineMath.gd`
    - `inline()`：按 CJK 切分文本，把非中文片段去 `data/inline_math.json` 查表。
    - `inline_formulas()`：把 `{f:名称}` 替换为 `art/line/formulas/名称.png`。
    - `_inline_math[core] = { "p": 图片路径, "w": 宽, "h": 高 }`。
  - `scripts/ui/UI.gd`：`inline()` / `inline_formulas()` / `strip_formulas()` / `formula_img()` 为薄转发。
  - 资源：`art/line/formulas/`、`art/formulas/`、`art/vector/formulas/`、`art/space/formulas/`、`art/sequence/formulas/`、`art/questions/formulas/` 等。
  - 数据：`data/inline_math.json`、`data/curriculum.json`、`data/*_levels.json`（标题/题干/选项里混有公式标记或裸 LaTeX 片段）。
- 引擎：`project.godot` → `config/features=("4.4","GL Compatibility")`，渲染 `gl_compatibility`。
  - README 里写的是 Godot 4.7.2（`Downloads\Godot_v4.7.2-stable_win64.exe\` 内有 exe）。
  - 本机另见 `D:\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe`。
  - **godot-cpp 分支要与最终导出用引擎的 GDExtension API 对齐**（用户指定 4.4）。
- 导出（Android）：`export_presets.cfg`；README 约定本机无法访问 gradle，`use_gradle_build=false`、`compress_native_libraries=false`。

---

## 1. 任务清单（按顺序）

### [x] 1. 安装 C++ 构建工具链（CMake + MinGW-w64 msvcrt + Ninja）
- [x] 安装 CMake（≥3.20），加入 PATH，`cmake --version` 通过。
      - 已装 MSYS2 到 `C:\msys64`；工具在 `C:\msys64\mingw64\bin`（cmake 4.4.4）。
- [x] 安装 Ninja，加入 PATH，`ninja --version` 通过。（1.13.2）
- [x] 安装 MinGW-w64 **msvcrt** 运行时版本（godot-cpp/MicroTeX 官方推荐，**不要**用 ucrt 以保持一致）。
      - [x] `gcc --version` / `g++ --version` 通过。（gcc/g++ 16.2.0；target `x86_64-w64-mingw32`；mingw64 子系统 = msvcrt）
- [x] 校验三者能在 PowerShell 里协同（`cmake -G Ninja ...` 找得到 gcc）。
- 验收：`cmake --version`、`ninja --version`、`g++ --version` 均有输出。
- 备注：本机网络屏蔽 GitHub；已把 pacman 镜像切到 `mirror.nju.edu.cn`（见 `C:\msys64\etc\pacman.d\mirrorlist.*`）。
- 使用方式（不污染全局 PATH）：
      ```
      & "C:\msys64\mingw64\bin\gcc.exe" ...
      & "C:\msys64\usr\bin\bash.exe" -lc "..."   # 或进入 mingw64 环境
      ```

### [x] 2. 克隆 godot-cpp(4.4) 与 MicroTeX 源码
- [x] 克隆 `/godotengine/godot-cpp`，切到 `4.4` 分支（与引擎版本对齐，用 submodule 拉全）。（commit b0e3b1e）
- [x] 克隆 MicroTeX 源码（原版为 SVG 后端；需确认可编译为静态库/可嵌 C++）。
      - [x] 梳理 MicroTeX 依赖（如字体、第三方头）与许可证。（字体 CM 系；freetype+tinyxml2 均自 mingw-w64）
- [x] 放置位置建议：仓库外同级或 `third_party/`（**不要提交**，见 .gitignore）。→ `third_party/`
- 验收：两份源码可本地编译出最小目标（godot-cpp 生成 `libgodot-cpp.*`；MicroTeX 生成库/可执行）。（LaTeX 静态库独立构建通过）

### [x] 3. 编写 GDExtension 封装（MicroTeX Graphics2D → ImageTexture）
- [x] 新建扩展目录（建议 `gdextension/`）：`SConstruct`/`CMakeLists` + `src/` + `.gdextension` 描述文件。
      - `gdextension/CMakeLists.txt`（Ninja + MinGW）；`math_tex.gdextension`（windows debug/release + android arm64 占位）。
- [x] 实现自定义 `Graphics2D`：把 MicroTeX 的绘制指令光栅化到 `Image`（RGBA8，注意字体与抗锯齿）。
      - `src/backend.cpp`：`Graphics2D_Image`，even-odd 多边形填充 + 2x2 超采样 AA；`src/font_ft.cpp`：freetype 字体/排版；`src/surface.cpp`。
- [x] 暴露节点/单例 API，建议：
      - `render_latex(latex: String, font_size: int, color: Color) -> ImageTexture`
      - `render(...) -> Image`（缓存见任务 6）
      - 单例 `MathTeX`：`configure(res_path)` / `render(latex,font_size,color)` / `render_latex(...)` / `is_ready()` / `get_res_path()`。
- [x] `.gdextension` 中声明 Windows 与 Android 各架构的 `.dll/.so` 路径。
- 验收：Godot 内 `ClassDB`/`Engine.get_singleton()` 能看到类；编辑器中新 API 可调用不报错。（4.4.1 导入后加载成功）
- 备注：**Error 126 坑**——Godot 4.4 用 `LOAD_LIBRARY_SEARCH_DEFAULT_DIRS` 加载扩展，MinGW 依赖 DLL（libstdc++-6.dll 等）即使放同目录也找不到；解法=全静态链接（`-static -static-libgcc -static-libstdc++` + 显式 `.a` 归档链），成品 DLL 仅依赖系统 DLL（KERNEL32/msvcrt/USER32/GDI32/DWrite/RPCRT4/USP10）。

### [x] 4. Windows 本地构建并跑通硬编码公式
- [x] 用 MinGW + Ninja 构建扩展 `.dll`，放入 `.gdextension` 约定目录。（`gdextension/bin/godot_math_tex.windows.debug.x86_64.dll`，约 63MB 全静态 debug 构建）
- [x] 写一个最小 Godot 场景/脚本：硬编码 `x^2+y^2=r^2` → `render_latex` → 贴到 `TextureRect`。
      - `tests/mathtex_test/`（独立 4.4 工程）：`scripts/main.gd` 渲染 8 公式 × 24/40px，存 PNG 并自查。
- [x] 验证透明背景、基线对齐、颜色、字号缩放。
- 验收：运行项目能看到渲染出的公式，无控制台报错。（16/16 公式渲染保存成功，failures=0，无脚本错误）
- 备注：headless 首次须先 `--import --quit` 生成导入缓存；`render_latex` 需用 `== null` 判断（无 `is_null()`）。

### [x] 5. 产出 name → LaTeX 映射（就地扩展 data/inline_math.json）
- [x] 生成脚本已定位：`%TEMP%\opencode\mathgen\`（MiKTeX + dvipng；`mathgen.unicode_to_latex` 负责 Unicode→LaTeX）。
- [x] 就地扩展 `data/inline_math.json`：每条在 `{p,w,h}` 基础上新增 `latex` 字段（保留旧字段以支持回退）。**824/824 全部产出**。
- [x] 统一 CJK 切分 + 首尾修剪：运行时 `InlineMath._inline_trim` 改为与 `gen_inline.py::trim_math` 一致（只去首尾空白与 `,;:.!?`），Trim 后键与映射一一对应。
- 验收：得到全量 `name -> LaTeX` 表，覆盖率与旧 PNG 集一致（824/824）。✅

### [x] 6. 改造 InlineMath/UI 与 JSON 数据为 LaTeX 驱动 + 缓存
- [x] 改 `InlineMath.gd`：命中映射时优先 `latex` 字段调用 GDExtension 渲染为纹理并缓存；无 `latex`/扩展不可用时回退旧 PNG。
      - 新增 `scripts/ui/MtTextureLoader.gd`：自定义 `ResourceFormatLoader`，让 RichTextLabel bbcode `[img]` 能引用运行时纹理（存 `user://mt_cache/<md5>.mttex`，私有扩展名避开内建 PNG 加载器）。
      - `_formula_bbcode()`：LaTeX 优先 → 失败/缺失 → 旧 `{p,w,h}` PNG bbcode。
- [x] 缓存策略：进程内 `md5(latex|h|color)→Vector2i` + 磁盘 `user://mt_cache/*.mttex` 复用（LRU/上限待任务 8 视情况加）。
- [x] `strip_formulas()`（朗读用）继续去标记；TTS 路径未改动。
- [x] UI 回退策略：扩展不可用或无 `latex` 时退回旧 PNG，逐片段降级不会崩。
- [x] 灰度迁移 `data/inline_math.json`：已加 `latex` 字段，全部内联片段走 LaTeX。
- [ ] 仍走旧 PNG 的：`{f:名称}` 直挂图（`formula_img()` → `art/line/formulas/*.png`）暂无 `name→latex` 表，保持回退。
- 验收：题干/选项/标题中的内联公式全部走 LaTeX 渲染（实测 824/824 命中 `mt_cache`，0 回退到 PNG）。✅
- 备注：主工程根目录 `math_tex.gdextension` + `gdextension/{bin,res}` 已就位；`project.godot` features 已由 4.7 改回 **4.4**。验证见 `tests/mathtex_test/`（扩展加载 + 8 公式渲染 + LaTeX→bbcode→ImageTexture 全链路）。
- 关键修复：`_mt_ready()` 原用 `ResourceLoader.exists("res://gdextension/res")` 判断，而该路径是**目录**，恒为 false → `configure()` 从未调用 → `is_ready()` 为 false，全部退回 PNG。改为直接 `configure()`。

### [~] 7. Android arm64 交叉编译 .so 并集成
- [x] 配置 NDK 交叉编译（arm64-v8a），产出 `gdextension/bin/libgodot_math_tex.android.release.arm64.so`（约 8.6MB，`build-android/` 为构造目录，不入库）。
      - ⚠️ Godot 安卓导出**强制要求原生库名以 `lib` 开头**，故 `CMakeLists.txt` 的 OUTPUT_NAME 改为 `libgodot_math_tex...`。
- [x] 在 `.gdextension` 增加 Android aarch64 条目（debug/release，均带 `lib` 前缀）。
- [x] 核对 `export_presets.cfg`：`use_gradle_build=false`、`compress_native_libraries=false`（README 约定）。✅ 原本已正确。
- [x] **导出过滤 / 资源打包**（原方案「把 res/** 加进 include_filter」不可行）：
      - `.gdignore` 会让 Godot 完全跳过该目录（include_filter 也救不回），且 `*.zip` 不会被 `all_resources` 打包。
      - 改为：`tools/pack_math_res.gd` 把 `gdextension/res/` 打成**单个非资源二进制** `gdextension/res.bin`（≈684KB），导出预设 `include_filter="gdextension/res.bin"`。
      - 依赖/产物目录用 `.gdignore` 排除，避免把 `third_party/`、`gdextension/build*/` 打进包（`CMakeLists.txt` 配置时自动生成这些 `.gdignore`）。
      - 导出过滤（exclude）另加：`third_party/*, gdextension/build/*, gdextension/build-android/*, tests/mathtex_test/*, *.log, *.pck`。
- [x] 运行时改为从真实文件系统读 MicroTeX 资源：`InlineMath._mt_resolve()` 开发态直读 `res://gdextension/res`；导出态用 `ZIPReader` 把 `res.bin` 解压到 **OS 临时目录** 再 `configure()`。
      - ⚠️ 不能用 `user://`：Windows 上 `user://` 落在含中文的工程名目录，MicroTeX/FreeType 走 ANSI 窄路径会失败；临时目录为 ASCII。
      - `res.bin` 变更时按 md5 自动重新解压（`<cache>/.source_md5`）。
- [x] 导出 APK：`Godot_v4.7.2 --headless --path . --export-debug "Android" "build/衍数阁.apk"`（4.7.2 导出模板；扩展为 4.4 godot-cpp，实测 4.7.2 可加载）。
      - APK 内容核对：`lib/arm64-v8a/{libgodot_android.so, libc++_shared.so, libgodot_math_tex.android.debug.arm64.so}` + `assets/gdextension/res.bin` + `assets/math_tex.gdextension`。✅
      - 注意：debug 条目当前复用了 release 构建的 `.so`（同为 template_debug godot-cpp），如需严格 debug 需重编。
- [ ] 导出 APK 并在真机/模拟器安装启动。（本机 `adb devices` 无设备，未能真机验证）
- 验收：Android 上扩展加载成功，公式可渲染。（打包链路已验证，待真机确认）

### [ ] 8. 双端公式渲染校对与性能验证
- [ ] Windows 与 Android 各截一组含公式的界面，逐条比对（透明度/基线/字号/颜色/本地化）。
- [ ] 性能：首帧与连续题切换的渲染耗时、内存/纹理数量；必要时加预热与缓存上限。
- [ ] 回归：跑 `tests/` 与 `tools/check_all.gd`、`tools/smoke_scene`。
- 验收：双端视觉一致，帧率/内存无明显回退。

---

## 2. 续接指引（换电脑后）

1. 克隆仓库，切到进行中的分支（建议分支名 `feat/microtex-gdextension`，未建则先建）。
2. 恢复工具链（任务 1），再拉 `godot-cpp(4.4)` 与 MicroTeX 到本机（**不入库**）。
3. 按本文件从上往下打勾；每完成一项，在提交信息里引用本文件对应小节。
4. 关键路径速查：
   - 公式逻辑：`scripts/ui/InlineMath.gd`、`scripts/ui/UI.gd`
   - 映射数据：`data/inline_math.json`
   - 课程/关卡：`data/curriculum.json`、`data/*_levels.json`
   - 导出：`export_presets.cfg`、`README.md`（Android 离线约定）
5. 本地验证命令（示例，exe 路径按本机替换）：
   ```
   & "<godot.exe>" --headless --path . --import
   & "<godot.exe>" --headless --path . --script res://tools/check_all.gd
   & "<godot.exe>" --path .        # 运行查看公式
   ```

---

## 3. 风险 / 注意

- **版本对齐**：godot-cpp 分支、引擎版本、`.gdextension` API 要一致；README(4.7) 与 project.godot(4.4) 存在不一致，构建前先确认实际导出引擎。
- **MinGW 运行时**：全程用 msvcrt，混用 ucrt 会链接失败/运行期崩溃。
- **MicroTeX 后端**：原版偏 SVG，需要自写 `Graphics2D` 光栅化，工作量主要在此。
- **Android 限制**：`use_gradle_build=false` 下 `.so` 的打包方式需实测；`compress_native_libraries=false` 必须保持。
- **不可入库**：`third_party/`、`godot-cpp/`、`build/`、生成的 `.dll/.so` 均不要提交。
- **回退**：任何阶段都要保留旧 PNG 渲染路径，扩展加载失败时自动降级。
```
