//
//  MakeOpaque.ci.metal
//  moody
//
//  Created by bart Shin on 16/07/2021.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

extern "C" {
	namespace coreimage {
		float4 makeOpaque(sampler image) {
			float4 source = image.sample(image.coord());
			return float4(source.xyz, 1.0);
		}
	}
}
