#pragma once

#include <cstdint>
#include <string>

#include "graphic/graphic.h"

struct FT_FaceRec_;
using FT_Face = FT_FaceRec_ *;

namespace mt {

class Surface;

// FreeType-based Font / TextLayout backend for MicroTeX.
class Font_ft : public tex::Font {
public:
	Font_ft(const std::string &file, float size);
	Font_ft(const std::string &family, int style, float size);
	~Font_ft() = default;

	float getSize() const override;
	tex::sptr<tex::Font> deriveFont(int style) const override;
	bool operator==(const tex::Font &f) const override;
	bool operator!=(const tex::Font &f) const override;

	FT_Face face() const { return _face; }
	// A system face with wide coverage (CJK). Used when the CM font lacks a
	// glyph for a character (e.g. CJK inside \text{}).
	FT_Face fallback_face() const;
	int style() const { return _style; }
	const std::string &file() const { return _file; }
	void set_res_root(const std::string &root) { _res_root = root; }

private:
	void load_from_file(const std::string &path);
	std::string resolve_family(const std::string &family, int style) const;

	FT_Face _face = nullptr;
	float _size = 1.f;
	int _style = tex::PLAIN;
	std::string _file;
	std::string _res_root;
};

class TextLayout_ft : public tex::TextLayout {
public:
	TextLayout_ft(const std::wstring &src, const tex::sptr<tex::Font> &font);
	~TextLayout_ft() = default;

	void getBounds(tex::Rect &bounds) override;
	void draw(tex::Graphics2D &g2, float x, float y) override;

private:
	std::wstring _src;
	tex::sptr<tex::Font> _font;
	float _total_advance = 0.f;
	float _asc = 0.f;
	float _desc = 0.f;
};

// Shared glyph helpers (also used by Graphics2D_Image).
// Horizontal advance (in px at 'pixel_size') of glyph 'ch' in font (uses the
// fallback face when the primary face has no glyph).
float glyph_advance(const Font_ft &font, wchar_t ch, float pixel_size);
// Rasterizes glyph 'ch' with baseline at (bx, by) in surface pixel coordinates.
void draw_char_glyph(const Font_ft &font, wchar_t ch, float pixel_size,
		float bx, float by, std::uint32_t color, Surface &srf);

} // namespace mt