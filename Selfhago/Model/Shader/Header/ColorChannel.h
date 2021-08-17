//
//  ColorChannel.h
//  ColorChannel
//
//  Created by bart Shin on 2021/08/16.
//

#ifndef ColorChannel_h
#define ColorChannel_h

extern "C" {
	namespace coreimage {
		float4 colorChannel(sample_t s,
							const float4 red,
							const float4 green,
							const float4 blue,
							const float4 ranges);
	}
}
#endif /* ColorChannel_h */
