//
//  ShaderHelper.h
//  Selfhago
//
//  Created by bart Shin on 05/07/2021.
//

#ifndef ShaderHelper
#define ShaderHelper
constant float3 LUMINANCE_VECTOR(0.2125, 0.7154, 0.0721);
constant half3 LUMINACE_VECTOR_HALF(0.2125, 0.7154, 0.0721);

// fyi: 1/sqrt(2*pi) = 0.3989422803
constant float GAUSS_MULTIPLIER (0.3989422803);
float gauss(float x, float sigma);
float gauss3(float3 x, float sigma);
half3 rgb2hsv(half3 col);
half3 hsv2rgb(half3 col);
#endif /* metalHelper_h */
