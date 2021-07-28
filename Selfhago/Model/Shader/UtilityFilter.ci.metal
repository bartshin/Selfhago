//
//  UtilityFilter.ci.metal
//  moody
//
//  Created by bart Shin on 16/07/2021.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "shader_helper.h"
using namespace metal;

extern "C" {
	namespace coreimage {
		float4 makeOpaque(sampler image) {
			float4 source = image.sample(image.coord());
			return float4(source.rgb, 1.0);
		}
		
		float4 threshold(sampler image,
						 float criterion) {
			float4 pixel = image.sample(image.coord());
			float luma = dot(LUMINANCE_VECTOR, pixel.rgb);
			return float4(step(criterion, luma));
		}
	}
}
