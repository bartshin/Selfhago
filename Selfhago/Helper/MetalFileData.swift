//
//  MetalFileData.swift
//  moody
//
//  Created by bart Shin on 29/06/2021.
//

import CoreImage

extension CIFilter {
	
	static func getMetalLibData(from fileName: String) -> Data {
		if let url = getMetalLibUrl(for: fileName),
			let data = try? Data(contentsOf: url) {
			return data
		}else {
			assertionFailure("Fail to read data from metal lib")
			return Data()
		}
	}
	static func getMetalLibUrl(for fileName: String) -> URL? {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "ci.metallib") else {
			fatalError("Fail to find url for \(fileName)")
		}
		return url
	}
}

extension CIFilter {
	func findKernel(by kernelName: String, from fileName: String) -> CIKernel {
		let data = CIFilter.getMetalLibData(from: fileName)
		if let kernel = try? CIKernel(functionName: kernelName, fromMetalLibraryData: data) {
			return kernel
		}else {
			assertionFailure("Fail to find \(kernelName)")
			return CIKernel()
		}
	}
	
}
