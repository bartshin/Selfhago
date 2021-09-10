//
//  MetalFileData.swift
//  Selfhago
//
//  Created by bart Shin on 29/06/2021.
//

import CoreImage

extension CIFilter {
	
	fileprivate static func metalLibUrl(for fileName: String) -> URL {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "ci.metallib") else {
			fatalError("Fail to find metallib url for \(fileName)")
		}
		return url
	}
}

extension CIFilter {
	func findKernel(_ functionName: String, in fileName: String? = nil) -> CIKernel {
		let url = Self.metalLibUrl(for: fileName ?? functionName)
	
		do {
			let data = try Data(contentsOf: url)
			let kernel = try CIKernel(functionName: functionName, fromMetalLibraryData: data)
			return kernel
		}
		catch {
			assertionFailure("Fail to load kernel for \(functionName) \(error.localizedDescription)")
			return CIKernel()
		}
		
	}
}
