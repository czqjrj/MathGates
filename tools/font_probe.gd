extends Node
## 探测正文字体对「数学符号」的字形覆盖（窗口模式运行）。
## 用法： godot --path . res://tools/font_probe.tscn

const CHARS := "²³⁰¹₀₁₂₃ₙ√·×÷±≤≥≠≈∞∈∉⊆⊇∪∩→←⇒⇔∀∃∠°′″ΔαβγθλμνπρωΩΣ∑∫⌒≅∥⊥⊙△□≡∅⟨⟩"

func _ready() -> void:
	var fonts := {
		"UI.font": UI.font(),
		"UI.font_bold": UI.font_bold(),
		"UI.mono_font": UI.mono_font(),
		"UI.title_font": UI.title_font(),
	}
	var lines: Array[String] = []
	for name in fonts:
		var f: Font = fonts[name]
		var missing := ""
		for i in CHARS.length():
			var ch := CHARS[i]
			if not f.has_char(ch.unicode_at(0)):
				missing += ch
		lines.append("%s 缺字形: %s" % [name, "（无）" if missing == "" else missing])
	var out := "\n".join(lines) + "\n"
	DirAccess.make_dir_recursive_absolute("res://build")
	var fw := FileAccess.open("res://build/font_probe.txt", FileAccess.WRITE)
	fw.store_string(out)
	fw.close()
	print("PROBE DONE")
	get_tree().quit()
