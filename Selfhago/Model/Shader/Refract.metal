//
//  Refract.metal
//  Selfhago
//
//  Created by bart Shin on 24/07/2021.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "Header/shader_helper.h"
#include "Header/Refract.h"

#define VIEW_POINT_VECTOR float3(0, 0, 1)

using namespace metal;

extern "C" {
	namespace coreimage {
		
		float calcLumaAtOffset(sampler image,
							   float2 origin,
							   float2 offset)
		{
			float3 pixel = sample(image, samplerTransform(image, origin + offset)).rgb;
			return dot(pixel, LUMINANCE_VECTOR);
		}
		
		float4 refract(sampler image,
					   sampler refractingImage,
					   float refractiveIndex,
					   float lensScale,
					   float lightingAmount,
					   destination dest)
		{
			float2 destCoords = dest.coord();
			
			float northLuma = calcLumaAtOffset(refractingImage, destCoords, float2(0, -1));
			float southLuma = calcLumaAtOffset(refractingImage, destCoords, float2(0, 1));
			float westLuma = calcLumaAtOffset(refractingImage, destCoords, float2(-1, 0));
			float eastLuma = calcLumaAtOffset(refractingImage, destCoords, float2(1, 0));
			
			float3 lensNormal = normalize(float3((eastLuma - westLuma), (southLuma - northLuma), 1.0));
			float3 refractVector = metal::refract(float3(0, 0, 1),
												  lensNormal,
												  refractiveIndex) * lensScale;
			float3 outputPixel = sample(image, samplerTransform(image, destCoords + refractVector.xy)).rgb;
			
			// Order of luma direction determine lighting direction
			outputPixel += (northLuma - southLuma) * lightingAmount;
			outputPixel += (eastLuma - westLuma) * lightingAmount;
			
			return float4(outputPixel, 1.0);
		}
	}
}
