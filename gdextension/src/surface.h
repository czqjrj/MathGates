#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace mt {

// Simple RGBA8 pixel surface (y-down, row-major, w*h*4 bytes).
class Surface {
public:
	int w;
	int h;
	std::vector<uint8_t> px;

	Surface() : w(0), h(0) {}
	Surface(int pw, int ph);

	void clear();
	// Over-composite a colored pixel with coverage coeff in 0..1 at integer
	// pixel (x, y). c = AARRGGBB.
	void blend(int x, int y, float coeff, std::uint32_t c);
	inline std::uint8_t *row(int y) { return px.data() + (size_t)y * (size_t)w * 4; }
};

// Converts a UTF-8 string to a UTF-16 (wchar_t) string.
std::wstring utf8_to_w(const std::string &s);

} // namespace mt