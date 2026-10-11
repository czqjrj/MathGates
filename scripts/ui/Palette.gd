class_name Palette
extends RefCounted
## 科学绘图统一调色板：坐标平面 / 探索器 / 3D 视图共享，避免同一颜色在十余处重复定义。
## 用法：const COL_AXIS := Palette.AXIS （保留本地别名，绘制代码无需改动）。

const GRID := Color(1.0, 1.0, 1.0, 0.05)
const GRID_MAJOR := Color(1.0, 1.0, 1.0, 0.10)
const AXIS := Color(0.55, 0.62, 0.78, 1.0)
const TEXT := Color(0.92, 0.96, 1.0, 1.0)
const DIM := Color(0.62, 0.68, 0.80, 1.0)
const ACCENT := Color(0.369, 0.902, 1.0, 1.0)
const GOLD := Color(1.0, 0.83, 0.47, 1.0)
const SUCCESS := Color(0.204, 0.827, 0.600, 1.0)
const DANGER := Color(0.98, 0.44, 0.52, 1.0)
const INDIGO := Color(0.66, 0.55, 1.0, 1.0)
const ORANGE := Color(1.0, 0.72, 0.42, 1.0)
