//
//  Album.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/04.
//

import UIKit
import PhotosUI

class Album {
	
	static let thumnailImageSize = CGSize(width: 180, height: 180)
	let name: String
	let photoCount: Int
	var assets: [PHAsset]
	
	init(name: String, assets: [PHAsset]) {
		self.name = name
		self.photoCount = assets.count
		self.assets = assets
	}
	
	static let thumnailImagePlaceholder = UIImage()
}

extension Album: Hashable {
	static func == (lhs: Album, rhs: Album) -> Bool {
		lhs.name == rhs.name
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
	
}
