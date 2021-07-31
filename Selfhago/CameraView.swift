//
//  CameraView.swift
//  Selfhago
//
//  Created by bart Shin on 27/07/2021.
//

import SwiftUI

struct CameraView: View, EditorDelegation {
	
	@EnvironmentObject var editor: ImageEditor
	@ObservedObject var recorder: CameraRecorder
	@State private var isShowingAlert = false
	@State private var currentCategory = FilterCategory<Any>(rawValue: SingleSliderFilterControl.brightness.rawValue)!
	@State private var feedBackImage: Image?
	
    var body: some View {
		GeometryReader { geometry in
			VStack {
				ZStack {
					ImagePreview(category: $currentCategory)
						.ignoresSafeArea()
					FeedBackView(feedBackImage: $feedBackImage)
				}
				.layoutPriority(1)
				ZStack(alignment: .topLeading) {
					TuningPanel(selected: $currentCategory, in: availableFilters)
						.frame(height: Constant.tuningPanelHeight)
					shutterButton
						.frame(width: Constant.shutterButtonSize.width, height: Constant.shutterButtonSize.height)
						.offset(x: (geometry.size.width - Constant.shutterButtonSize.width)/2, y: -Constant.shutterButtonSize.height)
				}
			}
			.alert(isPresented: $isShowingAlert, content: showPermissionAlert)
		}
		.onDisappear {
			recorder.stopRecording()
			editor.clearImage()
			editor.editingState.isRecording = false
		}
		.onAppear{
			editor.editingState.reset()
			editor.savingDelegate = self
			recorder.checkAuthorization {
				recorder.setupCamera(position: .back)
				recorder.startRecording()
			} deniedHandler: {
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					isShowingAlert = true
				}
			}
		}
		
    }
	
	private var shutterButton: some View {
		Button {
			editor.saveImage()
		}label: {
			Circle()
				.size(Constant.shutterButtonSize)
				.fill(Color.blue)
		}
	}
	
	func savingCompletion(error: Error?) {
		if error != nil {
			print("Fail to save image \(error!.localizedDescription)")
		}else {
			withAnimation {
				feedBackImage = Image(systemName: "checkmark")
			}
		}
	}
	
	private var availableFilters: [FilterCategory<Any>] {
		let filters = [SingleSliderFilterControl.brightness, .saturation, .contrast].compactMap{ $0.rawValue } +
			[
				MultiSliderFilterControl.vignette.rawValue,
				MultiSliderFilterControl.outline.rawValue,
				AngleAndSliderFilterControl.glitter.rawValue
			] +
			OnOffFilter.allCases.compactMap { $0.rawValue }
		return filters.map {
			FilterCategory(rawValue: $0)! 
		}
	}
	
	private func showPermissionAlert() -> Alert {
		Alert(title: Text("카메라 접근 권한"),
			  message: Text("사용자의 카메라에 대한 권한이 없습니다 설정에서 권한을 허용해주세요"),
			  primaryButton: .default(Text("설정 열기")) {
				UIApplication.shared.open( URL(string: UIApplication.openSettingsURLString)!)
			  },
			  secondaryButton: .cancel())
	}
	private struct Constant {
		static let shutterButtonSize = CGSize(width: 50, height: 50)
		static let tuningPanelHeight: CGFloat = 200
	}
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
		CameraView(recorder: CameraRecorder())
    }
}
