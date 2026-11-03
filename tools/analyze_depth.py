# -*- coding: utf-8 -*-
"""
B11 · 模块间质量方差分析工具
计算各章节的「深度」指标，用于量化题目复杂度与内容充实度
"""
import json
import os
import sys

def count_formula(text):
    """统计公式数量"""
    if not text:
        return 0
    s = str(text)
    # LaTeX 公式计数
    latex_dollar = s.count('$$') // 2
    latex_frac = s.count('\\frac')
    latex_power = s.count('^') + s.count('{^')
    unicode_math = sum(1 for c in s if c in '²³αβγδθλμπΣΔ')
    return latex_dollar + latex_frac + latex_power + unicode_math

def analyze_chapter(chapter_id, data):
    """分析单个章节的深度指标"""
    total_questions = 0
    type_counts = {}
    hint_count = 0
    explain_count = 0
    total_steps = 0
    total_formula = 0
    total_opts = 0
    q_length_sum = 0
    
    for group_key, group_value in data.items():
        levels_list = group_value.get('levels', [])
        for level in levels_list:
            if not isinstance(level, dict):
                continue
            
            total_questions += 1
            
            # 类型分布
            q_type = level.get('type', 'pick')
            type_counts[q_type] = type_counts.get(q_type, 0) + 1
            
            # 选项数
            opts = level.get('opts', [])
            if isinstance(opts, list):
                total_opts += len(opts)
            
            # 提示和解析
            if level.get('hint'):
                hint_count += 1
            if level.get('explain'):
                explain_count += 1
            
            # 步骤数
            steps = level.get('steps', [])
            if isinstance(steps, list):
                total_steps += len(steps)
            
            # 公式数
            q_text = level.get('q', '')
            fc = count_formula(q_text)
            total_formula += fc
            
            # 题干长度
            q_length_sum += len(str(q_text))
    
    if total_questions == 0:
        return None
    
    # 计算各项指标
    avg_opts = total_opts / total_questions
    hint_ratio = hint_count / total_questions
    explain_ratio = explain_count / total_questions
    steps_per_q = total_steps / total_questions
    formula_per_q = total_formula / total_questions
    avg_q_len = q_length_sum / total_questions
    
    # **深度综合评分** (加权计算)
    # 权重设计参考教育测量理论：
    # - 公式密度 (30%): 数学思维的抽象程度
    # - 平均步骤 (25%): 解题过程的复杂程度  
    # - 解析覆盖率 (20%): 诊断性反馈的质量
    # - 题干长度 (15%): 问题表述的完整度
    # - 非选择题比例 (10%): 开放型题目的占比
    non_pick_ratio = 1.0 - (type_counts.get('pick', 0) / total_questions)
    
    depth_score = (
        0.30 * min(formula_per_q / 3.0, 1.0) +  # 归一化到 0-1
        0.25 * min(steps_per_q / 3.0, 1.0) +
        0.20 * explain_ratio +
        0.15 * min(avg_q_len / 100.0, 1.0) +
        0.10 * non_pick_ratio
    )
    
    return {
        'id': chapter_id,
        'total_questions': total_questions,
        'type_dist': type_counts,
        'non_pick_ratio': round(non_pick_ratio, 3),
        'avg_opts': round(avg_opts, 2),
        'hint_ratio': round(hint_ratio, 3),
        'explain_ratio': round(explain_ratio, 3),
        'steps_per_q': round(steps_per_q, 2),
        'formula_per_q': round(formula_per_q, 2),
        'avg_q_len': round(avg_q_len, 1),
        'depth_score': round(depth_score, 3)
    }

def main():
    # 读取课程表
    with open('data/curriculum.json', encoding='utf-8') as f:
        curriculum = json.load(f)
    
    results = []
    
    for ch in curriculum['chapters']:
        chapter_id = ch['id']
        filename = f'data/{chapter_id}_levels.json'
        
        if not os.path.exists(filename):
            continue
        
        with open(filename, encoding='utf-8') as f:
            data = json.load(f)
        
        result = analyze_chapter(chapter_id, data)
        if result:
            results.append(result)
    
    # 按深度评分排序
    results.sort(key=lambda x: x['depth_score'])
    
    print("=" * 90)
    print("B11 · 模块间质量方差分析报告")
    print("=" * 90)
    print()
    print(f"{'章节 ID':<20} {'题':>4} {'深分':>6} {'公试':>6} {'步数':>6} {'解板':>6} {'非选':>6} {'题干':>6}")
    print("-" * 90)
    
    for r in results:
        print(f"{r['id']:<20} {r['total_questions']:>4} {r['depth_score']:>6.3f} "
              f"{r['formula_per_q']:>6.2f} {r['steps_per_q']:>6.2f} "
              f"{r['explain_ratio']*100:>5.1f}% {r['non_pick_ratio']*100:>5.1f}% "
              f"{r['avg_q_len']:>5.0f}")
    
    print()
    print("=" * 90)
    print("深度指标定义（0-1 归一化，越高越深）:")
    print("  depth_score = 0.30×公式密度 + 0.25×平均步骤 + 0.20×解析覆盖率 + 0.15×题干长度 + 0.10×非选择题比")
    print()
    
    # 计算方差
    scores = [r['depth_score'] for r in results]
    mean_score = sum(scores) / len(scores)
    variance = sum((s - mean_score) ** 2 for s in scores) / len(scores)
    std_dev = variance ** 0.5
    
    print("深度指标统计:")
    print(f"  均值：{mean_score:.3f}")
    print(f"  方差：{variance:.4f}")
    print(f"  标准差：{std_dev:.4f}")
    print(f"  最薄 ({min(scores):.3f}): {min(results, key=lambda x: x['depth_score'])['id']}")
    print(f"  最深 ({max(scores):.3f}): {max(results, key=lambda x: x['depth_score'])['id']}")
    print()
    
    # 输出建议
    print("=" * 90)
    print("整改建议:")
    
    # 找出深度低于 0.5 的章节
    shallow_chapters = [r for r in results if r['depth_score'] < 0.5]
    if shallow_chapters:
        print(f"\n以下 {len(shallow_chapters)} 个章节深度不足 (score < 0.5)，建议优先补强:")
        for r in shallow_chapters[:5]:
            print(f"  - {r['id']}: 当前 {r['depth_score']:.3f}, 主要短板:")
            if r['formula_per_q'] < 2:
                print(f"      * 公式密度低 ({r['formula_per_q']:.1f}), 建议增加含多步推导的题目")
            if r['explain_ratio'] < 0.7:
                print(f"      * 解析覆盖率低 ({r['explain_ratio']*100:.1f}%), 建议补充错因分析")
            if r['steps_per_q'] < 1.5:
                print(f"      * 平均步骤少 ({r['steps_per_q']:.1f}), 建议增加探究轮次或复合问题")
    
    print()

if __name__ == '__main__':
    main()
