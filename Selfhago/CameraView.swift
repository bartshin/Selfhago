//
//  CameraView.swift
//  Selfhago
//
//  Created by bart Shin on 27/07/2021.
//

import SwiftUI

struct CameraView: View {
	
	@ObservedObject private var recorder: CameraRecorder
	@State private var isShowingAlert = false

    var body: some View {
		VStack {
			CameraPreview(session: recorder.captureSession)
				.alert(isPresented: $isShowingAlert, content: showPermissionAlert)
		}
		.onAppear{
			recorder.checkAuthorization {
				recorder.setupCamera(position: .back)
				recorder.startRecording()
			} deniedHandler: {
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					isShowingAlert = true
				}
			}
		}
		.onDisappear {
			recorder.stopRecording()
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
	
	
	init(recorder: CameraRecorder) {
		
		self.recorder = recorder
	}
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
		CameraView(recorder: CameraRecorder())
    }
}
