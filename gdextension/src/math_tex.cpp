#include "math_tex.h"

#include <cstring>
#include <fstream>

#include <godot_cpp/classes/project_settings.hpp>

#include "core/formula.h"
#include "latex.h"
#include "render.h"

#include "backend.h"
#include "font_ft.h"
#include "surface.h"

using namespace godot;

MathTeX *MathTeX::_singleton = nullptr;

MathTeX::MathTeX() = default;
MathTeX::~MathTeX() = default;

MathTeX *MathTeX::get_singleton() { return _singleton; }

void MathTeX::setup_singleton() {
	if (_singleton == nullptr) {
		_singleton = memnew(MathTeX);
	}
}

void MathTeX::teardown_singleton() {
	if (_singleton != nullptr) {
		memdelete(_singleton);
		_singleton = nullptr;
	}
}

void MathTeX::_bind_methods() {
	ClassDB::bind_method(D_METHOD("configure", "res_path"), &MathTeX::configure);
	ClassDB::bind_method(D_METHOD("is_ready"), &MathTeX::is_ready);
	ClassDB::bind_method(D_METHOD("get_res_path"), &MathTeX::get_res_path);
	ClassDB::bind_method(D_METHOD("render", "latex", "font_size", "text_color"), &MathTeX::render,
			DEFVAL(24.f), DEFVAL(Color(1.0f, 1.0f, 1.0f, 1.0f)));
	ClassDB::bind_method(D_METHOD("render_latex", "latex", "font_size", "text_color"),
			&MathTeX::render_latex, DEFVAL(24.f), DEFVAL(Color(1.0f, 1.0f, 1.0f, 1.0f)));
}

bool MathTeX::configure(const String &res_path) {
	_ready = false;
	_res_path = res_path;
	String p = res_path;
	if (p.begins_with("res://")) {
		p = ProjectSettings::get_singleton()->globalize_path(p);
	}
	tex::LaTeX::init(p.utf8().get_data());
	const std::string &root = tex::LaTeX::getResRootPath();
	if (!root.empty()) {
		// Only consider it ready if the resource location was actually found.
		std::string marker = tex::LaTeX::getResRootPath() + "/.clatexmath-res_root";
		std::ifstream f(marker, std::ios::binary);
		_ready = f.good();
	}
	return _ready;
}

Ref<Image> MathTeX::render(const String &latex, float font_size, const Color &text_color) {
	Ref<Image> out;
	if (!_ready) {
		ERR_PRINT("MathTeX: not configured, call configure() first.");
		return out;
	}
	if (latex.is_empty()) {
		return out;
	}
	try {
		// Convert UTF-8 -> wchar_t (UTF-16 on Windows).
		const CharString cs = latex.utf8();
		std::wstring ws = mt::utf8_to_w(cs.get_data());

		tex::Formula formula(ws);
		tex::TeXRenderBuilder builder;
		tex::TeXRender *render = builder.setStyle(tex::TexStyle::display)
										.setTextSize(font_size)
										.setForeground(tex::argb(text_color.a, text_color.r, text_color.g, text_color.b))
										.build(formula);
		if (render == nullptr) {
			ERR_PRINT("MathTeX: failed to build render.");
			return out;
		}

		const int width = render->getWidth();
		const int height = render->getHeight();
		if (width <= 0 || height <= 0) {
			delete render;
			return out;
		}

		mt::Surface surface(width, height);
		mt::Graphics2D_Image g2(surface);
		render->draw(g2, 0, 0);
		delete render;

		PackedByteArray data;
		data.resize((int64_t)surface.px.size());
		if (surface.px.size() > 0) {
			std::memcpy(data.ptrw(), surface.px.data(), surface.px.size());
		}
		out = Image::create_from_data(width, height, false, Image::FORMAT_RGBA8, data);
	} catch (const std::exception &e) {
		ERR_PRINT(String("MathTeX: render error: ") + String(e.what()));
		return Ref<Image>();
	}
	return out;
}

Ref<ImageTexture> MathTeX::render_latex(const String &latex, float font_size, const Color &text_color) {
	Ref<Image> image = render(latex, font_size, text_color);
	if (image.is_null()) {
		return Ref<ImageTexture>();
	}
	return ImageTexture::create_from_image(image);
}