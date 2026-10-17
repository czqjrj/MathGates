extends SceneTree
## A13 · 资源入库/体积护栏（headless，可进 CI）。
##
## 用法： godot --headless --path . --script res://tools/check_assets.gd
##
## 检查：
##   1. 项目内不得出现美术**源文件**（.xcf/.psd/.blend/.kra/.ai/.sketch）——
##      它们应放 `assets_src/`（已 gitignore，不入库/不进包）；
##   2. 单文件超过 `PER_FILE_WARN_MB` 时告警（便于发现新塞进仓库的大资源）；
##   3. 资源总体积超过 `BUDGET_WARN_MB` 告警、超过 `BUDGET_FAIL_MB` 直接失败。
##
## 退出码：0 = 通过（可有告警）；1 = 有违规（源文件入库 / 超硬预算）。

const BANNED_EXT := ["xcf", "psd", "blend", "kra", "ai", "sketch"]
## 这些目录本来就是「源文件/依赖/构建产物」的家，不参与检查。
const SKIP_DIRS := [
	".godot", ".git", "build", "android", "assets_src", "third_party", "godot-cpp",
	"build_microtex", "keystore", "mathtex_test",
	"bin", "build-android",
]
const PER_FILE_WARN_MB := 15.0
const BUDGET_WARN_MB := 22.0
const BUDGET_FAIL_MB := 40.0

var _total := 0
var _files := 0
var _banned: Array[String] = []
var _oversize: Array[String] = []

func _initialize() -> void:
	_scan("res://")
	var mb := _total / 1048576.0
	print("ASSETS: %.2f MB over %d files, banned=%d, oversize=%d" % [mb, _files, _banned.size(), _oversize.size()])
	for b in _banned:
		print("  [banned] 源文件不应入库（移到 assets_src/）：", b)
	for o in _oversize:
		print("  [big] 单文件偏大：", o)
	var fail := false
	if not _banned.is_empty():
		print("ASSETS-FAIL: 有 %d 个美术源文件入库" % _banned.size())
		fail = true
	if mb > BUDGET_FAIL_MB:
		print("ASSETS-FAIL: 资源总体积 %.2fMB 超过硬预算 %.0fMB" % [mb, BUDGET_FAIL_MB])
		fail = true
	elif mb > BUDGET_WARN_MB:
		print("ASSETS-WARN: 资源总体积 %.2fMB 超过告警线 %.0fMB（考虑降采样/替换大字体）" % [mb, BUDGET_WARN_MB])
	quit(1 if fail else 0)

func _scan(dir_path: String) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir_path.path_join(n)
		if d.current_is_dir():
			if not n.begins_with(".") and not SKIP_DIRS.has(n):
				_scan(p)
		else:
			_count_file(p, n)
		n = d.get_next()
	d.list_dir_end()

func _count_file(path: String, name: String) -> void:
	var ext := name.get_extension().to_lower()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var size := f.get_length()
	f.close()
	if size <= 0:
		return
	_files += 1
	_total += size
	if BANNED_EXT.has(ext):
		_banned.append("%s (%.2fMB)" % [path, size / 1048576.0])
	if size / 1048576.0 > PER_FILE_WARN_MB:
		_oversize.append("%s (%.2fMB)" % [path, size / 1048576.0])
