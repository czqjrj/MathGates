# -*- coding: utf-8 -*-
"""
B11 · 模块间质量方差分析工具
计算各章节的「深度」指标，用于量化题目复杂度与内容充实度

口径（2026-11-03 修正，见 docs/B11_模块质量方差整改方案.md §1.3）：

1) **章节覆盖面**：旧版按 `data/<章节 id>_levels.json` 硬拼路径，27 章里只有 22 章命中。
   `line_eq` / `circle_eq` / `recurrence_methods` / `function_methods` / `solid` 五个
   章节的关卡放在 `line` / `circle` / `recurrence` / `function_lab` / `solid_methods` 文件里
   （课程表通过 `lab`+`lab_ref` / `sequence` / `conic` / `method` 指向），旧版直接 `continue`
   静默跳过——**B11 的方差从来没把「直线方程 / 圆的方程 / 立体几何」算进去**。

2) **题型判定**：旧版只认 `type == "pick"` 为选择题，但全库 `type` 有 5 种写法：
   缺省（133 轮）、`choice`（413 轮）、`pick`（6 轮）、`input`、`interact`。
   于是 413 轮 `choice` 被算成「非选择」，10% 权重的分量对 20/24 章都是错的。
   现与 `tools/check_questions.gd` 用同一套判定（B1 看板口径）：
   有非空 opts → 选择（ans 为数组即多选）；否则按 input / interact 分类。
   `explore` 轮的收尾同样是四选一，按选择题计，但单独统计轮数便于 B3/B4 对照。

3) **字段是否真的显示**：`explain` / `steps` 由 `StageBase._level_ok/_wrong` 渲染，
   只有继承 StageBase 的场景（LabStage / Lab3DStage / SequenceStage）会显示。
   `ConicStage`（extends Control）与 `SolidChallenge`（extends Node3D）自带一套反馈，
   **只读 `hint`，从不读 `explain`/`steps`**——在这些章节里给数据补解析，
   学生永远看不到，分数却会涨，属于假指标。
   现在按场景把「可测轮次」圈出来：`explain_ratio` 的分母只算**会显示解析**的轮次；
   完全没有可测轮次的章节标 `n/a` 并排除在方差统计外（`solid` 就是这种）。
"""
import json
import os
import sys

# 权重与归一化上限：与文档 §2 一致，改这里必须同步改文档
W_FORMULA = 0.30
W_STEPS = 0.25
W_EXPLAIN = 0.20
W_QLEN = 0.15
W_NONPICK = 0.10
NORM_FORMULA = 3.0   # 公式/题 达到 3.0 即封顶
NORM_STEPS = 3.0     # 步骤/题 达到 3.0 即封顶
NORM_QLEN = 100.0    # 题干均长达到 100 字即封顶

# 场景 → 会渲染哪些数据字段（与脚本源码一致，改引擎显示能力时必须同步这张表）
STAGE_FEEDBACK = {
    'LabStage.tscn': {'hint': True, 'explain': True, 'steps': True},
    'Lab3DStage.tscn': {'hint': True, 'explain': True, 'steps': True},
    'SequenceStage.tscn': {'hint': True, 'explain': True, 'steps': True},
    'ConicStage.tscn': {'hint': True, 'explain': False, 'steps': False},
    'SolidChallenge.tscn': {'hint': True, 'explain': False, 'steps': False},
}
STAGE_DEFAULT = {'hint': True, 'explain': False, 'steps': False}


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


def classify_round(level):
    """按 check_questions.gd 的口径判定题型（不信任 `type` 单一来源）"""
    rtype = str(level.get('type', '') or '')
    if rtype == 'input':
        return 'input'
    if rtype == 'interact' or 'gate' in level or 'answers' in level:
        return 'interact'
    opts = level.get('opts')
    if isinstance(opts, list) and len(opts) >= 2:
        return 'multi' if isinstance(level.get('ans'), list) else 'single'
    return 'other'


def stage_name(scene_path):
    return os.path.basename(str(scene_path)) if scene_path else ''


def stage_feedback(scene_path):
    return STAGE_FEEDBACK.get(stage_name(scene_path), STAGE_DEFAULT)


_open_cache = {}


def _load(path):
    if path not in _open_cache:
        with open(path, encoding='utf-8') as f:
            _open_cache[path] = json.load(f)
    return _open_cache[path]


