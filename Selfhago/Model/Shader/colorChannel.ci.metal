//
//  ColorChannel.metal
//  Selfhago
//
//  Created by bart Shin on 29/06/2021.
//

#include <CoreImage/CoreImage.h>
#include "Header/ShaderHelper.h"

using namespace metal;

extern "C" {
	
	namespace coreimage {
		
		float4 colorChannel(sample_t s,
							const float4 red,
							const float4 green,
							const float4 blue,
							const float4 ranges)
		{
			
			const float luminance = dot(s.rgb, LUMINANCE_VECTOR);
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

