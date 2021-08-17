//
//  MetalFileData.swift
//  Selfhago
//
//  Created by bart Shin on 29/06/2021.
//

import CoreImage

extension CIFilter {
	
	static var metalLibUrl: URL {
		guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib") else {
			fatalError("Fail to find main metallib url")
		}
		return url
	}
}

extension CIFilter {
	func findKernel(_ kernelName: String) -> CIKernel {
		let url = Self.metalLibUrl
	
		do {
			let data = try Data(contentsOf: url)
			let kernel = try CIKernel(functionName: kernelName, fromMetalLibraryData: data)
			return kernel
		}
		catch {
			assertionFailure("Fail to load kernel \(error.localizedDescription)")
			return CIKernel()
		}
		
	}
}
