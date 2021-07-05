//
//  FilterKernel.ci.metal
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
#define KERNEL_SIZE 11

extern "C" {
	
	namespace coreimage {
		
		
		float gauss(float GAUSS_MULTIPLIER, float x, float sigma)
		{
			return GAUSS_MULTIPLIER * exp(-(pow(x, 2.0)) / (2.0 * pow(sigma, 2.0))) / sigma;
		}
		
		float gauss3(float GAUSS_MULTIPLIER, float3 x, float sigma)
		{
			return GAUSS_MULTIPLIER * exp(-(dot(x, x)) / (2.0 * pow(sigma, 2.0))) / sigma;
		}
		//https://github.com/notjosh/NTJBilateralCIFilter
		// Not work on iOS
		float4 bilateral(sampler image, float sigma_R, float sigma_S)
		{
			// fyi: 1/sqrt(2*pi) = 0.3989422803
			const float GAUSS_MULTIPLIER = float(0.3989422803);
			const int KernelRadius = (KERNEL_SIZE - 1) / 2;
			
			float convolution[KERNEL_SIZE];
			for (int i = 0; i <= KernelRadius; i++) {
				convolution[KernelRadius + i] =
				convolution[KernelRadius - i] =
				gauss(GAUSS_MULTIPLIER, float(i), sigma_R);
			}
			
			float normalisationFactor = 0.0;
			float3 colour = float3(0.0);
			
			float3 pixel = sample(image, samplerCoord(image)).rgb;
			float spacialWeightBaseReference = 1.0 / gauss(GAUSS_MULTIPLIER, 0.0, sigma_S);
			
			for (int i = -KernelRadius; i <= KernelRadius; i++) {
				for (int j = -KernelRadius; j <= KernelRadius; j++) {
					float2 offsetCoord = samplerCoord(image).xy + float2(i, j);
					float3 offsetPixel = sample(image, offsetCoord).rgb;
					
					float3 dist = offsetPixel - pixel;
					
					float range = convolution[KernelRadius + i] * convolution[KernelRadius + j];
					float spacial = gauss3(GAUSS_MULTIPLIER, dist, sigma_S) * spacialWeightBaseReference;
					
					float weight = range * spacial;
					
					colour += weight * offsetPixel;
					normalisationFactor += weight;
				}
			}
			
			return float4(colour / normalisationFactor, 1.0);
		}

		
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
		
		float getLuminace(float4 s)
		{
			return s.r * 0.2126 + s.g * 0.7152 + s.b * 0.0722;
		}
		
		float4 selectiveBrightness(sample_t s,
								   const float4 red,
								   const float4 green,
								   const float4 blue,
								   const float4 ranges) {
			
			const float luminance = getLuminace(s);
			const float supplementDark = pow(2 - luminance, 3);
			float pfDark = pow(1 - abs(luminance - ranges.x), 3) * supplementDark;
			float pfShadow = pow( 1 - abs(luminance - ranges.y), 3) * supplementDark;
			float pfHighlight = pow(1 - abs(luminance - ranges.z), 3) * supplementDark;
			float pfWhite = pow(1 - abs(luminance - ranges.w), 3) * supplementDark;
			
			float pfRed = pfDark * red.x + pfShadow * red.y + pfHighlight * red.z + pfWhite * red.w;
			float pfGreen = pfDark * green.x + pfShadow * green.y + pfHighlight * green.z + pfWhite * green.w;
			float pfBlue = pfDark * blue.x + pfShadow * blue.y + pfHighlight * blue.z + pfWhite * blue.w;
			
			s.r *= 1 + pfRed/3;
			s.g *= 1 + pfGreen/3;
			s.b *= 1 + pfBlue/3;
			
			
			return s;
		}
		
	}
}

