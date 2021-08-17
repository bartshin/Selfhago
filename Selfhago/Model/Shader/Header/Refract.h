//
//  Refract.h
//  Refract
//
//  Created by bart Shin on 2021/08/16.
//

#ifndef Refract_h
#define Refract_h


extern "C" {
	namespace coreimage {
	float4 refract(sampler image,
				   sampler refractingImage,
				   float refractiveIndex,
				   float lensScale,
				   float lightingAmount,
				   destination dest);
	}
}
#endif /* Refract_h */
