class_name MasteryRules
## A4 第三刀：从 GameData 切出的**领域掌握度纯公式**——无状态、无 IO、无 autoload 依赖。
## 单一来源：单关掌握度(星级 + 清关质量 - 错题惩罚)、错题权重、领域均值、达标/生疏阈值。
## 调用方约定：缓存填充(_recompute_mastery 循环)与 UI 判定仍在调用方，公式在此。
## 单测：tests/Tests.gd::_test_mastery_rules()（构造数据）。

## 领域掌握度达标即解锁对应萌宠部件(只增不减)
const MASTERY_UNLOCK := 0.5
## 已解锁领域掌握度低于此值视为「生疏」(仅影响萌宠表现，不回收形态)
const MASTERY_STALE := 0.35

const STAR_RATIO_MAX := 3.0   ## 满星 3 星 → 星级分 1.0
const STAR_WEIGHT := 0.65     ## 星级分权重
const CLEAN_WEIGHT := 0.25    ## 清关质量(答对率)权重
const WRONG_CAP := 0.4        ## 错题惩罚封顶
const MISTAKE_PER := 0.1      ## 错题本每 1 次错题的权重增量
const MISTAKE_CAP := 0.5      ## 单条错题记录的权重封顶

## 错题本单条记录的惩罚权重：次数 × MISTAKE_PER，封顶 MISTAKE_CAP。
static func mistake_weight(count: int) -> float:
	return minf(MISTAKE_CAP, float(count) * MISTAKE_PER)

## 单关掌握度 0..1：星级分 + 清关质量 - 错题惩罚；
## 未通关(星级 0)不判掌握恒 0；无记录传 (0,0) 即可(除零由 maxi(1,total) 守卫)。
static func level_mastery(star_count: int, clean_count: int, total_count: int, wrong_weight: float) -> float:
	var st := float(star_count) / STAR_RATIO_MAX
	if st <= 0.0:
		return 0.0
	var clean := float(clean_count) / float(maxi(1, total_count))
	return clampf(st * STAR_WEIGHT + clean * CLEAN_WEIGHT - minf(wrong_weight, WRONG_CAP), 0.0, 1.0)

## 领域均值：count 为 0 恒 0(不除零)。
static func domain_mean(sum: float, count: int) -> float:
	return (sum / float(count)) if count > 0 else 0.0
