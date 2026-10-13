#pragma once

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

// Singleton: renders LaTeX source through MicroTeX into Godot Images/Textures.
class MathTeX : public Object {
	GDCLASS(MathTeX, Object)

public:
	MathTeX();
	~MathTeX();

	static MathTeX *get_singleton();
	static void setup_singleton();
	static void teardown_singleton();

	bool configure(const String &res_path);
	bool is_ready() const { return _ready; }
	String get_res_path() const { return _res_path; }

	Ref<Image> render(const String &latex, float font_size, const Color &text_color);
	Ref<ImageTexture> render_latex(const String &latex, float font_size, const Color &text_color);

protected:
	static void _bind_methods();

private:
	static MathTeX *_singleton;
	bool _ready = false;
	String _res_path;
};

} // namespace godot