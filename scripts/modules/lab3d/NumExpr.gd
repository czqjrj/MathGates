class_name NumExpr
extends RefCounted
## 3D 实验室参数表达式求值：支持数字、滑块名、算术(+ - * / ^ 括号)与常用函数。
## 三角函数按【角度制】；常量 pi / e。供 SolidBuilder / Lab3DView / Lab3DStage 复用，
## 使立体图形能随滑块实时重建（"实验探究"里的动态几何）。
##
## 用法： NumExpr.eval("sqrt(a*a+b*b)", {"a": 3.0, "b": 4.0}, 0.0) -> 5.0


class _P:
	var s := ""
	var i := 0
	var ok := true
	var dflt := 0.0
	var vars: Dictionary = {}

	func peek() -> String:
		return s[i] if i < s.length() else ""

	func take() -> String:
		var c := peek()
		i += 1
		return c

	func expr() -> float:
		var v := term()
		while ok:
			var c := peek()
			if c == "+":
				take()
				v += term()
			elif c == "-":
				take()
				v -= term()
			else:
				break
		return v

	func term() -> float:
		var v := unary()
		while ok:
			var c := peek()
			if c == "*":
				take()
				v *= unary()
			elif c == "/":
				take()
				var d := unary()
				v = v / d if absf(d) > 1e-12 else 0.0
			elif c == "%":
				take()
				var d2 := unary()
				v = fmod(v, d2) if absf(d2) > 1e-12 else 0.0
			else:
				break
		return v

	func unary() -> float:
		var c := peek()
		if c == "-":
			take()
			return -unary()
		if c == "+":
			take()
			return unary()
		return power()

	func power() -> float:
		var base := primary()
		if peek() == "^":
			take()
			return pow(base, unary())
		return base

	func primary() -> float:
		var c := peek()
		if c == "(":
			take()
			var v := expr()
			if peek() == ")":
				take()
			else:
				ok = false
			return v
		if c.is_valid_float() or c == ".":
			var st := i
			while i < s.length() and (s[i].is_valid_float() or s[i] == "."):
				i += 1
			return s.substr(st, i - st).to_float()
		if _ident_start(c):
			var st2 := i
			while i < s.length() and _ident_char(s[i]):
				i += 1
			var name := s.substr(st2, i - st2)
			if peek() == "(":
				take()
				var args: Array[float] = []
				if peek() != ")":
					args.append(expr())
					while ok and peek() == ",":
						take()
						args.append(expr())
				if peek() == ")":
					take()
				else:
					ok = false
				return _call(name, args)
			return _var(name)
		ok = false
		return 0.0

	func _ident_start(c: String) -> bool:
		return not c.is_empty() and c.is_valid_identifier()

	func _ident_char(c: String) -> bool:
		return c.is_valid_identifier() or c.is_valid_int()

	func _arg(args: Array[float], k: int, d: float) -> float:
		return args[k] if k < args.size() else d

	func _call(name: String, args: Array[float]) -> float:
		match name:
			"sqrt": return sqrt(maxf(_arg(args, 0, 0.0), 0.0))
			"abs": return absf(_arg(args, 0, 0.0))
			"sin": return sin(deg_to_rad(_arg(args, 0, 0.0)))
			"cos": return cos(deg_to_rad(_arg(args, 0, 0.0)))
			"tan": return tan(deg_to_rad(_arg(args, 0, 0.0)))
			"asin": return rad_to_deg(asin(clampf(_arg(args, 0, 0.0), -1.0, 1.0)))
			"acos": return rad_to_deg(acos(clampf(_arg(args, 0, 0.0), -1.0, 1.0)))
			"atan": return rad_to_deg(atan(_arg(args, 0, 0.0)))
			"atan2": return rad_to_deg(atan2(_arg(args, 0, 0.0), _arg(args, 1, 1.0)))
			"pow": return pow(_arg(args, 0, 0.0), _arg(args, 1, 1.0))
			"min": return minf(_arg(args, 0, 0.0), _arg(args, 1, 0.0))
			"max": return maxf(_arg(args, 0, 0.0), _arg(args, 1, 0.0))
			"ln": return log(maxf(_arg(args, 0, 1.0), 1e-12))
			"log": return log(maxf(_arg(args, 0, 1.0), 1e-12)) / log(10.0)
			"exp": return exp(clampf(_arg(args, 0, 0.0), -60.0, 60.0))
			"floor": return floorf(_arg(args, 0, 0.0))
			"ceil": return ceilf(_arg(args, 0, 0.0))
			"round": return roundf(_arg(args, 0, 0.0))
			"sign": return signf(_arg(args, 0, 0.0))
			"deg": return rad_to_deg(_arg(args, 0, 0.0))
			"rad": return deg_to_rad(_arg(args, 0, 0.0))
		return 0.0

	func _var(name: String) -> float:
		if vars.has(name):
			return float(vars[name])
		match name:
			"pi", "PI": return PI
			"e", "E": return 2.718281828459045
			"tau", "TAU": return TAU
		return dflt


## 求值：expr 为字符串时解析表达式，为数字直接返回；失败回退 dflt。
static func eval(expr: String, vars: Dictionary, dflt: float = 0.0) -> float:
	var s := expr.strip_edges().replace(" ", "").replace("　", "")
	if s.is_empty():
		return dflt
	if s.is_valid_float():
		return s.to_float()
	var p := _P.new()
	p.s = s
	p.i = 0
	p.ok = true
	p.dflt = dflt
	p.vars = vars
	var r := p.expr()
	if not p.ok or p.i < p.s.length():
		return dflt
	return r


## 通用取值：数字 / 数值字符串 / 表达式；缺失时用 dflt。
static func num(v: Variant, vars: Dictionary, dflt: float = 0.0) -> float:
	if v == null:
		return dflt
	if v is float or v is int or v is bool:
		return float(v)
	if v is String:
		var s := str(v)
		if s.strip_edges().is_empty():
			return dflt
		return eval(s, vars, dflt)
	return dflt


## [x,y,z] / ["a","b","c"] -> Vector3（分量可用表达式）。
static func vec3(v: Variant, vars: Dictionary, dflt: Vector3 = Vector3.ZERO) -> Vector3:
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Vector3(num(a[0], vars, dflt.x), num(a[1], vars, dflt.y), num(a[2], vars, dflt.z))
	return dflt


## 紧凑数值格式化（整数不带小数）。
static func fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.0005:
		return str(int(roundf(v)))
	return "%.3f" % v
