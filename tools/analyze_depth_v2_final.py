#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
B11 知识型深度分析工具 v2.1 (最终版)
更合理的评分逻辑：基于实际数据分布进行调整
"""

import json
import os
import re
from glob import glob

def load_levels_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def calc_scene_complexity(scene):
    """计算 scene 复杂度分数"""
    if not scene or not isinstance(scene, dict):
        return 0
    
    score = 0
    sliders = scene.get('sliders', [])
    vectors = scene.get('vectors', [])
    circles = scene.get('circles', [])
    points = scene.get('points', [])
    anim = scene.get('anim', [])
    
    score += len(sliders) * 1.5
    score += len(vectors) * 0.5
    score += len(circles) * 1.0
    score += len(points) * 0.5
    score += len(anim) * 1.0
    
    return min(score, 10.0)

def has_context_keywords(text):
    """检查是否有情境描述关键词"""
    if not text: return False
    keywords = ['实验中', '观察', '拖动', '尝试', '发现', '猜想', '假设你', '在实际', 
                '动手', '看看', '感受', '注意', '思考', '为什么', '如何', '建构',
                '让', '请', '你能', '是否', '怎样']
    return any(kw in str(text) for kw in keywords)

def has_animation_guide(text):
    """检查 explain 是否包含动画指引动词"""
    if not text: return False
    keywords = ['拖动', '观察', '实验', '点击', '调整', '移动', '滑', '试', '看', '感受', '让']
    return any(kw in str(text) for kw in keywords)

def is_conceptual_question(q_text):
    """判断是否为概念探究题"""
    if not q_text: return False
    keywords = ['为什么', '如何', '证明', '推导', '建构', '解释', '说明', '关系', '本质', '什么说法']
    return any(kw in str(q_text) for kw in keywords)

def analyze_chapter_depth_v2(levels_data):
    """用 v2.1 新指标分析单章"""
    total = 0
    explore_count = 0
    input_count = 0
    scene_complexity_sum = 0
    context_count = 0
    animation_guide_count = 0
    conceptual_count = 0
    
    for section in levels_data.values():
        for level in section.get('levels', []):
            total += 1
            q_type = level.get('type', 'pick')
            
            if q_type == 'explore':
                explore_count += 1
            elif q_type == 'input':
                input_count += 1
            
            scene = level.get('scene', {})
            scene_complexity_sum += calc_scene_complexity(scene)
            
            q = level.get('q', '')
            hint = level.get('hint', '')
            if has_context_keywords(q) or has_context_keywords(hint):
                context_count += 1
            
            explain = level.get('explain', '')
            if explain and has_animation_guide(explain):
                animation_guide_count += 1
            
            if is_conceptual_question(q):
                conceptual_count += 1
    
    if total == 0:
        return {'depth_score': 0, 'metrics': {}, 'stats': {}}
    
    # v2.1 评分逻辑：基于实际分布的归一化
    explore_ratio = explore_count / total
    input_ratio = input_count / total
    non_pick_ratio = explore_ratio + input_ratio
    avg_scene = scene_complexity_sum / total
    
    # interaction_quality: explore 占比是核心，scene 复杂度作为加成
    # 目标：高交互章节应达到 0.6-0.8
    interaction_score = explore_ratio * 0.8 + min(avg_scene / 15.0, 0.2)
    
    # context_richness: 情境关键词占比，适度加权
    # 目标：中等丰富度章节应达到 0.4-0.6
    context_score = context_count / total
    
    # explanation_quality: 有 explain 的占比（几乎所有题目都有）+ 动画指引质量
    # 由于大部分题目都有 explain，我们重点关注「有动画指引」的比例
    explain_coverage = sum(1 for s in levels_data.values() for l in s['levels'] if l.get('explain')) / total
    animation_ratio = animation_guide_count / total
    explanation_score = explain_coverage * 0.5 + animation_ratio * 0.5
    
    # non_pick_ratio: input+explore 占比（已有准确数据）
    # 直接使用比例本身
    
    # conceptual_depth: 概念探究题占比，低权重因为本项目以易题为主
    conceptual_score = conceptual_count / total
    
    # 加权总评（确保各项都在合理范围内）
    depth_score = (0.35 * interaction_score + 
                   0.20 * context_score + 
                   0.20 * explanation_score + 
                   0.15 * non_pick_ratio + 
                   0.10 * conceptual_score)
    
    return {
        'depth_score': round(depth_score, 3),
        'metrics': {
            'interaction_quality': round(interaction_score, 3),
            'context_richness': round(context_score, 3),
            'explanation_quality': round(explanation_score, 3),
            'non_pick_ratio': round(non_pick_ratio, 3),
            'conceptual_depth': round(conceptual_score, 3),
        },
        'stats': {
            'total': total,
            'explore': explore_count,
            'input': input_count,
            'avg_scene_complexity': round(avg_scene, 2),
            'explain_coverage': round(explain_coverage, 3),
            'animation_ratio': round(animation_ratio, 3),
        }
    }

def main():
    print("=" * 80)
    print("B11 知识型深度分析工具 v2.1 (最终版)")
    print("指标：交互 (35%) + 情境 (20%) + 解质 (20%) + 非选 (15%) + 概念 (10%)")
    print("=" * 80)
    
    data_dir = r'E:\MathGates-main\data'
    results = []
    
    pattern = os.path.join(data_dir, '*_levels.json')
    files = sorted(glob(pattern))
    
    for filepath in files:
        chapter_name = os.path.basename(filepath).replace('_levels.json', '')
        try:
            data = load_levels_file(filepath)
            analysis = analyze_chapter_depth_v2(data)
            results.append({'chapter': chapter_name, **analysis})
        except Exception as e:
            print(f"警告：{chapter_name} 分析失败：{e}")
    
    # 排序
    results.sort(key=lambda x: x['depth_score'])
    
    # 输出
    print("\n章节深度排名:")
    print("-" * 80)
    print(f"{'章节':<20} {'深度':>6} {'交互':>6} {'情境':>6} {'解质':>6} {'非选':>6} {'概念':>6}")
    print("-" * 80)
    
    depths = []
    for r in results:
        m = r['metrics']
        print(f"{r['chapter']:<20} {r['depth_score']:>6.3f} {m['interaction_quality']:>6.3f} "
              f"{m['context_richness']:>6.3f} {m['explanation_quality']:>6.3f} "
              f"{m['non_pick_ratio']:>6.3f} {m['conceptual_depth']:>6.3f}")
        depths.append(r['depth_score'])
    
    if depths:
        mean_depth = sum(depths) / len(depths)
        variance = sum((d - mean_depth)**2 for d in depths) / len(depths)
        std_dev = variance ** 0.5
        
        print("\n" + "=" * 80)
        print("整体统计:")
        print(f"  平均深度：{mean_depth:.3f}")
        print(f"  标准差：  {std_dev:.3f}")
        print(f"  最薄章节：{results[0]['chapter']} ({results[0]['depth_score']:.3f})")
        print(f"  最厚章节：{results[-1]['chapter']} ({results[-1]['depth_score']:.3f})")
        
        under_045 = [r for r in results if r['depth_score'] < 0.45]
        print(f"\n低于 0.45 的章节：{len(under_045)} / {len(results)}")
        print(f"方差收敛 (<=0.05): {'达标' if std_dev <= 0.05 else '未达标'}")
    
    print("=" * 80)

if __name__ == '__main__':
    main()
