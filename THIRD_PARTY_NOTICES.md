# 第三方声明（THIRD_PARTY_NOTICES）

本项目自身采用**专有授权**（见根目录 `LICENSE`）。本文件汇总本项目**使用与分发**的第三方组件、
字体、美术与音效素材的名称、许可类型与来源，用于应用商店上架核查与合规披露（TODO **F7**）。

> 约定：随安装包**实际分发**的第三方内容标 ✅；仅作为**构建期依赖**、不随包分发的标 ⛔。

---

## 1. 组件与依赖（软件）

| 组件 | 版本 | 许可 | 来源 | 随包分发 |
|---|---|---|---|---|
| Godot Engine | 4.7.2 stable | MIT | https://godotengine.org/license | ✅（导出运行时嵌入） |
| MicroTeX（LaTeX 数学排版库） | 上游 commit `0e3707f` | MIT, © 2020 Nano Michael | https://github.com/NanoMichael/MicroTeX | ✅（编译进 `gdextension/` 本机库） |
| godot-cpp（GDExtension 绑定） | 4.4 分支，commit `b0e3b1e` | MIT | https://github.com/godotengine/godot-cpp | ⛔（`third_party/`，`.gitignore` 排除） |
| Godot 内置组件（FreeType / zlib / libpng 等） | 随引擎 | 各自许可（多为 MIT/BSD/zlib） | https://godotengine.org/license | ✅（随引擎） |

**MIT 许可要求**：再分发时须保留版权声明与许可全文。Godot 与 MicroTeX 的 MIT 许可文本见
`THIRD_PARTY_LICENSES.md`；上架前请在应用内「关于 / 开源许可」页展示（见 §6 检查清单）。

---

## 2. 数学排版字体（随 `gdextension/res.bin` 分发）✅

这些字体由上游 MicroTeX 的 `res/fonts/` 提供，经 `tools/pack_math_res.gd` 打包进 `res.bin`。
**许可全文已随包分发**于 `fonts/licences/`（见下表中「许可文件」一列）。

| 字体文件 | 字体 | 许可 | 许可文件 |
|---|---|---|---|
| `fonts/latin/*`、`fonts/base/cmex10,cmmi10,cmmib10`、`fonts/maths/cmbsy10,cmsy10`、`fonts/maths/special` | Computer Modern（Knuth） | Knuth License（可复制/分发/修改，修改需改名） | ✅ `fonts/licences/Knuth_License.txt` |
| `fonts/euler/eufb10,eufm10`、`fonts/maths/msam10,msbm10` | AMS Euler / AMS Symbols | SIL OFL 1.1（© 1997,2009 American Mathematical Society；含保留字体名） | ✅ `fonts/licences/OFL.txt` |
| `fonts/maths/optional/dsrom10` | dsrom | 自定义宽许可（"use and distribute as you like"，改名限制） | ✅ `fonts/licences/License_for_dsrom.txt` |
| `fonts/maths/rsfs10` | RSFS（Ralph Smith's Formal Script） | **上游无单独许可文件**（RSFS 历来为宽许可） | ⚠️ 待补 |
| `fonts/maths/stmary10` | St Mary's Road（`stmaryrd`） | **上游无单独许可文件** | ⚠️ 待补 |

说明：上表字体均**原样分发、未修改**；OFL 字体的保留字体名（RFN）未被改动，符合 OFL 要求。

### 2.1 已排除：GPLv3 字体（重要）⛔

上游 MicroTeX 的 `res/greek/` 与 `res/cyrillic/` 目录**随附 **GNU GPLv3 许可
（`greek/LICENSE`、`cyrillic/LICENSE` 为完整 GPLv3 文本）。GPLv3 的传染性与本项目「专有发布」
不兼容，因此：

- `tools/pack_math_res.gd` 已将这些目录加入 `EXCLUDE_DIRS`，**不再打进 `res.bin`**；
- 打包体积由 652 KB（78 项）降至 297 KB（43 项），顺带缓解 A13；
- 全仓源码与渲染路径**无任何引用**（数学希腊字母来自 `base/cmmi10` 等，非 `greek/`）；
- 已用 `verify_inline.gd` 复验：`VERIFY_TABLE: total=3904 fail=0`。

