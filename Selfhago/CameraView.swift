//
//  CameraView.swift
//  Selfhago
//
//  Created by bart Shin on 27/07/2021.
//

import SwiftUI

struct CameraView: View {
	
	@EnvironmentObject var imageEditor: ImageEditor
	@ObservedObject var recorder: CameraRecorder
	@Binding var navigationTag: String?
	@State private var isShowingAlert = false
	@State private var currentCategory: FilterCategory<Any>? = nil
	
    var body: some View {
		GeometryReader { geometry in
			ZStack (alignment: .bottom) {
				EditView(navigationTag: $navigationTag)
					.environmentObject(recorder)
			}
			.alert(isPresented: $isShowingAlert, content: showPermissionAlert)
		}
		.onDisappear {
			recorder.stopRecording()
			imageEditor.clearImage()
			imageEditor.editingState.isRecording = false
		}
		.onAppear{
			imageEditor.editingState.isRecording = true
			imageEditor.editingState.reset()
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
	
	private var availableFilters: [FilterCategory<Any>] {
		let filters = [SingleSliderFilterControl.brightness, .saturation, .contrast].compactMap{ $0.rawValue } +
			[
				MultiSliderFilterControl.vignette.rawValue,
				MultiSliderFilterControl.outline.rawValue,
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
}

#if DEBUG
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
		CameraView(recorder: CameraRecorder(), navigationTag: .constant(nil))
    }
}
#endif
