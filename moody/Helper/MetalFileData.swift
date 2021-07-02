//
//  MetalFileData.swift
//  moody
//
//  Created by bart Shin on 29/06/2021.
//

import CoreImage

extension CIFilter {
	
	static var metalLibData: Data {
		guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib") else {
			assertionFailure("Fail to find metal library url")
			return Data()
		}
		if let data = try? Data(contentsOf: url) {
			return data
		}else {
			assertionFailure("Fail to read data from metal lib")
			return Data()
		}
	}
	
}
