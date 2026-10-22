#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""分析 explore 关卡的 gate 覆盖率"""

import json
import glob
import os
import sys

# 解决 Windows 控制台编码问题
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def count_type_in_file(filepath):
    """统计文件中的 explore 和 gate 数量"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 统计 type="explore"
    explore_count = content.count('"type": "explore"')
    
    # 统计 gate:true (在 steps 后面的上下文中)
    gate_count = content.count('"gate": true')
    
    return explore_count, gate_count

def analyze_all_files():
    data_dir = "data"
    results = []
    
    json_files = glob.glob(os.path.join(data_dir, "*_levels.json"))
    
    total_explore = 0
    total_gate = 0
    
    for filepath in sorted(json_files):
        filename = os.path.basename(filepath)
        explore_count, gate_count = count_type_in_file(filepath)
        
        if explore_count > 0:
            has_missing = gate_count < explore_count
            status = "⚠️ 缺失" if has_missing else "✅ 完整"
            
            results.append({
                'file': filename,
                'explore': explore_count,
                'gate': gate_count,
                'missing': explore_count - gate_count,
                'status': status
            })
            
            total_explore += explore_count
            total_gate += gate_count
    
    print("=" * 70)
    print("B1 题型分析：explore 关卡的 gate 覆盖率")
    print("=" * 70)
    
    for r in sorted(results, key=lambda x: x['missing'], reverse=True):
        print(f"{r['file']}: explore={r['explore']:2d}, gate={r['gate']:2d}, 缺{r['missing']:2d} {r['status']}")
    
    print("=" * 70)
    print(f"总计：explore={total_explore}, gate={total_gate}, 可增补={total_explore - total_gate}")
    print(f"当前覆盖率：{total_gate/total_explore*100:.1f}%" if total_explore > 0 else "无数据")
    print("=" * 70)

if __name__ == "__main__":
    analyze_all_files()
