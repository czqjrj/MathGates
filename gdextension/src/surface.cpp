#include "surface.h"

namespace mt {

Surface::Surface(int pw, int ph) : w(pw), h(ph), px((size_t)pw * (size_t)ph * 4, 0) {}

void Surface::clear() {
	std::fill(px.begin(), px.end(), 0);
}

void Surface::blend(int x, int y, float coeff, std::uint32_t c) {
	if (x < 0 || y < 0 || x >= w || y >= h || coeff <= 0.f) return;
	uint8_t *d = row(y) + (size_t)x * 4;
	const float sa = coeff * (float)((c >> 24) & 0xff) / 255.f;
	if (sa <= 0.f) return;
	const float sr = (float)((c >> 16) & 0xff) / 255.f;
	const float sg = (float)((c >> 8) & 0xff) / 255.f;
	const float sb = (float)(c & 0xff) / 255.f;
	const float da = (float)d[3] / 255.f;
	const float out_a = sa + da * (1.f - sa);
	float dr = (float)d[0] / 255.f;
	float dg = (float)d[1] / 255.f;
	float db = (float)d[2] / 255.f;
	if (out_a > 0.0001f) {
		dr = (sr * sa + dr * da * (1.f - sa)) / out_a;
		dg = (sg * sa + dg * da * (1.f - sa)) / out_a;
		db = (sb * sa + db * da * (1.f - sa)) / out_a;
	}
	d[0] = (uint8_t)(dr * 255.f + 0.5f);
	d[1] = (uint8_t)(dg * 255.f + 0.5f);
	d[2] = (uint8_t)(db * 255.f + 0.5f);
	d[3] = (uint8_t)(out_a * 255.f + 0.5f);
}

std::wstring utf8_to_w(const std::string &s) {
	std::wstring out;
	out.reserve(s.size());
	size_t i = 0;
	while (i < s.size()) {
		unsigned char c = (unsigned char)s[i];
		uint32_t cp = 0;
		int extra = 0;
		if (c < 0x80) { cp = c; }
		else if ((c >> 5) == 0x6) { cp = c & 0x1f; extra = 1; }
		else if ((c >> 4) == 0xe) { cp = c & 0x0f; extra = 2; }
		else if ((c >> 3) == 0x1e) { cp = c & 0x07; extra = 3; }
		else { i++; continue; }
		if (i + extra >= s.size()) break;
		bool bad = false;
		for (int k = 1; k <= extra; k++) {
			unsigned char cc = (unsigned char)s[i + k];
			if ((cc >> 6) != 0x2) { bad = true; break; }
			cp = (cp << 6) | (cc & 0x3f);
		}
		if (bad) { i++; continue; }
		i += extra + 1;
		if (cp < 0x10000) {
			out.push_back((wchar_t)cp);
		} else {
			cp -= 0x10000;
			out.push_back((wchar_t)(0xd800 + (cp >> 10)));
			out.push_back((wchar_t)(0xdc00 + (cp & 0x3ff)));
		}
	}
	return out;
}

} // namespace mt