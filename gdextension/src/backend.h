#pragma once

#include <cstdint>

#include "graphic/graphic.h"
#include "surface.h"

namespace mt {

// Software rasterizer backend: draws TeX content into a Surface (RGBA8,
// y-down) using FreeType glyphs and a small even-odd polygon fill.
class Graphics2D_Image : public tex::Graphics2D {
public:
	explicit Graphics2D_Image(Surface &srf);

	void setColor(tex::color c) override;
	tex::color getColor() const override;
	void setStroke(const tex::Stroke &s) override;
	const tex::Stroke &getStroke() const override;
	void setStrokeWidth(float w) override;
	const tex::Font *getFont() const override;
	void setFont(const tex::Font *font) override;

	void translate(float dx, float dy) override;
	void scale(float sx, float sy) override;
	void rotate(float angle) override;
	void rotate(float angle, float px, float py) override;
	void reset() override;
	float sx() const override;
	float sy() const override;

	void drawChar(wchar_t c, float x, float y) override;
	void drawText(const std::wstring &str, float x, float y) override;
	void drawLine(float x1, float y1, float x2, float y2) override;
	void drawRect(float x, float y, float w, float h) override;
	void fillRect(float x, float y, float w, float h) override;
	void drawRoundRect(float x, float y, float w, float h, float rx, float ry) override;
	void fillRoundRect(float x, float y, float w, float h, float rx, float ry) override;

private:
	void to_pixel(float x, float y, float &px, float &py) const;
	float pen_px() const;
	// Fills one or more closed loops (each an array of x,y pairs). Uses the
	// even-odd rule so that nested loops act as holes.
	void fill_loops_px(const std::vector<std::vector<float>> &loops);
	// Builds a rounded-rectangle perimeter loop (x,y pairs) in local coords.
	static void add_rounded_rect_loop(std::vector<float> &out, float x, float y, float w, float h,
			float rx, float ry);

	Surface &_srf;
	tex::color _color = tex::black;
	tex::Stroke _stroke;
	const tex::Font *_font = nullptr;
	// Row-vector transform: [x' y' 1] = [x y 1] * [[a b 0][c d 0][e f 1]]
	float _a = 1, _b = 0, _c = 0, _d = 1, _e = 0, _f = 0;
};

} // namespace mt