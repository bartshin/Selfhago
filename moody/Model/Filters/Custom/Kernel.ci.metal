//
//  Kernel.ci.metal
//  moody
//
//  Created by bart Shin on 29/06/2021.
//

#include <CoreImage/CoreImage.h>
using namespace metal;
#define minHue 0
#define maxHue 6
#define minSat 0
#define maxSat 1
#define minVal 0
#define maxVal 1

// Luma range
#define blackRange 0.05
#define darKRange 0.1
#define darkShadowRange 0.16
#define shadowRange 0.23
#define brigtShadowRange 0.31
#define midtoneRange 0.40
#define brightMidtoneRange 0.5
#define highlightRange 0.6
#define whiteRange 0.7

extern "C" {
	
	namespace coreimage {
		
		float4 rgbToHsv(float4 rgb)
		{
			float4 hsv;
			float maxV = max(rgb.r, max(rgb.g, rgb.b));
			float c = maxV - min(rgb.r, min(rgb.g, rgb.b));
			float d = step(0.0, -c);
			
			hsv.z = maxV;
			hsv.y = c / (maxV + d);
			float4 delta = (maxV - rgb) / (c + d);
			delta -= delta.brga;
			delta += float4(2.0, 4.0, 6.0, 0.0);
			delta *= step(maxV, rgb.gbra);
			hsv.x = fract(max(delta.r, max(delta.g, delta.b)) / maxHue) * maxHue;
			return hsv;
		}
		
		
		float4 hsvToRgb(float4 hsv)
		{
			float4 hue;
			hue.x = abs(hsv.x - 3.0) - 1.0;
			hue.y = 2.0 - abs(hsv.x - 2.0);
			hue.z = 2.0 - abs(hsv.x - 4.0);
			return ((clamp(hue, minSat, maxVal) - 1.0) * hsv.y + 1.0) * hsv.z;
		}
		
		float getLuma(float4 s)
		{
			return s.r * 0.2126 + s.g * 0.7152 + s.b * 0.0722;
		}
		
		float4 selectiveBrightness(sample_t s, float4 red, float4 green, float4 blue) {
			
			float luma = getLuma(s);
			if (luma < blackRange) {
				s.r *= (red.x * 1.1);
				s.g *= (green.x * 1.1);
				s.b *= (blue.x * 1.1);
			}else if (luma < darKRange) {
				s.r *= red.x;
				s.g *= green.x;
				s.b *= blue.x;
			}else if (luma < darkShadowRange) {
				s.r *= red.x*0.66 + red.y*0.33;
				s.g *= green.x*0.66 + green.y*0.33;
				s.b *= blue.x*0.66 + blue.y*0.33;
			}else if (luma < shadowRange) {
				s.r *= red.x*0.33 + red.y*0.66;
				s.g *= green.x*0.33 + green.y*0.66;
				s.b *= blue.x*0.33 + blue.y*0.66;
			}else if (luma < brigtShadowRange) {
				s.r *= red.y;
				s.g *= green.y;
				s.b *= blue.y;
			}else if (luma < midtoneRange) {
				s.r *= red.y*0.66 + red.z*0.33;
				s.g *= green.y*0.66 + green.z*0.33;
				s.b *= blue.y*0.66 + blue.z*0.33;
			}else if (luma < brightMidtoneRange) {
				s.r *= red.y*0.33 + red.z*0.66;
				s.g *= green.y*0.33 + green.z*0.66;
				s.b *= blue.y*0.33 + blue.z*0.66;
			}else if (luma < highlightRange) {
				s.r *= red.z;
				s.g *= green.z;
				s.b *= blue.z;
			}else if (luma < whiteRange) {
				s.r *= (red.z + red.w)/2;
				s.g *= (green.z + green.w)/2;
				s.b *= (blue.z + blue.w)/2;
			}else {
				s.r *= red.w;
				s.g *= green.w;
				s.b *= blue.w;
			}
			
			return s;
		}
	}
}

