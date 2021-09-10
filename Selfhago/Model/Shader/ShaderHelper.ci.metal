//
//  shader_helper.metal
//  Selfhago
//
//  Created by bart Shin on 05/07/2021.
//

#include <metal_stdlib>
#include "Header/ShaderHelper.h"
using namespace metal;


float gauss(float x, float sigma)
{
	return GAUSS_MULTIPLIER * exp(-(pow(x, 2.0)) / (2.0 * pow(sigma, 2.0))) / sigma;
}

float gauss3(float3 x, float sigma)
{
	return GAUSS_MULTIPLIER * exp(-(dot(x, x)) / (2.0 * pow(sigma, 2.0))) / sigma;
}

half3 rgb2hsv(half3 col) {
	half r = col.r;
	half g = col.g;
	half b = col.b;
	
	half max_value = r > g ? r : g;
	max_value = max_value > b ? max_value : b;
	half min_value = r < g ? r : g;
	min_value = min_value < b ? min_value : b;
	
	half h = max_value - min_value;
	half s = max_value - min_value;
	half v = max_value;
	
	if (h > 0.0h) {
		if (max_value == r) {
			h = (g - b) / h;
			if (h < 0.0h) {
				h += 6.0;
			}
		} else if (max_value == g) {
			h = 2.0 * (b - r) / h;
		} else {
			h = 4.0f + (r - g) / h;
		}
	}
	
	h /= 6.0h;
	if (max_value != 0.0h)
		s /= max_value;
	
	return half3(h, s, v);
}

half3 hsv2rgb(half3 col) {
	half h = col.x;
	half s = col.y;
	half v = col.z;
	
	half r = v;
	half g = v;
	half b = v;
	if (s == 0) { return half3(r, g, b); }
	
	h *= 6.0h;
	int i = int(h);
	half f = h - half(i);
	
	switch (i) {
		case 0:
			g *= 1 - s * (1 - f);
			b *= 1 - s;
			break;
		case 1:
			r *= 1 - s * f;
			b *= 1 - s;
			break;
		case 2:
			r *= 1 - s;
			b *= 1 - s * (1 - f);
			break;
		case 3:
			r *= 1 - s;
			g *= 1 - s * f;
			break;
		case 4:
			r *= 1 - s * (1 - f);
			g *= 1 - s;
			break;
		case 5:
			g *= 1 - s;
			b *= 1 - s * f;
			break;
	}
	
	return half3(r, g, b);
}
