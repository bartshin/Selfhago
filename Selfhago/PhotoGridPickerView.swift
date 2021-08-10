//
//  PhotoGridPickerView.swift
//  iOS
//
//  Created by bart Shin on 2021/08/03.
//

import SwiftUI
import PhotosUI

struct PhotoGridPickerView: View {
	
	@EnvironmentObject var imageEditor: ImageEditor
	private let tapImage: (PHAsset) -> Void
	private let tapCamera: () -> Void
	private let images: [(PHAsset, UIImage)]
		
    var body: some View {
		Group {
			GeometryReader { geometry in
				ScrollView {
					LazyVGrid(columns: createColumns(in: geometry.size),
							  alignment: .center,
							  spacing: Constant.imageMargin ,
							  pinnedViews: []) {
						cameraButton
							.frame(width: geometry.size.width * Constant.imageSize,
								   height: geometry.size.width * Constant.imageSize)
						ForEach(0..<images.count, id: \.self) { index in
							drawImage(at: index, in: geometry.size)
						}
					}
				}
			}
			.ignoresSafeArea()
		}
	}
	
	// MARK: - User Intents
	private func tapAsset(_ asset: PHAsset) {
		if asset.mediaType == .image {
			tapImage(asset)
		}
	}
	
	private func drawImage(at index: Int, in size: CGSize) -> some View {
		Image(uiImage: images[index].1)
			.resizable()
			.aspectRatio(contentMode: .fill)
			.frame(width: size.width * Constant.imageSize,
				   height: size.width * Constant.imageSize)
			.clipped()
			.contentShape(Rectangle())
			.onTapGesture {
				tapAsset(images[index].0)
			}
	}
	
	private var cameraButton: some View {
		Button(action: tapCamera) {
			Constant.cameraButtonBackgroundColor
				.overlay (
					Image("camera")
						.resizable()
						.renderingMode(.template)
						.frame(width: Constant.cameraButtonSize.width,
							   height: Constant.cameraButtonSize.height)
						.foregroundColor(Constant.cameraButtonColor)
				)
		}
	}
	
	private func createColumns(in size: CGSize) -> [GridItem] {
		[GridItem(.adaptive(minimum: (size.width - Constant.imageMargin * Constant.numberOfColums) * Constant.imageSize,
							maximum: size.width / Constant.imageSize),
					 spacing: Constant.imageMargin,
					 alignment: .center)]
	}
	
	private struct Constant {
		static let imageSize: CGFloat = 1 / numberOfColums
		static let numberOfColums: CGFloat = 3
		static let imageMargin: CGFloat = 2
		static let cameraButtonColor: Color = .white
		static let cameraButtonBackgroundColor: Color = Color(.darkGray)
		static let cameraButtonSize = CGSize(width: 54, height: 54)
	}
	
	init(images: [(PHAsset, UIImage)],
		 tapImage: @escaping (PHAsset) -> Void,
		 tapCamera: @escaping () -> Void) {
		self.images = images
		self.tapImage = tapImage
		self.tapCamera = tapCamera
	}
}
