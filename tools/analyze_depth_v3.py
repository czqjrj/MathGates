#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
B11 知识型深度分析工具 v3.0
新指标：方法覆盖 (30%) + 交互质量 (25%) + 难度适宜 (20%) + 解答质量 (15%) + 非选比 (10%)
"""

import json
import os
import re
from glob import glob

# 各章节核心方法列表（用于计算 method_coverage）
CHAPTER_METHODS = {
    'vector': ['概念', '模长单位向量', '加法法则', '减法法则', '数乘线性组合', '坐标运算', '数量积', '夹角投影', '垂直平行', '分点重心'],
    'statistics': ['抽样方法', '样本估计总体', '平均数中位数众数', '方差标准差', '直方图', '散点图相关性', '回归方程', '正态分布'],
    'counting': ['分类原理', '分步原理', '排列', '组合', '综合应用', '捆绑法', '插空法', '隔板法'],
    'probability': ['古典概型', '几何概型', '互斥对立', '条件概率', '乘法公式', '全概率', '贝叶斯', '独立重复试验'],
    'conics': ['椭圆定义', '双曲线定义', '抛物线定义', '标准方程', '几何性质', '焦点三角形', '直线与圆锥曲线', '轨迹方程'],
    # ... 可继续补充其他章节
}

def load_levels_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def detect_methods_in_chapter(levels_data):
    """检测一章中已覆盖的方法（简化版：基于题目标题和题干关键词匹配）"""
    covered = set()
    
    for section in levels_data.values():
        for level in section.get('levels', []):
            name = level.get('name', '').lower()
            q = level.get('q', '').lower()
            text = name + q
            
            # 关键词映射（简化的方法识别规则）
            method_keywords = {
                '数量积': ['数量积', '点积', 'a·b', 'dot'],
                '投影': ['投影', 'proj', '射影'],
                '夹角': ['夹角', 'cosθ', '角度'],
                '垂直': ['垂直', '⊥', 'orthogonal'],
                '平行': ['平行', '共线', '//'],
                '坐标': ['坐标', '(x,y)', '分量'],
                '模长': ['模长', '|a|', '长度'],
                '单位向量': ['单位向量', 'unit vector', '归一化'],
                '加法': ['加法', '+', '首尾相接', '平行四边形'],
                '减法': ['减法', '-', '终点指向'],
                '数乘': ['数乘', 'λa', 'scalar'],
                '分点': ['分点', '定比分点', '中点', '重心'],
                '直方图': ['直方图', 'histogram', '频数分布'],
                '散点图': ['散点图', 'scatter', '相关'],
                '回归': ['回归', 'regression', '拟合'],
                '条件概率': ['条件概率', 'P(A|B)', 'given'],
                '贝叶斯': ['贝叶斯', 'bayes', '逆推'],
                '全概率': ['全概率', 'total probability', '分解'],
                '排列': ['排列', 'permutation', 'P(n,k)'],
                '组合': ['组合', 'combination', 'C(n,k)'],
                '捆绑': ['捆绑', '相邻', '一起'],
                '插空': ['插空', '不相邻', '空隙'],
            }
            
            for method, keywords in method_keywords.items():
                if any(kw in text for kw in keywords):
                    covered.add(method)
    
    return covered

def calc_scene_complexity(scene):
    if not scene or not isinstance(scene, dict):
        return 0
    score = 0
    score += len(scene.get('sliders', [])) * 1.5
    score += len(scene.get('vectors', [])) * 0.5
    score += len(scene.get('circles', [])) * 1.0
    score += len(scene.get('points', [])) * 0.5
    score += len(scene.get('anim', [])) * 1.0
    return min(score, 20.0)

def has_animation_guide(text):
    if not text: return False
    keywords = ['拖动', '观察', '实验', '点击', '调整', '移动', '滑', '试', '看', '感受', '让', '看看']
    return any(kw in str(text) for kw in keywords)

def is_easy_question(level):
    """判断是否为容易题（简化版：无复杂 proof/derivation 字样）"""
    name = level.get('name', '')
    q = level.get('q', '')
    text = name + q
    hard_keywords = ['证明', '推导', '严谨证明', '一般性证明']
    return not any(kw in text for kw in hard_keywords)

def analyze_chapter_depth_v3(levels_data, chapter_name):
    total = 0
    explore_count = 0
    input_count = 0
    easy_count = 0
    hard_count = 0
    scene_complexity_sum = 0
    animation_guide_count = 0
    
    for section in levels_data.values():
        for level in section.get('levels', []):
            total += 1
            q_type = level.get('type', 'pick')
            
            if q_type == 'explore':
                explore_count += 1
            elif q_type == 'input':
                input_count += 1
            
            if is_easy_question(level):
                easy_count += 1
            else:
                hard_count += 1
            
            scene = level.get('scene', {})
            scene_complexity_sum += calc_scene_complexity(scene)
            
            explain = level.get('explain', '')
            if explain and has_animation_guide(explain):
                animation_guide_count += 1
    
    if total == 0:
        return {'depth_score': 0, 'metrics': {}, 'stats': {}}
    
    # 方法覆盖率
    covered_methods = detect_methods_in_chapter(levels_data)
    all_methods = CHAPTER_METHODS.get(chapter_name, [])
    method_coverage = len(covered_methods) / len(all_methods) if all_methods else 0.5
    
    # 交互质量
    explore_ratio = explore_count / total
    avg_scene = scene_complexity_sum / total
    interaction_quality = explore_ratio * 0.7 + min(avg_scene / 20.0, 0.3)
    
    # 难度适宜性（容易题占比 - 难题占比，归一化到 0-1）
    easy_ratio = easy_count / total
    hard_ratio = hard_count / total
    difficulty_appropriateness = 0.5 * (easy_ratio - hard_ratio) + 0.5
    difficulty_appropriateness = max(0, min(1, difficulty_appropriateness))
    
    # 解答质量
    explanation_quality = animation_guide_count / total
    
    # 非选择题比
    non_pick_ratio = (explore_count + input_count) / total
    
    # 加权总评
    depth_score = (0.30 * method_coverage + 
                   0.25 * interaction_quality + 
                   0.20 * difficulty_appropriateness +
                   0.15 * explanation_quality + 
                   0.10 * non_pick_ratio)
    
    return {
        'depth_score': round(depth_score, 3),
        'metrics': {
            'method_coverage': round(method_coverage, 3),
            'interaction_quality': round(interaction_quality, 3),
            'difficulty_appropriateness': round(difficulty_appropriateness, 3),
            'explanation_quality': round(explanation_quality, 3),
            'non_pick_ratio': round(non_pick_ratio, 3),
        },
        'stats': {
            'total': total,
            'explore': explore_count,
            'input': input_count,
            'easy': easy_count,
            'hard': hard_count,
            'methods_covered': len(covered_methods),
            'methods_total': len(all_methods),
        }
    }

def main():
    print("=" * 90)
    print("B11 知识型深度分析工具 v3.0")
    print("指标：方法覆盖 (30%) + 交互质量 (25%) + 难度适宜 (20%) + 解答质量 (15%) + 非选比 (10%)")
    print("=" * 90)
    
    data_dir = r'E:\MathGates-main\data'
    results = []
    
    pattern = os.path.join(data_dir, '*_levels.json')
    files = sorted(glob(pattern))
    
    for filepath in files:
        chapter_name = os.path.basename(filepath).replace('_levels.json', '')
        try:
            data = load_levels_file(filepath)
            analysis = analyze_chapter_depth_v3(data, chapter_name)
            results.append({'chapter': chapter_name, **analysis})
        except Exception as e:
            print(f"警告：{chapter_name} 分析失败：{e}")
    
    results.sort(key=lambda x: x['depth_score'])
    
    print("\n章节深度排名:")
    print("-" * 90)
    print(f"{'章节':<16} {'深度':>6} {'方法':>6} {'交互':>6} {'难度':>6} {'解质':>6} {'非选':>6}")
    print("-" * 90)
    
    depths = []
    for r in results:
        m = r['metrics']
        print(f"{r['chapter']:<16} {r['depth_score']:>6.3f} {m['method_coverage']:>6.3f} "
              f"{m['interaction_quality']:>6.3f} {m['difficulty_appropriateness']:>6.3f} "
              f"{m['explanation_quality']:>6.3f} {m['non_pick_ratio']:>6.3f}")
        depths.append(r['depth_score'])
    
    if depths:
        mean_depth = sum(depths) / len(depths)
        variance = sum((d - mean_depth)**2 for d in depths) / len(depths)
        std_dev = variance ** 0.5
        
        print("\n" + "=" * 90)
        print("整体统计:")
        print(f"  平均深度：{mean_depth:.3f}")
        print(f"  标准差：  {std_dev:.3f}")
        print(f"  最薄章节：{results[0]['chapter']} ({results[0]['depth_score']:.3f})")
        print(f"  最厚章节：{results[-1]['chapter']} ({results[-1]['depth_score']:.3f})")
        
        under_target = [r for r in results if r['depth_score'] < 0.45]
        print(f"\n低于 0.45 的章节：{len(under_target)} / {len(results)}")
        if under_target:
            print("  未达标:", ', '.join([r['chapter'] for r in under_target[:5]]), "...")
        
        status = "达标" if std_dev <= 0.05 else "未达标"
        print(f"\n方差收敛 (<=0.05): {status}")
    
    print("=" * 90)

if __name__ == '__main__':
    main()
