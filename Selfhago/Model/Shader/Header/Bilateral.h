//
//  Bilateral.h
//  Bilateral
//
//  Created by bart Shin on 2021/08/16.
//

#ifndef Bilateral_h
#define Bilateral_h


extern "C" {
	namespace coreimage {
	float4 bilateral(sampler image,
					 const float4 face,
					 const float sigma_R,
					 const float sigma_S,
					 const float minimumDistance
					 );
	}
}
#endif /* Bilateral_h */
