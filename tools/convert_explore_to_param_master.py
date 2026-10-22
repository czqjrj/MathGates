#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量转换 explore 关卡为参数调参师题型

扫描所有 *_levels.json 文件，找出有 sliders 但没有 gate 的 explore 关卡，
自动生成带 gate 验证的参数调参师题目。
"""

import json
import os
import glob
import sys
from copy import deepcopy

# 解决 Windows 控制台编码问题
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


def detect_target_values(scene):
    """从场景配置中推断合理的目标值"""
    sliders = scene.get('sliders', [])
    targets = {}
    
    for slider in sliders:
        name = slider.get('name', '')
        min_val = float(slider.get('min', -3))
        max_val = float(slider.get('max', 3))
        current_val = float(slider.get('value', 0))
        
        # 根据滑动范围中间值作为默认目标
        target = (min_val + max_val) / 2
        
        # 某些特定变量特殊处理
        label_lower = slider.get('label', '').lower()
        if name == 'r' or 'radius' in label_lower:
            target = max(1.0, min_val + (max_val - min_val) * 0.6)
        elif name == 'a' and ('center' in label_lower or '圆心' in slider.get('label', '')):
            target = 1 if current_val < 0 else -1
        elif name == 'b' and ('center' in label_lower or '圆心' in slider.get('label', '')):
            target = -1 if current_val > 0 else 1
        elif name == 'k':
            target = 1 if current_val < 1 else 2
        elif name == 'e':  # 离心率
            target = 0.5
        elif name == 'd':  # 公差
            target = 1 if current_val <= 1 else 2
        elif name == 'q':  # 公比
            target = 1.5 if current_val < 1.5 else 2
        elif name == 'p':  # 概率
            target = 0.5
        
        # 四舍五入到较整的值
        if abs(target - round(target)) < 0.1:
            target = float(round(target))
        elif abs(target - round(target * 2) / 2) < 0.1:
            target = float(round(target * 2) / 2)
        
        targets[name] = target
    
    return targets


def generate_gate_question(original_level, targets):
    """基于原始关卡生成 gate 验证问题"""
    
    # 简化版：直接生成通用问题
    return {
        'ask': '拖动滑块使参数达到目标值的操作要点是？',
        'opts': ['逐一调整各参数直到读数显示「✓」', '随机拖动直到图像符合预期', '只调整一个参数即可', '不需要调整'],
        'ans': 0
    }


def convert_to_param_master(original_level, chapter_name="default"):
    """将单个 explore 关卡转换为参数调参师格式"""
    
    # 检查是否有 sliders
    scene = original_level.get('scene', {})
    sliders = scene.get('sliders', [])
    
    if not sliders:
        return None  # 无法转换
    
    # 检测目标值
    targets = detect_target_values(scene)
    
    if not targets:
        return None
    
    # 生成新问题
    qa_info = generate_gate_question(original_level, targets)
    
    # 构建新的参数调参师关卡
    new_level = deepcopy(original_level)
    new_level['name'] = f"PM-{chapter_name.upper()}_{original_level.get('name', '').split('.')[-1]}"
    new_level['goal'] = f"拖动滑块使{', '.join([f'{k}={v}' for k, v in targets.items()])}"
    
    # 增强步骤说明
    steps = original_level.get('steps', [])
    enhanced_steps = steps[:2] if len(steps) >= 2 else steps
    enhanced_steps.append(f"③ 把参数调到目标值：{', '.join([f'{k}={v}' for k, v in targets.items()])}")
    enhanced_steps.append("④ 达到目标时左上角显示「✓」")
    new_level['steps'] = enhanced_steps
    
    # 添加 gate 验证
    new_level['confirm'] = "参数已经调到目标值"
    new_level['gate'] = True
    new_level['answers'] = targets
    new_level['tol'] = {k: 0.1 + 0.05 * abs(v) for k, v in targets.items()}  # 动态容差
    
    # 修改 retry 提示
    retry_msg = "参数还未完全对准目标："
    for k, v in targets.items():
        retry_msg += f"\n  • {k} 当前={{{{{k}}}}}，需要 {k}={v}"
    new_level['retry'] = retry_msg
    
    # 替换追问问题和选项
    new_level['ask'] = qa_info['ask']
    new_level['opts'] = qa_info['opts']
    new_level['ans'] = qa_info['ans']
    
    # 更新成功消息
    success_parts = []
    for k, v in targets.items():
        success_parts.append(f"{k}={v}")
    new_level['success'] = f"太棒了！你找到的参数组合 {', '.join(success_parts)} 满足条件。"
    
    # 增强 readouts（如果有的话）
    if 'readouts' not in scene:
        scene['readouts'] = []
    
    for k, v in targets.items():
        scene['readouts'].append({
            "label": f"{k}≈{v}?",
            "expr": f"abs({k}-{v})<{new_level['tol'][k]}",
            "color": "#4caf50"
        })
    
    return new_level


def process_chapter_file(filepath):
    """处理单个章节文件"""
    
    filename = os.path.basename(filepath)
    converted_count = 0
    total_explore = 0
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 提取章节数据
        chapter_key = list(data.keys())[0] if data else ""
        chapter_data = data[chapter_key]
        levels = chapter_data.get('levels', [])
        
        converted_levels = []
        
        for i, level in enumerate(levels):
            if level.get('type') != 'explore':
                continue
            
            total_explore += 1
            
            # 检查是否已有 gate
            if level.get('gate'):
                continue  # 已经有 gate，跳过
            
            # 尝试转换
            new_level = convert_to_param_master(level, chapter_key.split('_')[0])
            
            if new_level:
                converted_levels.append(new_level)
                converted_count += 1
        
        # 如果有转换成功的关卡，保存到新文件
        if converted_levels:
            output_filename = filename.replace('_levels.json', '_param_auto.json')
            output_path = os.path.join(os.path.dirname(filepath), output_filename)
            
            output_data = {
                f"param_auto_{chapter_key}": {
                    "title": f"参数调参师 · 自动生成 · {chapter_data.get('title', chapter_key)}",
                    "method": "批量转换 · 智能目标检测",
                    "color": "#9C27B0",
                    "summary": f"从原有 explore 关卡自动转换生成的参数调参师题目，共 {len(converted_levels)} 道。",
                    "levels": converted_levels
                }
            }
            
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(output_data, f, ensure_ascii=False, indent=2)
            
            print(f"✓ {filename}: 探索关卡={total_explore}, 已转换={converted_count}")
            return converted_count
        
        print(f"  {filename}: 探索关卡={total_explore}, 无需转换")
        return 0
        
    except Exception as e:
        print(f"✗ {filename}: 错误 - {e}")
        return 0


def main():
    """主函数：批量处理所有章节"""
    
    data_dir = "data"
    json_files = glob.glob(os.path.join(data_dir, "*_levels.json"))
    
    print("=" * 70)
    print("B1 参数调参师 - 批量转换器")
    print("正在扫描并转换 explore → param_master...")
    print("=" * 70)
    print()
    
    total_converted = 0
    chapters_processed = []
    
    for filepath in sorted(json_files):
        count = process_chapter_file(filepath)
        if count > 0:
            total_converted += count
            chapters_processed.append(os.path.basename(filepath))
    
    print()
    print("=" * 70)
    print(f"总计：转换了 {total_converted} 道参数调参师题目")
    print(f"处理章节：{len(chapters_processed)} 个")
    
    if chapters_processed:
        print("\n已生成的文件:")
        for ch in chapters_processed:
            auto_file = ch.replace('_levels.json', '_param_auto.json')
            print(f"  - {auto_file}")
    
    print()
    print("=" * 70)
    print("下一步:")
    print("  1. 在 Godot 中测试任意生成的 _param_auto.json 文件")
    print("  2. 验证转换后的关卡能否正常加载和交互")
    print("  3. 如果可行，考虑优化目标值检测算法")
    print("=" * 70)


if __name__ == "__main__":
    main()
