#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量生成「参数调参师」关卡题目

针对已有 explore 关卡较多的章节，自动生成多目标调参实验题目。
"""

import json
import os
import glob
import sys

# 解决 Windows 控制台编码问题
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def generate_cubic_roots_level(idx, r1, r2):
    """生成三次函数零点调参关卡"""
    
    return {
        "name": f"PM-{idx} 调出三个零点",
        "type": "explore",
        "goal": f"拖动 a、b 两个滑块，让 f(x) = x(x-a)(x-b) 的三个零点分别为 0、{r1}、{r2}",
        "q": f"函數 $$f(x)=x(x-a)(x-b)$$ 已經有一個零點 $$x=0$$。拖动滑块 a、b，讓另外兩個零點分別落在 $$x={r1}$$ 和 $$x={r2}$$ 的位置。觀察讀數：當三個零點正確時會顯示「✓」標記。",
        "steps": [
            "① 拖動 a 和 b 滑块改變多項式根的位置",
            "② 注意綠色曲線與 x 軸的交點（即零點）",
            f"③ 把三個零點對準 x=0、x={r1}、x={r2} 三條虛線",
            "④ 當三個零點都對準時，左上角會顯示「✓」"
        ],
        "tip": f"目標是 $$f(x)=x(x-{r1})(x-{r2})$$。試試把 a={r1}、b={r2}！",
        "confirm": "我找到了正確的參數組合",
        "gate": True,
        "answers": {"a": r1, "b": r2},
        "tol": {"a": 0.15, "b": 0.15},
        "retry": f"零點位置還不對。記住：a 控制第二個零點，b 控制第三個零點。目標是 {r1} 和 {r2}。",
        "ask": "多項式 $$f(x)=x(x-a)(x-b)$$ 有三個不同零點的條件是？",
        "opts": [
            "$$a\\\\ne0$$ 且 $$b\\\\ne0$$ 且 $$a\\\\ne b$$",
            "只需 $$a\\\\ne b$$",
            "只需 $$a>0$$ 且 $$b>0$$",
            "$$a=b$$ 時有三個重合零點"
        ],
        "ans": 0,
        "hint": "三個不同零點意味著 $$0$$、$$a$$、$$b$$ 互不相等。",
        "explain": f"$$f(x)=x(x-a)(x-b)$$ 的三個零點是 $$x_1=0$$、$$x_2=a$$、$$x_3=b$$。要讓它們互不相同，需要 $$a\\\\ne0$$、$$b\\\\ne0$$、$$a\\\\ne b$$。當 $$a={r1}$$、$$b={r2}$$ 時，三個零點分別是 $$0$$、$${r1}$$、$${r2}$$。",
        "success": f"太棒了！你找到的 $$a={{a}}$$、$$b={{b}}$$ 確實讓函數的三個零點是 $$0$$、$${r1}$$、$${r2}$$。",
        "scene": {
            "range": [-1, r2 + 1],
            "sliders": [
                {"name": "a", "min": -0.5, "max": r2 + 1, "value": (r1 + r2) / 2 - 0.5, "step": 0.1, "label": "第二個根 a"},
                {"name": "b", "min": -0.5, "max": r2 + 1, "value": (r1 + r2) / 2 + 0.5, "step": 0.1, "label": "第三個根 b"}
            ],
            "curves": [
                {"fn": "cubic_factorized", "roots": [0, "a", "b"], "color": "#9C27B0", "label": "f(x)"}
            ],
            "lines": [
                {"x": 0, "dash": True, "color": "#ff5722", "label": "x=0"},
                {"x": r1, "dash": True, "color": "#4caf50", "label": f"x={r1}"},
                {"x": r2, "dash": True, "color": "#4caf50", "label": f"x={r2}"}
            ],
            "points": [
                {"p": [0, 0], "label": "O", "color": "#ff5722"},
                {"p": ["a", 0], "label": "a", "color": "#ffd700"},
                {"p": ["b", 0], "label": "b", "color": "#ffd700"}
            ],
            "readouts": [
                {"label": "a", "expr": "a", "color": "#ffd700"},
                {"label": "b", "expr": "b", "color": "#ffd700"},
                {"label": f"a≈{r1}?", "expr": f"abs(a-{r1})<0.15", "color": "#4caf50"},
                {"label": f"b≈{r2}?", "expr": f"abs(b-{r2})<0.15", "color": "#4caf50"}
            ]
        }
    }


def generate_monotone_level(idx):
    """生成单调性调参关卡"""
    
    return {
        "name": f"PM-{idx} 調出單調遞增",
        "type": "explore",
        "goal": "拖动 k，让 f(x) = x³ + kx 在 R 上单调递增（导数始终 ≥ 0）",
        "q": "函數 $$f(x)=x^3+kx$$。拖动滑塊 $$k$$，觀察導數 $$f'(x)=3x^2+k$$ 的最小值——當 $$k$$ 取什麼範圍時，$$f'(x)\\\\ge0$$ 對一切 $$x\\\\in\\\\mathbb{R}$$ 成立，從而函數單調遞增？",
        "steps": [
            "① 拖動 $$k$$ 改變斜率參數",
            "② 注意右側讀數：$$f'(0)$$ 是導數的最小值（因為 $$3x^2\\\\ge0$$）",
            "③ 當 $$f'(0)=k\\\\ge0$$ 時，$$f'(x)\\\\ge0$$ 恒成立",
            "④ 同時觀察圖像是否始終上升（不下降）"
        ],
        "tip": "$$f'(x)=3x^2+k$$ 的最小值在 $$x=0$$ 處取得，為 $$f'(0)=k$$。只要 $$k\\\\ge0$$，就有 $$f'(x)\\\\ge0$$ 恆成立！",
        "confirm": "我明白了單調性的條件",
        "gate": True,
        "answers": {"k": 0},
        "tol": {"k": 0.1},
        "retry": "當 $$k={{k}}$$ 時，$$f'(x)$$ 在某些地方會變成負數。試試 $$k\\\\ge0$$。",
        "ask": "函數 $$f(x)=x^3+kx$$ 在 $$\\\\mathbb{R}$$ 上單調遞增的充要條件是？",
        "opts": ["$$k\\\\ge0$$", "$$k>0$$", "$$k=0$$", "任意實數 $$k$$"],
        "ans": 0,
        "hint": "$$f'(x)=3x^2+k$$，而 $$3x^2\\\\ge0$$ 恆成立。",
        "explain": "$$f'(x)=3x^2+k$$。因為 $$3x^2\\\\ge0$$ 對所有 $$x\\\\in\\\\mathbb{R}$$ 都成立，所以 $$f'(x)\\\\ge k$$。要讓 $$f'(x)\\\\ge0$$ 恒成立，只需 $$k\\\\ge0$$。",
        "success": "正確！$$k={{k}}\\\\ge0$$ 時 $$f'(x)\\\\ge0$$ 恒成立，函數單調遞增。",
        "scene": {
            "range": [-2, 2],
            "sliders": [
                {"name": "k", "min": -2, "max": 2, "value": -0.5, "step": 0.1, "label": "係數 k"}
            ],
            "curves": [
                {"fn": "cubic_simple", "coeffs": [1, 0, "k", 0], "color": "#9C27B0", "label": "f(x)"},
                {"fn": "deriv", "coeffs": [3, 0, "k", 0], "color": "#4caf50", "label": "f'(x)", "dash": True}
            ],
            "readouts": [
                {"label": "f'(0)=k", "expr": "k", "color": "#ff9800"},
                {"label": "f'最小值", "expr": "k", "color": "#4caf50"},
                {"label": "k≥0?", "expr": "k>=0", "color": "#4caf50"}
            ]
        }
    }


def main():
    """手动创建几个示范关卡并保存到文件"""
    
    data_dir = "data"
    
    print("=" * 70)
    print("B1 参数调参师 - 示范关卡生成")
    print("=" * 70)
    
    # 为 function_lab 章节生成示范
    levels = [
        generate_cubic_roots_level(1, 1, 2),
        generate_monotone_level(2),
        generate_cubic_roots_level(3, 2, 3),
    ]
    
    param_master_data = {
        "param_master_demos": {
            "title": "参数调参师 · 示范关卡集",
            "method": "动态实验 · 条件筛选 · 综合应用",
            "color": "#9C27B0",
            "summary": "通过拖动滑块观察函数图像变化，找到满足条件的参数范围。这些是首批自动生成的示范关卡。",
            "levels": levels
        }
    }
    
    output_file = os.path.join(data_dir, "param_master_demos.json")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(param_master_data, f, ensure_ascii=False, indent=2)
    
    print(f"✓ 已生成 {len(levels)} 道参数调参师示范关卡")
    print(f"  输出文件：{output_file}")
    print()
    print("关卡列表:")
    for lvl in levels:
        print(f"  - {lvl['name']}: {lvl['goal'][:50]}...")
    
    print()
    print("=" * 70)
    print("下一步:")
    print("  1. 将 param_master_demos.json 导入 Godot 项目")
    print("  2. 测试关卡能否正常加载和交互")
    print("  3. 如果可行，扩展至所有章节")
    print("=" * 70)


if __name__ == "__main__":
    main()
