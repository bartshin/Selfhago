//
//  Bilateral.metal
//  Selfhago
//
//  Created by bart Shin on 05/07/2021.
//  Open source: https://github.com/notjosh/NTJBilateralCIFilter

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "Header/ShaderHelper.h"

#define KERNEL_SIZE 7
#define MAX_FACES 10

using namespace metal;

extern "C" {
	
	namespace coreimage {
		
		float gauss(float x, float sigma)
		{
			return GAUSS_MULTIPLIER * exp(-(pow(x, 2.0)) / (2.0 * pow(sigma, 2.0))) / sigma;
		}
		
		float gauss3(float3 x, float sigma)
		{
			return GAUSS_MULTIPLIER * exp(-(dot(x, x)) / (2.0 * pow(sigma, 2.0))) / sigma;
		}
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

