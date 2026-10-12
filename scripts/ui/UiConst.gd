class_name UiConst
## 全局层级与布局常量，避免魔法数散落各处。

# ---- CanvasLayer 层级 ----
const LAYER_STAGE_HUD := 5     # 关卡内答题/选项叠加层(位于关卡 UI 之下)
const LAYER_STAGE_UI := 10     # 关卡常规 UI(题干、操作栏、反馈)
const LAYER_PANEL := 50        # 全屏面板(世界地图/知识树弹层)
const LAYER_PET := 90          # 萌宠悬浮层
const LAYER_TOAST := 100       # 顶部提示

# ---- 布局 ----
const CARD_W := 920.0          # 全宽内容卡片宽度(档案库 / 错题笔记等)
