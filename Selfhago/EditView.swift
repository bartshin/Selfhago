//
//  EditView.swift
//  iOS
//
//  Created by bart Shin on 2021/08/04.
//

import SwiftUI

struct EditView: View, SavingDelegation  {
	
	
	@EnvironmentObject var imageEditor: ImageEditor
	@EnvironmentObject var recorder: CameraRecorder
	@State private var currentCategory: FilterCategory<Any>?
	@State private var feedBackImage: Image?
	@State private var isCaptured = false
	@Binding var navigationTag: String?
	
    var body: some View {
		ZStack {
			GeometryReader { geometry in
				VStack (spacing: 0) {
					drawTopbar(in: geometry.size,
							   topMargin: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 50)
					imagePreview
					drawBottombar(in: geometry.size)
				}
			}
			.ignoresSafeArea(.all)
			FeedBackView(feedBackImage: $feedBackImage)
		}
		.onAppear {
			imageEditor.savingDelegate = self
		}
		.onDisappear {
			imageEditor.clearImage()
		}
		.navigationBarHidden(true)
    }
	
	// MARK: - User Intents
	private func tapMenu(_ menu: MenuScrollView.Menu) {
		if let tappedCategory = FilterCategory<Any>.allCategories.first(where: {
			$0.labelStrings.contains(menu.title) 
		}) {
			withAnimation {
				currentCategory = tappedCategory
			}
		}else {
			print("Category for \(menu.title) is not found")
		}
	}
	
	private func drawTopbar(in size: CGSize, topMargin: CGFloat) -> some View {
		Rectangle()
			.fill(Color.orange)
			.overlay(
				HStack {
					if !isCaptured {
						backButton
					}else {
						resumeRecordingbutton
					}
					Spacer()
					if !imageEditor.editingState.isRecording {
						saveButton
					}
				}
				.offset(y: topMargin/2)
				.padding(.horizontal, 18)
			)
		.frame(width: size.width, height: size.height * Constant.topbarHeight + topMargin)
	}
	
	private var backButton: some View {
		Button {
			withAnimation {
				navigationTag = nil
			}
		} label:  {
			Image(systemName: "chevron.backward")
				.resizable()
				.renderingMode(.template)
				.aspectRatio(contentMode: .fit)
				.foregroundColor(.white)
				.frame(width: Constant.navigationButtonSize.width, height: Constant.navigationButtonSize.height)
		}
	}
	
	private var resumeRecordingbutton: some View {
		Button {
			recorder.startRecording()
			imageEditor.clearImage()
			imageEditor.editingState.isRecording = true
			imageEditor.clearAllFilter()
			currentCategory = nil
			isCaptured = false
		} label: {
			Text("Cancel")
				.foregroundColor(.white)
		}
	}
	
	private var saveButton: some View {
		Button {
			imageEditor.saveImage()
		} label: {
			Text("Save")
				.font(.title3)
				.foregroundColor(.white)
		}
	}
	
	private var imagePreview: some View {
		ZStack(alignment: .bottom) {
			ImagePreview(currentCategory: $currentCategory)
				.environmentObject(imageEditor.editingState)
				.contentShape(Rectangle())
			if imageEditor.editingState.isRecording  {
				shutterButton
					.padding(.bottom, currentCategory != nil ? 10: 0)
			}
		}
	}
	
	private var shutterButton: some View {
		Button {
			recorder.stopRecording()
			imageEditor.editingState.isRecording = false
			imageEditor.captureImage()
			isCaptured = true
		}label: {
			Circle()
				.size(Constant.overlayButtonSize)
				.fill(Color.blue)
		}
		.frame(width: Constant.overlayButtonSize.width, height: Constant.overlayButtonSize.height)
	}
	
	private func drawBottombar(in size: CGSize) -> some View {
		VStack(spacing: 20) {
			if !imageEditor.editingState.isRecording {
				HistoryBar(currentCategory: $currentCategory)
					.padding(.horizontal, 10)
			}
			if let category = currentCategory {
				FilterControlPannel(category: category,
									size: size)
					.environmentObject(imageEditor.editingState)
					.padding(.horizontal, 10)
			}
			else {
				drawMenuScrollView(in: size)
			}
		}
		.padding(.vertical, 14)
		.padding(.horizontal, 5)
		.padding(.bottom, 30)
		.layoutPriority(1)
	}
	private var menus: [MenuScrollView.Menu] {
		let language = LocaleManager.currentLanguageCode
		if imageEditor.editingState.isRecording {
			return FilterCategory<Any>.categiresForRecording.map { category in
				MenuScrollView.Menu(title: category.labelStrings[language.rawValue], iconImage: category.labelImage)
			}
		}
		else {
			return FilterCategory<Any>.allCategories.map { category in
				MenuScrollView.Menu(title: category.labelStrings[language.rawValue], iconImage: category.labelImage)
			}
		}
	}
	
	private func drawMenuScrollView(in size: CGSize) -> some View {
		MenuScrollView(menus: menus, tapMenu: tapMenu(_:))
			.frame(height: size.height * Constant.menuViewHeight)
	}
	
	// MARK: - Saving delegation
	func savingCompletion(error: Error?) {
		if error == nil {
			withAnimation{
				feedBackImage = Image(systemName: "checkmark")
			}
		}else {
			print("Fail to save image: \(error!.localizedDescription)")
		}
	}
	
	private struct Constant {
		static let referenceHeight: CGFloat = 812
		static let topbarHeight: CGFloat = 30/referenceHeight
		static let imageViewHeight: CGFloat = 563/referenceHeight
		static let menuViewHeight: CGFloat = 80/referenceHeight
		static let overlayButtonSize = CGSize(width: 50, height: 50)
		static let navigationButtonSize = CGSize(width: 18, height: 18)
	}
}



#if DEBUG
struct NewEditView_Previews: PreviewProvider {
    static var previews: some View {
		EditView(navigationTag: Binding<String?>.constant(String(describing: EditView.self)))
			.environmentObject(ImageEditor.forPreview)
    }
}
#endif

