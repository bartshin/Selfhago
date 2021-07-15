//
//  Bilateral.ci.metal
//  moody
//
//  Created by bart Shin on 05/07/2021.
//  Open source: https://github.com/notjosh/NTJBilateralCIFilter

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "shader_helper.h"

#define KERNEL_SIZE 7
#define MAX_FACES 10

using namespace metal;

extern "C" {
	
	float kernel_factor(float center_luminance,
					   float surrounding_luminance,
					   float spacialSigma,
					   float luminanceSigma,
					   int2 normalized_position) {
		float luminance_gauss = gauss(center_luminance - surrounding_luminance, luminanceSigma);
		float space_gauss = gauss(normalized_position.x, spacialSigma) * gauss(normalized_position.y, spacialSigma);
		
		return space_gauss * luminance_gauss;
	}
	
	namespace coreimage {
		
		float4 bilateral(sampler image,
						 const float4 face,
						 const float sigma_R,
						 const float sigma_S,
						 const float minimumDistance
						 )
		{
			
			float2 coords = samplerCoord(image);
			
			// MARK: - Using face region
			if (face.x != 0) {
				if (face.x > coords.x || face.y < coords.x ||
					face.z > coords.y || face.w < coords.y) {
					return image.sample(coords);
				}
			}
			const int KernelRadius = (KERNEL_SIZE - 1) / 2;
			
			float convolution[KERNEL_SIZE];
			for (int i = 0; i <= KernelRadius; i++) {
				convolution[KernelRadius + i] =
				convolution[KernelRadius - i] =
				gauss(float(i), sigma_R);
			}
			
			float normalisationFactor = 0.0;
			float3 color = float3(0.0);
			
			float3 pixel = sample(image, coords).rgb;
			float spacialWeightBaseReference = 1.0 / gauss(0.0, sigma_S);
			
			for (int i = -KernelRadius; i <= KernelRadius; i++) {
				for (int j = -KernelRadius; j <= KernelRadius; j++) {
					float2 offsetCoord = samplerCoord(image).xy + float2(float(i) * minimumDistance, float(j) * minimumDistance);
					float3 offsetPixel = sample(image, offsetCoord).rgb;
					
					float3 dist = offsetPixel - pixel;
					
					float range = convolution[KernelRadius + i] * convolution[KernelRadius + j];
					float spacial = gauss3(dist, sigma_S) * spacialWeightBaseReference;
					
					float weight = range * spacial;
					
					color += weight * offsetPixel;
					normalisationFactor += weight;
				}
			}
			return float4(color / normalisationFactor, 1.0);
		}
	}
}

