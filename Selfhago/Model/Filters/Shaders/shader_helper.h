//
//  shader_helper.h
//  moody
//
//  Created by bart Shin on 05/07/2021.
//

#ifndef shader_helper
#define shader_helper
constant float3 luminanceVector(0.2125, 0.7154, 0.0721);
constant half3 luminanceVectorHalf(0.2125, 0.7154, 0.0721);

// fyi: 1/sqrt(2*pi) = 0.3989422803
constant float GAUSS_MULTIPLIER (0.3989422803);
float gauss(float x, float sigma);
float gauss3(float3 x, float sigma);
half3 rgb2hsv(half3 col);
half3 hsv2rgb(half3 col);
#endif /* metal_helper_h */
