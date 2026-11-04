#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Make explore questions actually completable.

LabStage's explore flow is two-stage:
  1. confirm the experiment (optionally gated by slider answers);
  2. answer a follow-up multiple-choice (`ask` + `opts` + `ans`).

Generated explore questions (and several older boost-added ones) have
`gate: true` with `answers: {}` (never passes) and/or no `opts` (dead end after
confirm). This script repairs both:
  * gate with empty answers -> gate false;
  * missing opts -> a 4-option follow-up, correct option = goal/success;
  * ans -> 0 (first option).
"""
import glob
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

DATA = r'E:\MathGates-main\data'


def build_opts(q):
    correct = str(q.get('goal') or q.get('success') or '').strip()
    if not correct:
        correct = str(q.get('ask') or q.get('name') or '上面的实验结论').strip()
    return [
        correct,
        "改变滑块后，这个结论就不再成立",
        "结论只对某一个特殊参数偶然成立",
        "不需要观察参数变化，直接套公式即可",
    ]


def main():
    files = 0
    gated = 0
    added_opts = 0
    for path in sorted(glob.glob(os.path.join(DATA, '*_levels.json'))):
        data = json.load(open(path, 'r', encoding='utf-8'))
        changed = False
        for sec in data.values():
            if not isinstance(sec, dict):
                continue
            for q in sec.get('levels', []):
                if not isinstance(q, dict) or q.get('type') != 'explore':
                    continue
                answers = q.get('answers')
                if q.get('gate') and not (isinstance(answers, dict) and answers):
                    q['gate'] = False
                    gated += 1
                    changed = True
                opts = q.get('opts')
                if not (isinstance(opts, list) and opts):
                    q['opts'] = build_opts(q)
                    q['ans'] = 0
                    added_opts += 1
                    changed = True
        if changed:
            files += 1
            json.dump(data, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(f"files changed          : {files}")
    print(f"gate true -> false      : {gated}")
    print(f"follow-up opts added    : {added_opts}")


if __name__ == '__main__':
    main()