def chapter_rounds(chapter):
    """按课程表的指针取出本章所有轮次，返回 [(来源文件, 关卡键, 轮次, scene)]。

    指针优先级：lab+lab_ref → sequence → conic → method(solid)。
    全部缺失时退回 `data/<id>_levels.json`（兼容老数据）。
    """
    out = []
    for lv in chapter.get('levels', []):
        scene = str(lv.get('scene', ''))
        group = None   # (path, key)

        lab = lv.get('lab')
        if lab:
            path = 'data/%s_levels.json' % lab
            key = lv.get('lab_ref') or lv.get('id')
            if os.path.exists(path) and key in _load(path):
                group = (path, key)
        if group is None and lv.get('sequence'):
            path = 'data/recurrence_levels.json'
            key = lv['sequence']
            if os.path.exists(path) and key in _load(path):
                group = (path, key)
        if group is None and lv.get('conic'):
            path = 'data/conic_levels.json'
            key = lv['conic']
            if os.path.exists(path) and key in _load(path):
                group = (path, key)
        if group is None and lv.get('method') and chapter.get('id') == 'solid':
            path = 'data/solid_methods.json'
            key = lv['method']
            if os.path.exists(path) and key in _load(path).get('methods', {}):
                out.extend((path, key, r, scene)
                           for r in _load(path)['methods'][key].get('levels', []))
                continue
        if group is None:
            path = 'data/%s_levels.json' % chapter['id']
            key = lv.get('id')
            if os.path.exists(path) and key in _load(path):
                group = (path, key)
        if group is not None:
            for r in _load(group[0])[group[1]].get('levels', []):
                out.append((group[0], group[1], r, scene))
    return out


def analyze_chapter(chapter):
    """分析单个章节的深度指标"""
    chapter_id = chapter['id']
    rounds = chapter_rounds(chapter)
    if not rounds:
        return None

    total_questions = 0
    kind_counts = {}
    type_counts = {}
    hint_count = 0
    explain_count = 0
    total_steps = 0
    steps_rounds = 0
    total_formula = 0
    q_length_sum = 0
    n_explain_measurable = 0
    n_steps_measurable = 0

    for _path, _key, level, scene in rounds:
        if not isinstance(level, dict):
            continue

        total_questions += 1
        fb = stage_feedback(scene)

        # 题型：真实 `type` 与判定结果分开记，便于核对口径
        q_type = str(level.get('type', '') or '<none>')
        type_counts[q_type] = type_counts.get(q_type, 0) + 1
        kind = classify_round(level)
        kind_counts[kind] = kind_counts.get(kind, 0) + 1

        # 提示和解析：只有场景真的显示，才算「学生拿到了反馈」
        if level.get('hint'):
            hint_count += 1
        if fb['explain']:
            n_explain_measurable += 1
            if level.get('explain'):
                explain_count += 1

        # 步骤数（只有交互/探究轮带 steps，且只有 StageBase 会显示）
        steps = level.get('steps', [])
        if fb['steps']:
            n_steps_measurable += 1
        if isinstance(steps, list) and steps:
            total_steps += len(steps)
            steps_rounds += 1

        # 公式数与题干长度：q 在任何场景都会显示
        q_text = level.get('q', '')
        total_formula += count_formula(q_text)
        q_length_sum += len(str(q_text))

    if total_questions == 0:
        return None

    # 解析覆盖率的分母只算「会显示解析」的轮次；分母为 0 说明该章根本测不了这一维
    if n_explain_measurable == 0:
        return {
            'id': chapter_id,
            'na': True,
            'reason': '场景（%s）不显示 explain/steps，深度指标不适用'
                      % stage_name(rounds[0][3]),
            'total_questions': total_questions,
            'kind_dist': kind_counts,
            'type_dist': type_counts,
        }

    explain_ratio = explain_count / n_explain_measurable
    steps_per_q = total_steps / n_steps_measurable if n_steps_measurable else 0.0
    formula_per_q = total_formula / total_questions
    avg_q_len = q_length_sum / total_questions
    hint_ratio = hint_count / total_questions

    # **深度综合评分** (加权计算)
    # 权重设计参考教育测量理论：
    # - 公式密度 (30%): 数学思维的抽象程度
    # - 平均步骤 (25%): 解题过程的复杂程度
    # - 解析覆盖率 (20%): 诊断性反馈的质量
    # - 题干长度 (15%): 问题表述的完整度
    # - 非选择题比例 (10%): 开放型题目的占比
    non_pick = total_questions - kind_counts.get('single', 0) - kind_counts.get('multi', 0)
    non_pick_ratio = non_pick / total_questions

    depth_score = (
        W_FORMULA * min(formula_per_q / NORM_FORMULA, 1.0) +
        W_STEPS * min(steps_per_q / NORM_STEPS, 1.0) +
        W_EXPLAIN * explain_ratio +
        W_QLEN * min(avg_q_len / NORM_QLEN, 1.0) +
        W_NONPICK * non_pick_ratio
    )

    return {
        'id': chapter_id,
        'na': False,
        'total_questions': total_questions,
        'measured_questions': n_explain_measurable,
        'kind_dist': kind_counts,
        'type_dist': type_counts,
        'non_pick_ratio': round(non_pick_ratio, 3),
        'hint_ratio': round(hint_ratio, 3),
        'explain_ratio': round(explain_ratio, 3),
        'steps_per_q': round(steps_per_q, 2),
        'steps_rounds': steps_rounds,
        'formula_per_q': round(formula_per_q, 2),
        'avg_q_len': round(avg_q_len, 1),
        'depth_score': round(depth_score, 3),
    }


