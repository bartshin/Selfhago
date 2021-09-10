//
//  LabAdjustment.h
//  LabAdjustment
//
//  Created by bart Shin on 2021/09/03.
//

#ifndef LabAdjustment_h
#define LabAdjustment_h

extern "C" {
	namespace coreimage {
	kernel void LabAdjustment(texture2d<float, access::read> source,
							  texture2d<float, access::write> destination,
							  constant float* lValues,
							  constant float& aValue,
							  constant float& bValue,
							  constant float& numberOfColors,
							  constant float4* pickedColors ,
							  uint2 position);
	}
}

#endif /* LabAdjustment_h */
