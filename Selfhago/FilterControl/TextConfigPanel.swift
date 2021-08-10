//
//  TextConfigPanel.swift
//  Selfhago
//
//  Created by bart Shin on 23/07/2021.
//

import SwiftUI

struct TextConfigPanel: View {
	
	@EnvironmentObject var editor: ImageEditor
	@EnvironmentObject var editingState: EditingState
	@State private var isShowingFontPicker = false
	
	var body: some View {
		VStack{
			showingSheetButton
				.sheet(isPresented: $isShowingFontPicker) {
					editTextSheet
				}
			GeometryReader { geometry in
				ColorPickerWheel(color: $editingState.control.textStampColor,
								 frame: geometry.frame(in: .local),
								 strokeWidth: 25)
			}
			.frame(width: Constant.colorPickerSize.width,
				   height: Constant.colorPickerSize.height)
		}
	}
	
	private var showingSheetButton: some View {
		Button {
			withAnimation {
				self.isShowingFontPicker = true
			}
		} label: {
			Text("Change Text")
		}
	}
	
    private var editTextSheet: some View {
		Form {
			textView
			fontPicker
		}
    }
	
	private var textView: some View {
		Section (header:
					HStack {
						Text("Content")
						dismissKeyboardButton
						Spacer()
						doneButton
					}
		) {
			TextEditor(text: $editingState.control.textStampContent)
				.font(fontWithSize)
				.frame(height: Constant.textViewHeight)
				.foregroundColor(Color(editingState.control.textStampColor))
				.onTapGesture {
					editingState.clearTextIfDefault()
				}
		}
	}
	
	private var dismissKeyboardButton: some View {
		Button {
			UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
		} label: {
			Image(systemName: "keyboard.chevron.compact.down")
		}
	}
	
	private var doneButton: some View {
		Button {
			isShowingFontPicker = false
		} label: {
			Text("Done")
		}
	}
	
	private var fontSizeSlider: some View {
		Slider(value: Binding<CGFloat> {
			editingState.control.textStampFont.fontSize
		} set: { 
			editingState.control.textStampFont.fontSize = $0
		},
		in: 20...80) {
			Text("Size")
		}
	}
	
	private var fontPicker: some View {
		Section (header:
					Text("Font"))
		{
			UIFontPickerRepresentable { newFont in
				editingState.control.textStampFont.descriptor = newFont
			}
		}
	}
	
	private var fontWithSize: Font {
		Font(UIFont(descriptor: editingState.control.textStampFont.descriptor,
					size: editingState.control.textStampFont.fontSize) as CTFont)
	}
	
	private func getImage(for alignment: TextMask.Alignment) -> Image {
		switch alignment {
			case .topLeft:
				return Image(systemName: "arrow.up.backward.square")
			case .topRight:
				return Image(systemName: "arrow.up.right.square")
			case .bottomLeft:
				return Image(systemName: "arrow.down.left.square")
			case .bottomRight:
				return Image(systemName: "arrow.down.right.square")
			case .center:
				return Image(systemName: "dot.squareshape.split.2x2")
		}
	}
	
	private struct Constant {
		static let textViewHeight: CGFloat = 200
		static let colorPickerSize = CGSize(width: 100, height: 100)
	}
}


struct TextConfigPanel_Previews: PreviewProvider {
	static var previews: some View {
		TextConfigPanel()
			.environmentObject(EditingState())
			.environmentObject(ImageEditor())
	}
}
