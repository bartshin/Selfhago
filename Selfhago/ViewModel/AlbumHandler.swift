//
//  AlbumHandler.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/03.
//

import Photos
import UIKit

class AlbumHandler: NSObject, ObservableObject {
	
	static let limitedAlbum = Album(name: "AllowedPhoto", assets: [])
	
	private let imageManager: PHImageManager
	private(set) var albums: [Album]
	var currentAlbum: Album?
	private(set) var thumnailImages: [Album: [PHAsset: UIImage]]
	@Published private(set) var authorizaionStatus: PHAuthorizationStatus
	
	private var lastFetched: PHFetchResult<PHAsset>?

	func getAlbumThumnail(for album: Album) -> UIImage {
		
		guard let firstAsset = album.assets.first,
			  thumnailImages[album] != nil ,
			 let thumnail = thumnailImages[album]![firstAsset] else
		{
			return Album.thumnailImagePlaceholder
		}
		return thumnail
	}
	
	func getThumnailImages(for album: Album) -> [(PHAsset, UIImage)] {
		if thumnailImages[album]?.values != nil {
			var images = [(PHAsset, UIImage)]()
			album.assets.forEach { asset in
				if thumnailImages[album]![asset] != nil{
					images.append((asset, thumnailImages[album]![asset]!))
				}
			}
			return images
		}else {
			return []
		}
	}
	
	func requestImageData(for asset: PHAsset, handler: @escaping (Data) -> Void) {
		let option = PHContentEditingInputRequestOptions()
		option.isNetworkAccessAllowed = false
		asset.requestContentEditingInput(with: option) { input, info in
			guard let url = input?.fullSizeImageURL else {
				assertionFailure("Fail to get image url for \(asset)")
				return
			}
			if let data = try? Data(contentsOf: url) {
				handler(data)
			}else {
				print("Fail to get data from \(asset), \(url)")
			}
		}
	}
	
	private func createAlbums() {
		if authorizaionStatus == .limited {
			createLimitedAlbum()
		}else if authorizaionStatus == .authorized {
			createEntireAlbums()
		}
		publishOnMainThread()
	}
	
	private func createLimitedAlbum() {
		currentAlbum = Self.limitedAlbum
		thumnailImages[currentAlbum!] = [:]
		let fetchOption = PHFetchOptions()
		fetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		let fetched = PHAsset.fetchAssets(with: fetchOption)
		lastFetched = fetched
		currentAlbum!.assets = gatherAsset(in: fetched)
		fetchImages(for: currentAlbum!, assets: currentAlbum!.assets)
	}
	
	private func createEntireAlbums() {
		let allAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
		let fetchOption = PHFetchOptions()
		fetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		allAlbums.enumerateObjects { [weak self] collection, index, stopPointer in
			guard let strongSelf = self else {
				return
			}
			let fetched = PHAsset.fetchAssets(in: collection, options: fetchOption)
			let albumAsset = strongSelf.gatherAsset(in: fetched)
			let newAlbum = Album(name: collection.localizedTitle ?? "No Title", assets: albumAsset)
			strongSelf.albums.append(newAlbum)
			strongSelf.fetchImages(for: newAlbum, assets: albumAsset)
			if strongSelf.currentAlbum == nil {
				strongSelf.currentAlbum = newAlbum
			}
		}
	}
	
	private func gatherAsset(in result: PHFetchResult<PHAsset>) -> [PHAsset] {
		var assets = [PHAsset]()
		result.enumerateObjects { asset, index, stopPointer in
			assets.append(asset)
		}
		
		return assets
	}
	
	private func fetchImages(for album: Album, assets: [PHAsset]) {
		if thumnailImages[album] == nil {
			thumnailImages[album] = [:]
		}
		var fetchedCount = 0
		var ratio: Int = 0
		assets.forEach { asset in
			imageManager.requestImage(for: asset,
									  targetSize: Album.thumnailImageSize,
									  contentMode: .aspectFill,
									  options: nil) {[weak weakSelf = self] image, info in
				fetchedCount += 1
				if image != nil {
					weakSelf?.thumnailImages[album]![asset] = image!
				}
				let newRatio = Int((Float(fetchedCount) / Float(assets.count)) * 10)
				if newRatio%2 == 0, newRatio > ratio {
					ratio = newRatio
					weakSelf?.publishOnMainThread()
				}
			}
		}
	}
	
	private func requestAuthorization() {
		if authorizaionStatus == .notDetermined {
			PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
			}
		}
	}
	
	func openSetting() {
		guard let url = URL(string: UIApplication.openSettingsURLString),
			  UIApplication.shared.canOpenURL(url) else {
			assertionFailure("Not able to open App privacy settings")
			return
		}
		
		UIApplication.shared.open(url, options: [:])
	}
	
	private func publishOnMainThread() {
		if Thread.isMainThread {
			objectWillChange.send()
		}else {
			DispatchQueue.main.async {
				self.objectWillChange.send()
			}
		}
	}
	
	override init() {
		self.albums = []
		authorizaionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
		imageManager = PHImageManager()
		thumnailImages = [:]
		super.init()
		PHPhotoLibrary.shared().register(self)
		requestAuthorization()
		createAlbums()
	}
}

extension AlbumHandler: PHPhotoLibraryChangeObserver {
	
	func photoLibraryDidChange(_ changeInstance: PHChange) {
		let newStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
		if newStatus != self.authorizaionStatus {
			DispatchQueue.main.async {
				self.authorizaionStatus = newStatus
				self.createAlbums()
			}
		}
		if authorizaionStatus == .limited {
			applyChange(changeInstance)
		}
	}
	
	private func applyChange(_ change: PHChange) {
		guard currentAlbum == Self.limitedAlbum,
			lastFetched != nil,
			  let changed = change.changeDetails(for: lastFetched!) else {
			return
		}
		let fetched = changed.fetchResultAfterChanges
		let fetchedAssets = gatherAsset(in: fetched)
		let removedAssets = currentAlbum!.assets.filter {
			!fetchedAssets.contains($0)
		}
		removedAssets.forEach {
			thumnailImages[currentAlbum!]!.removeValue(forKey: $0)
		}
		publishOnMainThread()
		let newAsset = fetchedAssets.filter {
			!currentAlbum!.assets.contains($0)
		}
		fetchImages(for: currentAlbum!, assets: newAsset)
		currentAlbum!.assets = fetchedAssets
		lastFetched = fetched
	}
}
