# 美术素材来源与授权（art/SOURCES.md）

> 用于 TODO **F7** 的上架核查。**本文件中的「待确认」项必须由项目组逐项确认后改为明确结论**，
> 商店审核会核查素材授权；一旦上线后才发现素材不可商用，代价是替换全部美术并重新发版。

## 结论（推断）

目录内保留了 `.xcf`（GIMP）源文件，**强烈提示全部美术为项目自制**；
但仍需书面确认（含素材平台下载件的授权条款）。若为自制，请按下表填写并在文末签名。

## 清单

| 路径 | 内容 | 生成方式 / 来源 | 授权 | 状态 |
|---|---|---|---|---|
| `art/bg_mainhub.png` | 主界面背景 | 自制（源文件 `bg_mainhub.xcf`） | © 项目组 | ⚠️ 待确认 |
| `art/bg_worldmap.png` | 世界地图背景 | 自制（源文件 `bg_worldmap.xcf`） | © 项目组 | ⚠️ 待确认 |
| `art/island_locked.png` / `island_unlocked.png` | 岛屿节点 | 自制（`.xcf`） | © 项目组 | ⚠️ 待确认 |
| `art/icon_book.png` / `icon_lock.png` / `icon_map.png` / `icon_train.png` | 图标 | 自制（`.xcf`） | © 项目组 | ⚠️ 待确认 |
| `art/ui_panel.png` | 通用面板九宫格 | 自制（`ui_panel.xcf`） | © 项目组 | ⚠️ 待确认 |
| `art/android/*.png` | Android 启动图标（自适应前景/背景/单色） | 自制（由图标派生） | © 项目组 | ⚠️ 待确认 |
| `art/formulas/*.png`、`art/inline/*.png` | 数学公式小图 | **程序生成**（MicroTeX 离线渲染，见 `tools/gen_inline.gd` / `tools/verify_inline.gd`） | 生成物；字形来源见 `THIRD_PARTY_NOTICES.md` §2 | ✅ 可追溯 |
| `art/questions/**`、`art/circle/**`、`art/conic/**`、`art/ellipse/**`、`art/line/**`、`art/sequence/**`、`art/space/**`、`art/vector/**` | 题干配图（几何图） | 待确认：脚本/手工绘制？ | 待确认 | ⚠️ |
| `art/fonts/aidianqianfengxingshu.ttf` | 标题行书字体 | **来源不明** | **不可核实** | ❌ 需替换（见下） |

## 待办（P0）

1. **替换标题字体**：删除 `art/fonts/aidianqianfengxingshu.ttf`（13.8 MB，授权不明），
   放入明确可商用的 OFL 字体（推荐「霞鹜文楷 LXGW WenKai」「得意黑 Smiley Sans」；
   `scripts/ui/UI.gd` 会自动加载 `art/fonts/` 下的任意 `.ttf/.otf`）。
   建议同时做子集化以减小体积（关联 A13）。
2. **确认其余素材**：把上表所有 ⚠️ 改为「自制，© 项目组」（或标注第三方来源与授权），
   并在下面签名。

## 声明（由项目组确认后填写）

- 上述美术素材（除字体与程序生成物外）为**本项目自制**，著作权归项目组所有，可随应用商用分发。
- 确认人：___________  日期：___________
