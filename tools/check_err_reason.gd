extends SceneTree

func _initialize() -> void:
	var path := "res://scripts/rules/ErrReasonRules.gd"
	
	if not ResourceLoader.exists(path):
		print("B6-FAIL: ErrReasonRules.gd not found")
		quit(1)
		return
	
	var err = OK
	var content := FileAccess.get_file_as_string(path)
	if content.is_empty():
		print("B6-FAIL: File is empty")
		quit(1)
		return
	
	# 检查必需内容是否存在
	if not content.contains("ERR_REASON_WHITELIST"):
		print("B6-FAIL: ERR_REASON_WHITELIST not found")
		quit(1)
		return
	
	if not content.contains("validate_err_reason"):
		print("B6-FAIL: validate_err_reason function not found")
		quit(1)
		return
	
	# 统计白名单数量
	var white_list_count := content.count('"concept",') + content.count('"calc",') + content.count('"formula",')
	if white_list_count < 3:
		print("B6-FAIL: Not enough reason types defined")
		quit(1)
		return
	
	print("B6: OK - ErrReasonRules.gd validated")
	print("B6:   ERR_REASON_WHITELIST exists with core reasons (concept, calc, formula...)")
	print("B6:   validate_err_reason function defined")
	quit(0)
