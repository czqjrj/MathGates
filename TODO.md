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

### [ ] 1. 安装 C++ 构建工具链（CMake + MinGW-w64 msvcrt + Ninja）
- [ ] 安装 CMake（≥3.20），加入 PATH，`cmake --version` 通过。
- [ ] 安装 Ninja，加入 PATH，`ninja --version` 通过。
- [ ] 安装 MinGW-w64 **msvcrt** 运行时版本（godot-cpp/MicroTeX 官方推荐，**不要**用 ucrt 以保持一致）。
      - [ ] `gcc --version` / `g++ --version` 通过。
- [ ] 校验三者能在 PowerShell 里协同（`cmake -G Ninja ...` 找得到 gcc）。
- 验收：`cmake --version`、`ninja --version`、`g++ --version` 均有输出。

### [ ] 2. 克隆 godot-cpp(4.4) 与 MicroTeX 源码
- [ ] 克隆 `/godotengine/godot-cpp`，切到 `4.4` 分支（与引擎版本对齐，用 submodule 拉全）。
- [ ] 克隆 MicroTeX 源码（原版为 SVG 后端；需确认可编译为静态库/可嵌 C++）。
      - [ ] 梳理 MicroTeX 依赖（如字体、第三方头）与许可证。
- [ ] 放置位置建议：仓库外同级或 `third_party/`（**不要提交**，见 .gitignore）。
- 验收：两份源码可本地编译出最小目标（godot-cpp 生成 `libgodot-cpp.*`；MicroTeX 生成库/可执行）。

### [ ] 3. 编写 GDExtension 封装（MicroTeX Graphics2D → ImageTexture）
- [ ] 新建扩展目录（建议 `gdextension/`）：`SConstruct`/`CMakeLists` + `src/` + `.gdextension` 描述文件。
- [ ] 实现自定义 `Graphics2D`：把 MicroTeX 的绘制指令光栅化到 `Image`（RGBA8，注意字体与抗锯齿）。
- [ ] 暴露节点/单例 API，建议：
      - `render_latex(latex: String, font_size: int, color: Color) -> ImageTexture`
      - 缓存由 GDScript 侧或 C++ 侧负责（见任务 6 决定）。
- [ ] `.gdextension` 中声明 Windows 与 Android 各架构的 `.dll/.so` 路径。
- 验收：Godot 内 `ClassDB`/`Engine.get_singleton()` 能看到类；编辑器中新 API 可调用不报错。

### [ ] 4. Windows 本地构建并跑通硬编码公式
- [ ] 用 MinGW + Ninja 构建扩展 `.dll`，放入 `.gdextension` 约定目录。
- [ ] 写一个最小 Godot 场景/脚本：硬编码 `x^2+y^2=r^2` → `render_latex` → 贴到 `TextureRect`。
- [ ] 验证透明背景、基线对齐、颜色、字号缩放。
- 验收：运行项目能看到渲染出的公式，无控制台报错。

### [ ] 5. 向用户索取 matplotlib/sympy 生成脚本，产出 name → LaTeX 映射
- [ ] **阻塞项**：请用户提供现有 matplotlib/sympy 生成脚本（即当前产出 PNG + `data/inline_math.json` 的那套）。
- [ ] 用脚本导出 `name -> LaTeX` 映射（替换现 `name -> {png,w,h}`），并保留 CJK 切分 + 首尾修剪规则，保证键一一对应。
- [ ] 决定映射产物格式（建议 `data/inline_math.json` 就地扩展：`{ "latex": "...", "w"?:..., "h"?:... }`）。
- 验收：得到全量 `name -> LaTeX` 表，覆盖率与旧 PNG 集一致。

### [ ] 6. 改造 InlineMath/UI 与 JSON 数据为 LaTeX 驱动 + 缓存
- [ ] 改 `InlineMath.gd`：命中映射时调用 GDExtension 渲染为 `ImageTexture` 并缓存（key：latex+font_size+color）。
- [ ] 缓存策略：内存 LRU + 可选磁盘缓存到 `user://`（首帧避免重复光栅化）。
- [ ] `strip_formulas()`（朗读用）继续去标记；确认 TTS 路径不受影响。
- [ ] UI 回退策略：扩展不可用时退回旧 PNG（灰度降级），保证桌面/低端机不崩。
- [ ] 灰度迁移 `data/*.json`：优先读取 LaTeX 字段，缺失时用旧 `{f:名称}`/PNG。
- 验收：题目/选项/标题公式全部走 LaTeX 渲染，文本不再依赖预烘焙 PNG。

### [ ] 7. Android arm64 交叉编译 .so 并集成
- [ ] 配置 NDK 交叉编译（arm64-v8a），产出 `lib*.so`。
- [ ] 在 `.gdextension` 增加 Android aarch64 条目；核对 `export_presets.cfg`：
      - `use_gradle_build=false`、`compress_native_libraries=false`（README 约定）。
- [ ] 导出 APK 并在真机/模拟器安装启动。
- 验收：Android 上扩展加载成功，公式可渲染。

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
