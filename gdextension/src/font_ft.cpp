#include "font_ft.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <map>

#include "common.h"
#include "surface.h"

#include <ft2build.h>
#include FT_FREETYPE_H

namespace {
// Global FreeType resources (single-threaded use).
FT_Library &g_lib() {
	static FT_Library lib = nullptr;
	return lib;
}

std::map<std::string, FT_Face> &g_faces() {
	static std::map<std::string, FT_Face> faces;
	return faces;
}

FT_Face &g_fallback() {
	static FT_Face fb = nullptr;
	return fb;
}

const std::string k_fallback_path = "C:/Windows/Fonts/segoeui.ttf";

bool ensure_ft() {
	if (g_lib() == nullptr) {
		if (FT_Init_FreeType(&g_lib()) != 0) return false;
	}
	return true;
}

FT_Face load_face(const std::string &path) {
	if (path.empty()) return nullptr;
	auto it = g_faces().find(path);
	if (it != g_faces().end()) return it->second;
	if (!ensure_ft()) return nullptr;
	FT_Face face = nullptr;
	if (FT_New_Face(g_lib(), path.c_str(), 0, &face) != 0) return nullptr;
	g_faces()[path] = face;
	return face;
}

bool file_exists(const std::string &path) {
	std::ifstream f(path.c_str(), std::ios::binary);
	return f.good();
}
} // namespace

