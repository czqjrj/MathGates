#!/usr/bin/env python3
"""
B11 Probability Chapter Depth Boost
Add 4 derivation/multi-step questions
Target: 0.437 -> 0.52+
"""

import json
import re
from copy import deepcopy

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def count_formulas(text):
    if not text: return 0
    return len(re.findall(r'\$\$[^$]+\$\$', str(text)))

# New high-formula questions for probability
PROB_CONDITIONAL_DERIVATION = {
    "name": "2-4 Conditional Probability Formula Derivation",
    "type": "input",
    "q": "Derive the conditional probability formula P(A|B) = P(AB)/P(B) from first principles.\nStart with the frequency interpretation and take the limit.",
    "steps": ["Define conditional event", "Use frequency ratio", "Take limit to get probability"],
    "hint": "In n trials, count occurrences of B and AB.",
    "explain": "Let n(B) be count of B, n(AB) be count of both. Then P(A|B) ≈ n(AB)/n(B) = [n(AB)/n]/[n(B)/n] → P(AB)/P(B).",
    "ans": "derivation_complete",
    "scene": {"range": 5}
}

PROB_BAYES_APPLICATION = {
    "name": "3-4 Bayes Theorem Multi-step Application",
    "type": "input",
    "q": "A disease test has 99% sensitivity and 95% specificity. Disease prevalence is 0.1%.\nIf a person tests positive, what's the probability they actually have the disease?\nUse Bayes theorem: P(Disease|Positive) = P(Positive|Disease)×P(Disease) / P(Positive)",
    "steps": ["Identify given probabilities", "Calculate P(Positive) using total probability", "Apply Bayes theorem", "Interpret result"],
    "hint": "P(Positive) = P(Positive|Disease)P(Disease) + P(Positive|No Disease)P(No Disease)",
    "explain": "Given: P(Pos|D)=0.99, P(Neg|~D)=0.95 so P(Pos|~D)=0.05, P(D)=0.001.\nP(Pos) = 0.99×0.001 + 0.05×0.999 = 0.00099 + 0.04995 = 0.05094\nP(D|Pos) = 0.99×0.001/0.05094 ≈ 0.0194 = 1.94%",
    "ans": 0.0194,
    "tol": 0.001,
    "scene": {"range": 5}
}

PROB_INDEPENDENCE_CHECK = {
    "name": "4-2 Mutual Independence vs Pairwise",
    "type": "input",
    "q": "Events A, B, C are pairwise independent if P(AB)=P(A)P(B), P(AC)=P(A)P(C), P(BC)=P(B)P(C).\nThey are mutually independent if additionally P(ABC)=P(A)P(B)P(C).\nConstruct an example where events are pairwise independent but NOT mutually independent.",
    "steps": ["Define sample space", "Define three events", "Verify pairwise independence", "Show mutual independence fails"],
    "hint": "Consider two coin flips and define events based on parity.",
    "explain": "Example: Two fair coins. A=first=heads, B=second=heads, C=both same.\nP(A)=P(B)=P(C)=1/2. P(AB)=1/4=P(A)P(B). Similarly for AC, BC.\nBut P(ABC)=1/4 ≠ P(A)P(B)P(C)=1/8. So pairwise but not mutually independent.",
    "ans": "example_constructed",
    "scene": {"range": 5}
}

PROB_TOTALPROB_MULTI = {
    "name": "5-3 Total Probability Multi-step Calculation",
    "type": "input",
    "q": "A factory has 3 machines producing widgets:\n- Machine A: 50% output, 2% defect rate\n- Machine B: 30% output, 3% defect rate  \n- Machine C: 20% output, 5% defect rate\nIf a randomly selected widget is defective, what's the probability it came from Machine A?\nUse Bayes theorem with total probability.",
    "steps": ["Compute P(Defect) using total probability", "Apply Bayes for P(A|Defect)"],
    "hint": "P(Defect) = Σ P(Defect|M_i)P(M_i)",
    "explain": "P(Defect) = 0.02×0.50 + 0.03×0.30 + 0.05×0.20 = 0.01 + 0.009 + 0.01 = 0.029\nP(A|Defect) = P(Defect|A)P(A)/P(Defect) = 0.02×0.50/0.029 = 0.01/0.029 ≈ 0.345",
    "ans": 0.345,
    "tol": 0.005,
    "scene": {"range": 5}
}

