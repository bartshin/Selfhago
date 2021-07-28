//
//  EditView.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

struct EditView: View, EditorDelegation {
	
	@EnvironmentObject var editor: ImageEditor
	@State private var isShowingPicker = false
	@State private var feedBackImage: Image?
	@State private var currentCategory = FilterCategory<Any>(rawValue: SingleSliderFilterControl.brightness.rawValue)!
	
    var body: some View {
		GeometryReader { geometry in
			ZStack {
				VStack(spacing: 0) {
					EditingImage(category: $currentCategory)
						.contentShape(Rectangle())
					TuningPanel(category: $currentCategory)
						.onChange(of: isShowingPicker, perform: resetTunner(_:))
						.disabled(editor.uiImage == nil)
						.frame(maxHeight: geometry.size.height * 0.3)
				}
				FeedBackView(feedBackImage: $feedBackImage)
			}
			.toolbar{
				ToolbarItem(placement: .navigationBarLeading, content: drawSaveButton)
				ToolbarItem(placement: .navigationBarTrailing,
							content: drawUndoButton)
				ToolbarItem(placement: .navigationBarTrailing,
							content: drawRedoButton)
				ToolbarItem(placement: .navigationBarTrailing,
							content: drawPickerButton)
			}
			.sheet(isPresented: $isShowingPicker, content: createImagePicker)
			.onAppear (perform: showPickerIfNeeded)
			.navigationTitle("Edit")
		}
    }
	
	private func drawRedoButton() -> some View {
		Button(action: {
			editor.redo()
		}) {
			Text("Redo")
				.font(.title)
		}.disabled(!editor.historyManager.redoAble)
	}
	
	private func drawUndoButton() -> some View {
		Button(action: {
			editor.undo()
		}) {
			Text("Undo")
				.font(.title)
		}.disabled(!editor.historyManager.undoAble)
	}
	
	private func drawSaveButton() -> some View {
		Button(action: {
			editor.saveImage()
		}) {
			Text("SAVE")
				.font(.title)
		}
	}
	
	private func drawPickerButton() -> some View {
		Button(action: {
			isShowingPicker = true
		}) {
			Image(systemName: "photo")
				.font(.title2)
		}
	}
	
	private func createImagePicker () -> ImagePicker {
		ImagePicker(
			picker: $isShowingPicker,
			imageData: Binding<Data>.constant(Data()),
			passImage: editor.setNewImage)
	}
	
	private func resetTunner(_ pickerPresenting: Bool) {
		guard !isShowingPicker else { return }
		withAnimation {
			editor.resetControls()
		}
	}
	
	private func showPickerIfNeeded() {
		guard editor.savingDelegate == nil else {
			return 
		}
		editor.savingDelegate = self
		if editor.uiImage == nil {
			DispatchQueue.main.async {
				isShowingPicker = true
			}
		}
	}
	
	// Editor delegation
	func savingCompletion(error: Error?) {
		if error == nil {
			withAnimation{
				feedBackImage = Image(systemName: "checkmark")
			}
		}else {
			print("Fail to save image: \(error!.localizedDescription)")
		}
	}
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView()
			.preferredColorScheme(.dark)
			.environmentObject(ImageEditor.forPreview)
    }
}
