//
//  UtilityFilter.h
//  UtilityFilter
//
//  Created by bart Shin on 2021/08/16.
//

#ifndef UtilityFilter_h
#define UtilityFilter_h


extern "C" {
	namespace coreimage {
	float4 makeOpaque(sampler image);
	float4 threshold(sampler image,
					 float criterion) ;
	}
}
#endif /* UtilityFilter_h */
