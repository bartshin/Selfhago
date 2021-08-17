//
//  Kuwahara.h
//  Kuwahara
//
//  Created by bart Shin on 2021/08/16.
//

#ifndef Kuwahara_h
#define Kuwahara_h

extern "C" {
	namespace coreimage {
		float4 colorChannel(sample_t s,
							const float4 red,
							const float4 green,
							const float4 blue,
							const float4 ranges);
		}
}
#endif /* Kuwahara_h */
