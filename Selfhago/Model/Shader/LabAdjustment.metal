//
//  LabAdjustment.metal
//  LabAdjustment
//
//  Created by bart Shin on 2021/09/02.
//

#include <metal_stdlib>
#include "Header/ColorConversion.h"
#include "Header/LabAdjustment.h"


using namespace metal;

extern "C" {
	
	namespace coreimage {
		
		constant bool deviceSupportsNonuniformThreadgroups [[ function_constant(0) ]];
		
		kernel void LabAdjustment(texture2d<float, access::read> source [[ texture(0) ]],
								  texture2d<float, access::write> destination [[ texture(1) ]],
								  constant float* lValues [[ buffer(0) ]], // Array of 256 elements for mapping
								  constant float& aValue [[ buffer(1) ]],
								  constant float& bValue [[ buffer(2) ]],
								  constant float& numberOfColors [[ buffer(3) ]],
								  constant float4* pickedColors [[ buffer(4) ]],
								  uint2 position [[thread_position_in_grid]]
								  ) {
			const auto textureSize = ushort2(destination.get_width(),
											 destination.get_height());
			if (deviceSupportsNonuniformThreadgroups) {
				if (position.x >= textureSize.x || position.y >= textureSize.y) {
					return;
				}
			}
			
			const auto sourceValue = source.read(position);
			auto labValue = rgb2lab(sourceValue.rgb);
			labValue = denormalizeLab(labValue);
			bool modifyPixel = false;
			if (numberOfColors == 0) {
				modifyPixel = true;
			}else {
				for (int i=0; !modifyPixel && i<numberOfColors; i++) {
					float3 color = pickedColors[i].rgb;
					modifyPixel = abs(color.g - labValue.g) < 10 && abs(color.b - labValue.b) < 10;
				}
			}
			if (modifyPixel) {
				labValue.g += aValue * 10.0f;
				labValue.b += bValue * 10.0f;
			}
			labValue = clipLab(labValue);
			labValue = normalizeLab(labValue);
			int lumaIndex = int(labValue.r * 254);
			labValue.r = lValues[lumaIndex];
			const auto resultValue = float4(lab2rgb(labValue), sourceValue.a);
			
			destination.write(resultValue, position);
		}
	}
}
