#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
B11 · Vector 章现状分析脚本
统计题目数量、类型分布、公式密度等指标
"""

import json
import re

def count_formulas(text):
    """简单统计 LaTeX 公式数量"""
    if not text:
        return 0
    # 统计 $$...$$ 和 \(...\) 中的公式
    return len(re.findall(r'\$\$[^$]+\$\$', text)) + len(re.findall(r'\\\[.*?\\\]', text, re.DOTALL))

def analyze_vector_chapter():
    with open('E:\\MathGates-main\\data\\vector_levels.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    total_questions = 0
    type_distribution = {}
    total_formulas = 0
    total_steps = 0
    
    details = []
    
    for section_id, section in data.items():
        levels = section.get('levels', [])
        
        for level in levels:
            total_questions += 1
            q_type = level.get('type', 'pick')
            type_distribution[q_type] = type_distribution.get(q_type, 0) + 1
            
            # 计算公式数
            q_text = level.get('q', '')
            explain = level.get('explain', '')
            hint = level.get('hint', '')
            
            formulas_in_q = count_formulas(q_text)
            formulas_in_explain = count_formulas(explain)
            formulas_in_hint = count_formulas(hint)
            
            opts = level.get('opts', [])
            formulas_in_opts = sum(count_formulas(str(opt)) for opt in opts)
            
            level_formulas = formulas_in_q + formulas_in_explain + formulas_in_hint + formulas_in_opts
            total_formulas += level_formulas
            
            # 计算步骤数
            steps = level.get('steps', [])
            level_steps = len(steps) if isinstance(steps, list) else 0
            total_steps += level_steps
            
            details.append({
                'section': section_id,
                'name': level.get('name', ''),
                'type': q_type,
                'formulas': level_formulas,
                'steps': level_steps,
                'has_explain': bool(explain)
            })
    
    # 计算指标
    formula_density = total_formulas / total_questions if total_questions > 0 else 0
    steps_per_question = total_steps / total_questions if total_questions > 0 else 0
    non_pick_count = sum(1 for d in details if d['type'] != 'pick')
    non_pick_ratio = non_pick_count / total_questions if total_questions > 0 else 0
    explain_coverage = sum(1 for d in details if d['has_explain']) / total_questions if total_questions > 0 else 0
    
    print("=" * 70)
    print("Vector 章深度分析（Phase 1 整改前）")
    print("=" * 70)
    print(f"\n基础统计:")
    print(f"  总题数：{total_questions}")
    print(f"  题型分布：{type_distribution}")
    print(f"\n核心指标:")
    print(f"  公式密度：{formula_density:.2f} 公式/题")
    print(f"  平均步骤：{steps_per_question:.2f} 步/题")
    print(f"  解析覆盖率：{explain_coverage*100:.1f}%")
    print(f"  非选择题比：{non_pick_ratio*100:.1f}%")
    print(f"\n深度评分估算 (按 B11 公式):")
    print(f"  formula_density 归一化：min({formula_density}/3.0, 1.0) = {min(formula_density/3.0, 1.0):.3f}")
    print(f"  steps_per_q 归一化：min({steps_per_question}/3.0, 1.0) = {min(steps_per_question/3.0, 1.0):.3f}")
    print(f"  explain_coverage: {explain_coverage:.3f}")
    print(f"  non_pick_ratio: {non_pick_ratio:.3f}")
    
    # 假设 question_length 约为 50 字符（需要实际计算）
    question_length_norm = 0.5  # 暂定值
    depth_score = (0.30 * min(formula_density/3.0, 1.0) + 
                   0.25 * min(steps_per_question/3.0, 1.0) + 
                   0.20 * explain_coverage + 
                   0.15 * question_length_norm + 
                   0.10 * non_pick_ratio)
    print(f"\n  → depth_score ≈ {depth_score:.3f}")
    print(f"\n目标: 通过补强将 depth_score 提升至 0.45+")
    print(f"当前短板: 公式密度 ({formula_density:.2f}) 和非选择题比 ({non_pick_ratio*100:.1f}%)")
    print("\n" + "=" * 70)

if __name__ == '__main__':
    analyze_vector_chapter()