def load_results():
    with open('data/curriculum.json', encoding='utf-8') as f:
        curriculum = json.load(f)

    results = []
    excluded = []
    empty = []
    for ch in curriculum['chapters']:
        result = analyze_chapter(ch)
        if result is None:
            empty.append(ch['id'])
        elif result.get('na'):
            excluded.append(result)
        else:
            results.append(result)

    # 反空转：扫不到东西必须是红灯，不能是「全绿」
    if not results:
        print('[FAIL] 一个章节都没扫到 —— 检查是否在仓库根目录运行、data/curriculum.json 是否存在')
        sys.exit(1)
    if empty:
        print('[WARN] 以下章节一条轮次都没取到：%s' % ', '.join(empty))

    results.sort(key=lambda x: x['depth_score'])
    return results, excluded


def main():
    as_json = '--json' in sys.argv
    results, excluded = load_results()

    if as_json:
        print(json.dumps({'chapters': results, 'excluded': excluded},
                         ensure_ascii=False, indent=2))
        return

    print("=" * 104)
    print("B11 · 模块间质量方差分析报告")
    print("=" * 104)
    print()
    print(f"{'章节 ID':<18} {'题':>4} {'深分':>6} {'公式/题':>7} {'步骤/题':>7} "
          f"{'解析%':>6} {'非选%':>6} {'题干':>5}  {'单选':>4} {'多选':>4} {'填空':>4} {'交互':>4}")
    print("-" * 104)

    for r in results:
        k = r['kind_dist']
        print(f"{r['id']:<18} {r['total_questions']:>4} {r['depth_score']:>6.3f} "
              f"{r['formula_per_q']:>7.2f} {r['steps_per_q']:>7.2f} "
              f"{r['explain_ratio']*100:>5.1f}% {r['non_pick_ratio']*100:>5.1f}% "
              f"{r['avg_q_len']:>5.0f}  "
              f"{k.get('single', 0):>4} {k.get('multi', 0):>4} "
              f"{k.get('input', 0):>4} {k.get('interact', 0):>4}")

    print()
    print("=" * 104)
    print("深度指标定义（0-1 归一化，越高越深）:")
    print("  depth_score = 0.30×公式密度 + 0.25×平均步骤 + 0.20×解析覆盖率 + 0.15×题干长度 + 0.10×非选择题比")
    print("  题型口径与 check_questions 一致：有非空 opts 即选择题（explore 轮收尾按选择题计）")
    print("  解析/步骤只在 StageBase 系场景计分（ConicStage / SolidChallenge 不显示这两项）")
    print()

    if excluded:
        print("不参与统计的章节（字段不落地，改动数据不会有任何学生可见效果）:")
        for r in excluded:
            print(f"  - {r['id']}（{r['total_questions']} 题）：{r['reason']}")
        print()

    scores = [r['depth_score'] for r in results]
    mean_score = sum(scores) / len(scores)
    variance = sum((s - mean_score) ** 2 for s in scores) / len(scores)
    std_dev = variance ** 0.5

    print("深度指标统计:")
    print(f"  参与章节数：{len(results)}（另有 {len(excluded)} 章不适用）")
    print(f"  均值：{mean_score:.3f}")
    print(f"  方差：{variance:.4f}")
    print(f"  标准差：{std_dev:.4f}")
    print(f"  最薄 ({min(scores):.3f}): {min(results, key=lambda x: x['depth_score'])['id']}")
    print(f"  最深 ({max(scores):.3f}): {max(results, key=lambda x: x['depth_score'])['id']}")
    print()

    print("=" * 104)
    print("整改建议:")

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
