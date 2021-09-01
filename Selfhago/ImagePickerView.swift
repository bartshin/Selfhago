//
//  ImagePickerView.swift
//  iOS
//
//  Created by bart Shin on 2021/08/03.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
	
	@Environment(\.colorScheme) var colorScheme
	@Binding var navigationTag: String?
	@State private var isShowingAlbum = false
	@State private var isShowingLimitedPicker = false
	@EnvironmentObject var albumHandler: AlbumHandler
	
	let imageEditor = ImageEditor()
	private var recorder: CameraRecorder {
		let recorder = CameraRecorder()
		recorder.videoOutputDelegate = imageEditor
		return recorder
	}
	
	private var currentAlbum: Album? {
		albumHandler.currentAlbum
	}
	
	private var albumNames: [String] {
		albumHandler.albums.compactMap {
			$0.name
		}
	}
	
	private var currentAlbumThumnails: [(PHAsset, UIImage)] {
		if currentAlbum != nil {
			return albumHandler.getThumnailImages(for: currentAlbum!)
		}else {
			return []
		}
	}
	
    var body: some View {
		
		GeometryReader { geometry in
			VStack(spacing: 0) {
				topbar
					.frame(width: geometry.size.width,
						   height: topbarHeight)
					.background(Constant.backgroundColor
									.frame(height: topbarHeight * 2))
					.offset(y: topbarHeight * 0.5)
					.padding(.bottom, topbarHeight * 0.4)
					.ignoresSafeArea(.container, edges: .top)
					.zIndex(1)
				ZStack {
					PhotoGridPickerView(images: currentAlbumThumnails,
										tapImage: tapImage(_:),
										tapCamera: tapCamera)
						.environmentObject(imageEditor)
					blurView
					drawAlbumList(in: geometry.size)
					if isShowingLimitedPicker {
						limtedImagePicker
					}
				}
				.zIndex(0)
			}
			.onAppear {
				imageEditor.editingState.isRecording = false
				DesignConstant.setColorScheme(to: colorScheme == .dark ? .dark: .light)
			}
			HStack {
				linkToEditView
				linkToCameraView
			}
		}
		.ignoresSafeArea(.container, edges: .horizontal)
    }
	
	// MARK: - User intents
	private func tapImage(_ asset: PHAsset) {
		DispatchQueue.global(qos: .userInteractive).async { [self] in
			albumHandler.requestImageData(for: asset) { data in
				imageEditor.setNewImage(from: data)
			}
		}
		
		navigationTag = String(describing: EditView.self)
	}
	private func tapCamera() {
		navigationTag = String(describing: CameraView.self)
	}
	private var linkToEditView: some View {
		NavigationLink(destination: EditView(navigationTag: $navigationTag)
						.environmentObject(imageEditor),
					   isActive: Binding<Bool>{
						navigationTag == String(describing: EditView.self)
					   } set: { _ in })
			{ EmptyView()}
	}
	
	private var linkToCameraView: some View {
		NavigationLink(destination: CameraView(recorder: recorder,
											   navigationTag: $navigationTag)
						.environmentObject(imageEditor),
					   isActive: Binding<Bool>{
						navigationTag == String(describing: CameraView.self)
					   } set: { _ in })
			{ EmptyView()}
	}
	
	private var blurView: some View {
		Color.black.opacity(isShowingAlbum ? 0.5: 0)
			.offset(y: topbarHeight)
			.onTapGesture {
				withAnimation {
					isShowingAlbum = false
				}
			}
	}
	
	private func drawAlbumList(in size: CGSize) -> some View {
		ScrollView {
			VStack (spacing: Constant.albumListVMargin) {
				ForEach(albumHandler.albums, id: \.self.name) { album in
					drawAlbumRow(for: album)
					Divider()
						.background(Color.black)
				}
				.padding(.horizontal, Constant.albumListHMargin)
			}
		}
		.background(Color(UIColor.systemBackground))
		.allowsHitTesting(isShowingAlbum)
		.offset(y: isShowingAlbum ? -topbarHeight: -size.height)
		.frame(height: size.height * 0.8)
	}
	
	private func drawAlbumRow(for album: Album) -> some View {
		HStack (spacing: 15){
			Image(uiImage: albumHandler.getAlbumThumnail(for: album))
				.resizable()
				.frame(width: Constant.albumThumnailSize.width,
					   height: Constant.albumThumnailSize.height)
			VStack (alignment: .leading) {
				Text(album.name)
					.font(Constant.albumRowTitleFont)
				Text(String(album.photoCount))
					.font(Constant.albumRowSubTitleFont)
					.foregroundColor(Constant.albumRowSubTitleColor)
			}
			Spacer()
		}
		.contentShape(Rectangle())
		.onTapGesture {
			withAnimation {
				isShowingAlbum = false
				albumHandler.currentAlbum = album
			}
		}
	}
	
	private var topbar: some View {
		Group {
			if albumHandler.authorizaionStatus == .authorized{
				albumToggleBar
			}
			else if albumHandler.authorizaionStatus == .limited {
				addPhotoBar
			}
			else if albumHandler.authorizaionStatus == .restricted {
				
			}
			else {
				openSettingBar
			}
		}
		.padding(.top, topbarHeight)
	}
	
	private var topbarHeight: CGFloat {
		(UIApplication.shared.windows.first?.safeAreaInsets.top ?? 50)
	}
	
	private var albumToggleBar: some View {
		HStack (spacing: 9) {
			Text(currentAlbum?.name ?? "")
			Image(systemName: isShowingAlbum ? "chevron.up": "chevron.down")
		}
		.font(Constant.topbarFont)
		.onTapGesture {
			withAnimation (.easeInOut(duration: 0.5)){
				isShowingAlbum.toggle()
			}
		}
	}
	
	private var addPhotoBar: some View {
		HStack {
			Button {
				isShowingLimitedPicker = true
			} label: {
				Text("Edit")
			}
			Spacer()
			Button {
				albumHandler.openSetting()
			} label: {
				Text("Allow all access")
			}
		}
		.font(Constant.topbarFont)
		.padding(.horizontal)
	}
	
	private var openSettingBar: some View {
		HStack {
			Text("Permission for album is not allowed")
			Spacer()
			Button {
				albumHandler.openSetting()
			} label: {
				Text("Open setting")
			}
		}
		.font(Constant.topbarFont)
		.padding(.horizontal)
	}
	
	private var limtedImagePicker: LimitedImagePicker {
		LimitedImagePicker(isPresenting: $isShowingLimitedPicker)
	}
	
	private struct Constant {
		static let albumThumnailSize = CGSize(width: 60, height: 60)
		static let topbarFont: Font = DesignConstant.getFont(.init(family: .NotoSansCJKkr, style: .Bold), size: 17)
		static let albumListHMargin: CGFloat = 16
		static let albumListVMargin: CGFloat = 12
		static let albumListRowHeight: CGFloat = 84
		static let albumRowTitleFont: Font = DesignConstant.getFont(.init(family: .NotoSansCJKkr, style: .Regular), size: 17)
		static let albumRowSubTitleFont: Font = DesignConstant.getFont(.init(family: .NotoSansCJKkr, style: .Regular), size: 14)
		static let topbarBottmMargin: CGFloat = 14
		static let albumRowSubTitleColor: Color = .gray
		static var backgroundColor: Color {
			DesignConstant.getColor(for: .background)
		}
	}
}

#if DEBUG
struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
		ImagePickerView(navigationTag: .constant(nil))
			.environmentObject(AlbumHandler())
    }
}
#endif
