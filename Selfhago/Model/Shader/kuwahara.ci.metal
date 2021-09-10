//
//  Kuwahara.ci.metal
//  Selfhago
//
//  Created by bart Shin on 22/07/2021.
//
#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include "Header/ShaderHelper.h"

using namespace metal;

extern "C" {
	namespace coreimage {
		float4 kuwahara(sampler image,
						float radius,
						destination dest)
		{
			float2 coords = dest.coord();
			int r = int(radius);
			
			float numberOfPixels = float(r + 1) * float(r + 1);
			float3 meanOfQuardants[4];
			float3 stdDeviations[4];
			
			for (int i=0; i < 4; i++)
			{
				meanOfQuardants[i] = float3(0);
				stdDeviations[i] = float3(0);
			}
			
			for (int x = -r; x <= r; x++)
			{
				for (int y = -r; y <= r; y++) {
					float3 color = sample(image, samplerTransform(image, coords + float2( x, y))).rgb;
					
					float3 colorA = float3(float( x <= 0 && y <= 0)) * color;
					meanOfQuardants[0] += colorA;
					stdDeviations[0] += colorA;
					
					float3 colorB = float3(float( x >= 0 && y <= 0)) * color;
					meanOfQuardants[1] += colorB;
					stdDeviations[1] += colorB;
					
					float3 colorC = float3(float( x >= 0 && y >= 0)) * color;
					meanOfQuardants[2] += colorC;
					stdDeviations[2] += colorC;
					
					float3 colorD = float3(float( x <= 0 && y <= 0)) * color;
					meanOfQuardants[3] += colorD;
					stdDeviations[3] += colorD;
					
				}
			}
			
			float minOfSigmaSqure = 1e+2;
			float3 colorToReturn = float3(0);
			
			for (int i = 0; i < 4; i++)
			{
				meanOfQuardants[i] /= numberOfPixels;
				stdDeviations[i] = abs(stdDeviations[i] / numberOfPixels - meanOfQuardants[i] * meanOfQuardants[i]);
				
				float sigmaSqure = stdDeviations[i].r + stdDeviations[i].g + stdDeviations[i].b;
				
				if (sigmaSqure < minOfSigmaSqure) {
					colorToReturn = meanOfQuardants[i];
					minOfSigmaSqure = sigmaSqure;
				}
			}
			
			return float4(colorToReturn, 1);
		}
	}
}
