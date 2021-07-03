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
#define darkRange 0.1
#define shadowRange 0.4
#define highlightRange 0.7
#define whiteRange 1.0

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
		
		float4 selectiveBrightness(sample_t s,
								   float4 red,
								   float4 green,
								   float4 blue,
								   float4 ranges) {
			
			float luma = getLuma(s);
			
			float pfDark = pow(1 - abs(luma - ranges.x), 3);
			float pfShadow = pow( 1 - abs(luma - ranges.y), 3);
			float pfHighlight = pow(1 - abs(luma - ranges.z), 3);
			float pfWhite = pow(1 - abs(luma - ranges.w), 3) ;
			
			float pfRed = pfDark * red.x + pfShadow * red.y + pfHighlight * red.z + pfWhite * red.w;
			float pfGreen = pfDark * green.x + pfShadow * green.y + pfHighlight * green.z + pfWhite * green.w;
			float pfBlue = pfDark * blue.x + pfShadow * blue.y + pfHighlight * blue.z + pfWhite * blue.w;
			
			s.r *= (3 + pfRed) / 3;
			s.g *= (3 + pfGreen) / 3;
			s.b *= (3 + pfBlue) / 3;
			
			
			return s;
		}
		
	}
}