> 若日后确需希腊语/西里尔语**正文排版**，须单独引入 OFL/CMS 类可商用字体，**不得**再用上述 GPLv3 字体。

---

## 3. 内置中文字体（待处理）⚠️

| 文件 | 说明 | 体积 | 来源/许可 |
|---|---|---|---|
| `art/fonts/aidianqianfengxingshu.ttf` | 标题用行书字体（「爱点前锋行书」） | **13.8 MB** | **来源与商用许可均未记录、无法核实** |

- 引用位置：`scripts/ui/UI.gd:79`（`_FONT_CANDIDATES` 显式路径）；`art/fonts/` 内**任何** `.ttf/.otf`
  都会被自动加载，故**替换 = 放入新字体文件并删除旧文件**。
- **行动建议（P0 上架前）**：替换为明确可商用的 OFL 字体，例如
  **霞鹜文楷 LXGW WenKai**（OFL）、**思源黑体 Source Han Sans**（OFL）、**得意黑 Smiley Sans**（OFL）；
  既满足授权可追溯，又同时解决 A13 的 13.8 MB 体积问题（子集化后通常 < 3 MB）。
- 在完成替换前，**不建议上架**（授权不可核实是商店审核的常见驳回点）。

---

## 4. 美术与音效素材（待确认来源）⚠️

| 目录 | 内容 | 来源/授权 |
|---|---|---|
| `art/*.png`（`bg_mainhub`、`bg_worldmap`、`island_*`、`icon_*`、`ui_panel` 等）+ `art/*.xcf` | 背景/岛屿/图标/面板；`.xcf` 为 GIMP 源文件（说明为**自制**） | 待确认：若为项目自制，建议在 `art/SOURCES.md` 声明为「项目自制，© 项目组」 |
| `art/android/*` | Android 启动图标（自适应前景/背景/单色） | 同上 |
| `art/formulas/*`、`art/inline/*` | 由 MicroTeX **离线渲染生成的公式 PNG**（`tools/gen_inline.gd` 等） | 生成物，字形来源为 §2 的 CM/AMS 字体 |
| `art/questions/*`、`art/{circle,conic,ellipse,line,sequence,space,vector}/*` | 题干配图（几何图形） | 待确认：若由脚本/手工绘制，建议声明为自制 |
| `audio/*.wav` | 10 个音效（点击/正确/错误/通关等） | **来源未记录**：需确认是自制、CC0 还是需授权；**待补** |

`.xcf` 源文件的存在强烈暗示美术为**项目自制**，但仍需在 `art/SOURCES.md` 与 `audio/SOURCES.md`
中书面声明并签名确认（见该文件）。

---

## 5. 内容与教材的关系（版权声明）

- 本项目的**课程结构**（章节、分册、顺序）**对齐**人教A/苏教等人教版教材的**知识点顺序**，
  以便学习者按教材体系复习；
- **题目均为自编**（题干、选项、解析由项目组撰写），**不逐题复制教材习题**；
- 教材名称、章节名为客观指代，相关教材著作权归各出版社所有，本项目与出版社无隶属关系。

> 若今后确需改编教材原题，须另行取得出版社授权，并在题面注明出处。

---

## 6. 上架检查清单（并入 F2）

- [ ] 根 `LICENSE` 与 `THIRD_PARTY_NOTICES.md` 齐备并随仓库发布；
- [ ] 应用内「关于 / 开源许可」页展示：Godot + MicroTeX 的 MIT 全文、字体许可全文（`THIRD_PARTY_LICENSES.md`）；
- [ ] **替换** `art/fonts/aidianqianfengxingshu.ttf` 为 OFL 字体（并记录许可）；
- [ ] 补 `art/SOURCES.md`、`audio/SOURCES.md` 的素材来源与授权声明；
- [ ] 核实 `rsfs10` / `stmary10` 的许可（或移除并改用已明确许可的替代字体）；
- [ ] 确认 `res.bin` 内**不含** `greek/`、`cyrillic/`（GPLv3）；
- [ ] 应用商店「数据安全 / 隐私」表单与 `docs/隐私政策.md`、F1 的 TTS 外发说明一致。

---

*本文件随第三方组件更新而更新；最近核对：`res.bin` = 43 项，greek/cyrillic 已排除。*
