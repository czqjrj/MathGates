#include "backend.h"

#include <algorithm>
#include <cmath>
#include <vector>

#include "font_ft.h"

namespace mt {

namespace {
constexpr float kPi = 3.14159265358979323846f;
}

Graphics2D_Image::Graphics2D_Image(Surface &srf) : _srf(srf) {}

void Graphics2D_Image::setColor(tex::color c) { _color = c; }
tex::color Graphics2D_Image::getColor() const { return _color; }
void Graphics2D_Image::setStroke(const tex::Stroke &s) { _stroke = s; }
const tex::Stroke &Graphics2D_Image::getStroke() const { return _stroke; }

void Graphics2D_Image::setStrokeWidth(float w) { _stroke.lineWidth = w; }

const tex::Font *Graphics2D_Image::getFont() const { return _font; }
void Graphics2D_Image::setFont(const tex::Font *font) { _font = font; }

void Graphics2D_Image::to_pixel(float x, float y, float &px, float &py) const {
	px = _a * x + _c * y + _e;
	py = _b * x + _d * y + _f;
}

float Graphics2D_Image::pen_px() const {
	const float avg = 0.5f * (sx() + sy());
	float p = _stroke.lineWidth * avg;
	if (p < 0.6f) p = 0.6f;
	return p;
}

void Graphics2D_Image::translate(float dx, float dy) {
	const float e = _a * dx + _c * dy;
	const float f = _b * dx + _d * dy;
	_e += e;
	_f += f;
}

void Graphics2D_Image::scale(float sx, float sy) {
	_a *= sx;
	_b *= sy;
	_c *= sx;
	_d *= sy;
	_e *= sx;
	_f *= sy;
}

void Graphics2D_Image::rotate(float angle) {
	const float c = std::cos(angle);
	const float s = std::sin(angle);
	const float a = _a * c + _b * -s;
	const float b = _a * s + _b * c;
	const float cc = _c * c + _d * -s;
	const float d = _c * s + _d * c;
	const float e = _e * c + _f * -s;
	const float f = _e * s + _f * c;
	_a = a;
	_b = b;
	_c = cc;
	_d = d;
	_e = e;
	_f = f;
}

void Graphics2D_Image::rotate(float angle, float px, float py) {
	translate(px, py);
	rotate(angle);
	translate(-px, -py);
}

void Graphics2D_Image::reset() {
	_a = 1;
	_b = 0;
	_c = 0;
	_d = 1;
	_e = 0;
	_f = 0;
}

float Graphics2D_Image::sx() const { return std::sqrt(_a * _a + _c * _c); }
float Graphics2D_Image::sy() const { return std::sqrt(_b * _b + _d * _d); }

void Graphics2D_Image::fill_loops_px(const std::vector<std::vector<float>> &loops) {
	if (loops.empty()) return;
	float minx = 1e30f, miny = 1e30f, maxx = -1e30f, maxy = -1e30f;
	for (const auto &lp : loops) {
		for (size_t i = 0; i + 1 < lp.size(); i += 2) {
			minx = std::min(minx, lp[i]);
			maxx = std::max(maxx, lp[i]);
			miny = std::min(miny, lp[i + 1]);
			maxy = std::max(maxy, lp[i + 1]);
		}
	}
	int x0 = std::max(0, (int)std::floor(minx));
	int x1 = std::min(_srf.w - 1, (int)std::ceil(maxx));
	int y0 = std::max(0, (int)std::floor(miny));
	int y1 = std::min(_srf.h - 1, (int)std::ceil(maxy));
	if (x0 > x1 || y0 > y1) return;
	// 2x2 supersampling with even-odd rule.
	static const float sdx[4] = {0.25f, 0.75f, 0.25f, 0.75f};
	static const float sdy[4] = {0.25f, 0.25f, 0.75f, 0.75f};
	for (int y = y0; y <= y1; y++) {
		for (int x = x0; x <= x1; x++) {
			int hits = 0;
			for (int s = 0; s < 4; s++) {
				const float px = (float)x + sdx[s];
				const float py = (float)y + sdy[s];
				bool inside = false;
				for (const auto &lp : loops) {
					const size_t n = lp.size() / 2;
					for (size_t i = 0; i < n; i++) {
						const float x0 = lp[i * 2];
						const float y0e = lp[i * 2 + 1];
						const float xi = lp[((i + 1) % n) * 2];
						const float yi = lp[((i + 1) % n) * 2 + 1];
						if ((y0e > py) != (yi > py)) {
							const float xint = x0 + (py - y0e) * (xi - x0) / (yi - y0e);
							if (xint > px) inside = !inside;
						}
					}
				}
				if (inside) hits++;
			}
			if (hits > 0) {
				_srf.blend(x, y, (float)hits / 4.f, _color);
			}
		}
	}
}

void Graphics2D_Image::add_rounded_rect_loop(std::vector<float> &out, float x, float y, float w,
		float h, float rx, float ry) {
	if (rx <= 0.f || ry <= 0.f || w <= 0.f || h <= 0.f) {
		// Plain rectangle, clockwise (any orientation works for even-odd).
		out.push_back(x);
		out.push_back(y);
		out.push_back(x + w);
		out.push_back(y);
		out.push_back(x + w);
		out.push_back(y + h);
		out.push_back(x);
		out.push_back(y + h);
		return;
	}
	rx = std::min(rx, w * 0.5f);
	ry = std::min(ry, h * 0.5f);
	const int seg = 10;
	const float cx_tr = x + w - rx, cy_tr = y + ry;
	const float cx_br = x + w - rx, cy_br = y + h - ry;
	const float cx_bl = x + rx, cy_bl = y + h - ry;
	const float cx_tl = x + rx, cy_tl = y + ry;
	auto arc = [&](float px, float py, float q0, float q1) {
		for (int i = 0; i < seg; i++) {
			const float t = (float)i / (float)seg;
			const float q = q0 + (q1 - q0) * t;
			out.push_back(px + rx * std::cos(q));
			out.push_back(py + ry * std::sin(q));
		}
	};
	out.push_back(x + rx);
	out.push_back(y);
	out.push_back(x + w - rx);
	out.push_back(y);
	arc(cx_tr, cy_tr, -kPi / 2.f, 0.f);
	out.push_back(x + w);
	out.push_back(y + ry);
	out.push_back(x + w);
	out.push_back(y + h - ry);
	arc(cx_br, cy_br, 0.f, kPi / 2.f);
	out.push_back(x + w - rx);
	out.push_back(y + h);
	out.push_back(x + rx);
	out.push_back(y + h);
	arc(cx_bl, cy_bl, kPi / 2.f, kPi);
	out.push_back(x);
	out.push_back(y + h - ry);
	out.push_back(x);
	out.push_back(y + ry);
	arc(cx_tl, cy_tl, kPi, 3.f * kPi / 2.f);
}

void Graphics2D_Image::fillRect(float x, float y, float w, float h) {
	if (w <= 0.f || h <= 0.f) return;
	std::vector<float> loop;
	loop.reserve(8);
	loop.push_back(x);
	loop.push_back(y);
	loop.push_back(x + w);
	loop.push_back(y);
	loop.push_back(x + w);
	loop.push_back(y + h);
	loop.push_back(x);
	loop.push_back(y + h);
	std::vector<std::vector<float>> loops;
	std::vector<float> px;
	px.reserve(loop.size());
	for (size_t i = 0; i < loop.size(); i += 2) {
		float a, b;
		to_pixel(loop[i], loop[i + 1], a, b);
		px.push_back(a);
		px.push_back(b);
	}
	loops.push_back(std::move(px));
	fill_loops_px(loops);
}

void Graphics2D_Image::drawRect(float x, float y, float w, float h) {
	if (w <= 0.f || h <= 0.f) return;
	float tl[2], tr[2], br[2], bl[2];
	to_pixel(x, y, tl[0], tl[1]);
	to_pixel(x + w, y, tr[0], tr[1]);
	to_pixel(x + w, y + h, br[0], br[1]);
	to_pixel(x, y + h, bl[0], bl[1]);
	const float p = pen_px() * 0.5f;
	std::vector<std::vector<float>> loops;
	auto edge_strip = [&](const float(&a)[2], const float(&b)[2], float pen) {
		float dx = b[0] - a[0], dy = b[1] - a[1];
		const float len = std::sqrt(dx * dx + dy * dy);
		if (len < 1e-6f) return;
		dx /= len;
		dy /= len;
		const float nx = -dy, ny = dx;
		std::vector<float> quad;
		quad.push_back(a[0] + nx * pen);
		quad.push_back(a[1] + ny * pen);
		quad.push_back(a[0] - nx * pen);
		quad.push_back(a[1] - ny * pen);
		quad.push_back(b[0] - nx * pen);
		quad.push_back(b[1] - ny * pen);
		quad.push_back(b[0] + nx * pen);
		quad.push_back(b[1] + ny * pen);
		loops.push_back(std::move(quad));
	};
	edge_strip(tl, tr, p);
	edge_strip(tr, br, p);
	edge_strip(br, bl, p);
	edge_strip(bl, tl, p);
	fill_loops_px(loops);
}

void Graphics2D_Image::drawLine(float x1, float y1, float x2, float y2) {
	if (x1 == x2 && y1 == y2) return;
	float a[2], b[2];
	to_pixel(x1, y1, a[0], a[1]);
	to_pixel(x2, y2, b[0], b[1]);
	float dx = b[0] - a[0], dy = b[1] - a[1];
	const float len = std::sqrt(dx * dx + dy * dy);
	if (len < 1e-6f) return;
	dx /= len;
	dy /= len;
	const float nx = -dy, ny = dx;
	const float p = pen_px() * 0.5f;
	std::vector<std::vector<float>> loops(1);
	auto &quad = loops[0];
	quad.push_back(a[0] + nx * p);
	quad.push_back(a[1] + ny * p);
	quad.push_back(a[0] - nx * p);
	quad.push_back(a[1] - ny * p);
	quad.push_back(b[0] - nx * p);
	quad.push_back(b[1] - ny * p);
	quad.push_back(b[0] + nx * p);
	quad.push_back(b[1] + ny * p);
	fill_loops_px(loops);
}

void Graphics2D_Image::fillRoundRect(float x, float y, float w, float h, float rx, float ry) {
	if (w <= 0.f || h <= 0.f) return;
	std::vector<float> local;
	add_rounded_rect_loop(local, x, y, w, h, rx, ry);
	std::vector<float> px;
	px.reserve(local.size());
	for (size_t i = 0; i < local.size(); i += 2) {
		float a, b;
		to_pixel(local[i], local[i + 1], a, b);
		px.push_back(a);
		px.push_back(b);
	}
	std::vector<std::vector<float>> loops;
	loops.push_back(std::move(px));
	fill_loops_px(loops);
}

void Graphics2D_Image::drawRoundRect(float x, float y, float w, float h, float rx, float ry) {
	if (w <= 0.f || h <= 0.f) return;
	const float avg = 0.5f * (sx() + sy());
	const float lp = pen_px() / (avg > 1e-6f ? avg : 1.f);
	std::vector<std::vector<float>> loops;
	std::vector<float> outer, inner;
	add_rounded_rect_loop(outer, x - lp, y - lp, w + 2.f * lp, h + 2.f * lp, rx + lp, ry + lp);
	add_rounded_rect_loop(inner, x + lp, y + lp, w - 2.f * lp, h - 2.f * lp,
			std::max(rx - lp, 0.0001f), std::max(ry - lp, 0.0001f));
	auto to_px = [&](std::vector<float> &src, std::vector<float> &dst) {
		dst.reserve(src.size());
		for (size_t i = 0; i < src.size(); i += 2) {
			float a, b;
			to_pixel(src[i], src[i + 1], a, b);
			dst.push_back(a);
			dst.push_back(b);
		}
	};
	std::vector<float> o, in;
	to_px(outer, o);
	to_px(inner, in);
	loops.push_back(std::move(o));
	loops.push_back(std::move(in));
	fill_loops_px(loops);
}

void Graphics2D_Image::drawChar(wchar_t c, float x, float y) {
	const tex::Font *f = getFont();
	const auto *ff = dynamic_cast<const Font_ft *>(f);
	if (!ff) return;
	float px, py;
	to_pixel(x, y, px, py);
	float gsize = ff->getSize() * sy();
	if (gsize < 1.f) gsize = 1.f;
	draw_char_glyph(*ff, c, gsize, px, py, _color, _srf);
}

void Graphics2D_Image::drawText(const std::wstring &str, float x, float y) {
	const tex::Font *f = getFont();
	const auto *ff = dynamic_cast<const Font_ft *>(f);
	if (!ff) return;
	float px, py;
	to_pixel(x, y, px, py);
	const float syv = sy() > 1e-6f ? sy() : 1.f;
	const float gsize = ff->getSize() * syv;
	float cx = x;
	for (wchar_t ch : str) {
		draw_char_glyph(*ff, ch, gsize, px, py, _color, _srf);
		const float adv = glyph_advance(*ff, ch, gsize) / syv;
		cx += adv;
		to_pixel(cx, y, px, py);
	}
}

} // namespace mt