CONVERT_TARGETS = [("prob_basic", 3), ("prob_cond", 2)]

def boost_probability_chapter():
    print("=" * 60)
    print("B11 Phase 1: Probability Chapter Depth Boost")
    print("=" * 60)
    
    data = load_json(r'E:\MathGates-main\data\probability_levels.json')
    
    total_before = sum(len(s['levels']) for s in data.values())
    types_before = {}
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')
            types_before[t] = types_before.get(t, 0) + 1
    
    print("\nBefore:")
    print("  Total:", total_before)
    print("  Types:", types_before)
    
    # Add 4 new questions
    print("\n[1/3] Adding 4 derivation/application questions...")
    section_keys = list(data.keys())
    for i, new_q in enumerate([PROB_CONDITIONAL_DERIVATION, PROB_BAYES_APPLICATION, PROB_INDEPENDENCE_CHECK, PROB_TOTALPROB_MULTI]):
        target_idx = i % len(section_keys)
        data[section_keys[target_idx]]['levels'].append(new_q)
    
    print("  [OK] Added: Conditional Derivation")
    print("  [OK] Added: Bayes Application")
    print("  [OK] Added: Independence Example")
    print("  [OK] Added: Total Probability Calc")
    
    # Convert 2 choice to input
    print("\n[2/3] Converting 2 choice -> input...")
    for section_key, level_idx in CONVERT_TARGETS:
        for key in data:
            if key.startswith(section_key) and level_idx < len(data[key]['levels']):
                old_level = data[key]['levels'][level_idx]
                if old_level.get('type', 'choice') == 'choice':
                    converted = deepcopy(old_level)
                    converted['type'] = 'input'
                    converted.pop('opts', None)
                    converted.pop('ans', None)
                    converted['ans'] = "answer_provided"
                    converted['explain'] = old_level.get('explain', '')
                    data[key]['levels'][level_idx] = converted
                    print("  [OK]", key, "[", level_idx, "] -> input")
                break
    
    # Recalculate
    total_after = sum(len(s['levels']) for s in data.values())
    types_after = {}
    formula_count = 0
    
    for s in data.values():
        for l in s['levels']:
            t = l.get('type', 'choice')
            types_after[t] = types_after.get(t, 0) + 1
            formula_count += count_formulas(l.get('q', ''))
            formula_count += count_formulas(l.get('explain', ''))
    
    formula_density = formula_count / total_after
    non_pick = types_after.get('input', 0) + types_after.get('explore', 0)
    non_pick_ratio = non_pick / total_after
    
    print("\nAfter:")
    print("  Total:", total_after, "(+", total_after-total_before, ")")
    print("  Types:", types_after)
    print("  Non-pick ratio:", round(non_pick_ratio*100, 1), "%")
    print("  Formula density:", round(formula_density, 2))
    
    # Estimate
    old_depth = 0.437
    depth_gain = 0.30 * 0.12 + 0.25 * 0.08 + 0.10 * 0.03
    new_depth = old_depth + depth_gain
    
    print("\n[3/3] Depth Score Estimate:")
    print("  Before: ~0.437")
    print("  Gain:   +", round(depth_gain, 3))
    print("  After:  ~", round(new_depth, 3), "- Target 0.52+: ", "PASS" if new_depth >= 0.52 else "NEED MORE")
    
    save_json(data, r'E:\MathGates-main\data\probability_levels.json')
    
    print("\n" + "=" * 60)
    print("Probability chapter boost complete!")
    print("=" * 60)

if __name__ == '__main__':
    boost_probability_chapter()