namespace mt {

Font_ft::Font_ft(const std::string &file_path, float size) : _size(size > 0.f ? size : 1.f) {
	_file = file_path;
	load_from_file(file_path);
}

Font_ft::Font_ft(const std::string &family, int style, float size)
		: _size(size > 0.f ? size : 1.f), _style(style) {
	std::string path = resolve_family(family, style);
	_file = path;
	load_from_file(path);
	if (_face == nullptr) {
		_file = k_fallback_path;
		load_from_file(k_fallback_path);
	}
}

void Font_ft::load_from_file(const std::string &path) {
	_face = load_face(path);
}

std::string Font_ft::resolve_family(const std::string &family, int style) const {
	std::string f = family;
	std::transform(f.begin(), f.end(), f.begin(), [](unsigned char c) { return (char)::tolower(c); });

	std::string base;
	if (f.find("sans") != std::string::npos) {
		base = "cmss10";
	} else if (f.find("tt") != std::string::npos || f.find("typewriter") != std::string::npos ||
			f.find("mono") != std::string::npos) {
		base = "cmtt10";
	} else {
		base = "cmr10";
	}
	if (style & tex::BOLD) {
		if (f.find("sans") != std::string::npos) base = "cmssbx10";
		else if (f.find("tt") != std::string::npos) base = "cmtt10";
		else base = "cmbx10";
	}
	if (style & tex::ITALIC) {
		if (f.find("sans") != std::string::npos) base = "cmssi10";
		else if (f.find("tt") != std::string::npos) base = "cmtt10";
		else base = "cmti10";
	}
	std::string root = tex::RES_BASE.empty() ? _res_root : tex::RES_BASE;
	if (root.empty()) root = "res";
	if (root.back() != '/' && root.back() != '\\') root += "/";
	std::string optional = root + "fonts/latin/optional/" + base + ".ttf";
	std::string regular = root + "fonts/latin/" + base + ".ttf";
	if (style & (tex::BOLD | tex::ITALIC)) {
		if (file_exists(optional)) return optional;
	}
	return regular;
}

float Font_ft::getSize() const { return _size; }

tex::sptr<tex::Font> Font_ft::deriveFont(int style) const {
	return std::make_shared<Font_ft>(_file, _size);
}

bool Font_ft::operator==(const tex::Font &f) const {
	const auto *o = dynamic_cast<const Font_ft *>(&f);
	return o && o->_face == _face && o->_size == _size;
}

bool Font_ft::operator!=(const tex::Font &f) const { return !(*this == f); }

FT_Face Font_ft::fallback_face() const {
	if (g_fallback() == nullptr) {
		g_fallback() = load_face(k_fallback_path);
	}
	return g_fallback();
}

float glyph_advance(const Font_ft &font, wchar_t ch, float pixel_size) {
	FT_UInt idx = 0;
	FT_Face face = font.face();
	if (face != nullptr) idx = FT_Get_Char_Index(face, (FT_ULong)ch);
	if (idx == 0) {
		FT_Face fb = font.fallback_face();
		if (fb != nullptr && fb != face) {
			face = fb;
			idx = FT_Get_Char_Index(face, (FT_ULong)ch);
		}
	}
	if (face == nullptr || idx == 0) return 0.f;
	if (pixel_size <= 0.f) pixel_size = 1.f;
	FT_Set_Char_Size(face, (FT_F26Dot6)(pixel_size * 64.f), (FT_F26Dot6)(pixel_size * 64.f), 72, 72);
	if (FT_Load_Glyph(face, idx, FT_LOAD_DEFAULT) == 0) {
		return (float)face->glyph->advance.x / 64.f;
	}
	return 0.f;
}

void draw_char_glyph(const Font_ft &font, wchar_t ch, float pixel_size, float bx, float by,
		std::uint32_t color, Surface &srf) {
	if (!ensure_ft()) return;
	FT_Face face = font.face();
	FT_UInt idx = face ? FT_Get_Char_Index(face, (FT_ULong)ch) : 0;
	if (idx == 0) {
		FT_Face fb = font.fallback_face();
		if (fb != nullptr && fb != face) {
			face = fb;
			idx = FT_Get_Char_Index(face, (FT_ULong)ch);
		}
	}
	if (face == nullptr || idx == 0) return;
	if (pixel_size <= 0.f) pixel_size = 1.f;
	FT_Set_Char_Size(face, (FT_F26Dot6)(pixel_size * 64.f), (FT_F26Dot6)(pixel_size * 64.f), 72, 72);
	if (FT_Load_Glyph(face, idx, FT_LOAD_RENDER | FT_LOAD_TARGET_NORMAL) != 0) return;
	const FT_GlyphSlot slot = face->glyph;
	const FT_Bitmap &bm = slot->bitmap;
	if (bm.width == 0 || bm.rows == 0) return;
	const int ox = (int)std::floor(bx) + slot->bitmap_left;
	const int oy = (int)std::floor(by) - slot->bitmap_top;
	for (unsigned r = 0; r < bm.rows; r++) {
		for (unsigned c = 0; c < bm.width; c++) {
			int alpha = 0;
			if (bm.pixel_mode == FT_PIXEL_MODE_GRAY) {
				alpha = bm.buffer[(size_t)r * bm.pitch + c];
			} else if (bm.pixel_mode == FT_PIXEL_MODE_MONO) {
				alpha = ((bm.buffer[(size_t)r * bm.pitch + (c >> 3)] >> (7 - (c & 7))) & 1) ? 255 : 0;
			} else {
				continue;
			}
			if (alpha <= 0) continue;
			srf.blend(ox + (int)c, oy + (int)r, (float)alpha / 255.f, color);
		}
	}
}

TextLayout_ft::TextLayout_ft(const std::wstring &src, const tex::sptr<tex::Font> &font)
		: _src(src), _font(font) {}

void TextLayout_ft::getBounds(tex::Rect &bounds) {
	const float design = _font ? _font->getSize() : 10.f;
	float w = 0.f;
	float asc = 0.f, desc = 0.f;
	const auto *ff = _font ? dynamic_cast<const Font_ft *>(_font.get()) : nullptr;
	FT_Face base = ff ? ff->face() : nullptr;
	if (base == nullptr && ff) base = ff->fallback_face();
	if (base) {
		FT_Set_Char_Size(base, (FT_F26Dot6)(design * 64.f), (FT_F26Dot6)(design * 64.f), 72, 72);
		asc = (float)base->size->metrics.ascender / 64.f;
		desc = (float)base->size->metrics.descender / 64.f;
	} else {
		asc = design * 0.8f;
		desc = -design * 0.2f;
	}
	if (ff) {
		for (wchar_t ch : _src) {
			w += glyph_advance(*ff, ch, design);
		}
	}
	_asc = asc;
	_desc = desc;
	_total_advance = w;
	// Design-space box; TextRenderingBox scales it by size/10.
	bounds.x = 0.f;
	bounds.y = -asc;
	bounds.w = w;
	bounds.h = asc - desc;
	if (bounds.h <= 0.f) bounds.h = design;
}

void TextLayout_ft::draw(tex::Graphics2D &g2, float x, float y) {
	const auto *ff = _font ? dynamic_cast<const Font_ft *>(_font.get()) : nullptr;
	if (!ff) return;
	float c = 0.f;
	for (wchar_t ch : _src) {
		g2.drawChar(ch, x + c, y);
		c += glyph_advance(*ff, ch, ff->getSize());
	}
}

} // namespace mt

// ---- MicroTeX platform statics implemented by this backend ----

namespace tex {

Font *Font::create(const std::string &file, float size) { return new mt::Font_ft(file, size); }

sptr<Font> Font::_create(const std::string &name, int style, float size) {
	return std::make_shared<mt::Font_ft>(name, style, size);
}

sptr<TextLayout> TextLayout::create(const std::wstring &src, const sptr<Font> &font) {
	return std::make_shared<mt::TextLayout_ft>(src, font);
}

} // namespace tex