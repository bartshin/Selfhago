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
		VStack {
			alignmentPicker
			Text(editingState.control.textStampContent)
				.font(fontWithoutSize)
			HStack{
				showingSheetButton
					.sheet(isPresented: $isShowingFontPicker) {
						editTextSheet
					}
				confirmButton
			}
		}
	}
	
	private var alignmentPicker: some View {
		HStack{
			Picker(selection: $editingState.control.textStampAlignment,
				   label: Text("Text alignment")) {
				ForEach(TextMask.Alignment.allCases, id: \.self) {
					getImage(for: $0)
				}
			}
			.pickerStyle(SegmentedPickerStyle())
		}
	}
	
	private var showingSheetButton: some View {
		Button {
			withAnimation {
				self.isShowingFontPicker = true
			}
		} label: {
			Image(systemName: "textformat.alt")
		}
	}
	
	private var confirmButton: some View {
		Button {
			editor.applyRefractedText()
		} label: {
			Image(systemName: "checkmark.seal.fill")
		}
	}
	
    private var editTextSheet: some View {
		
		GeometryReader { geometry in
			Form {
				drawTextview(in: geometry.size)
				fontSizeSlider
				fontPicker
			}
		}
    }
	
	private func drawTextview(in size: CGSize) -> some View {
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
				.frame(height: size.height * 0.3)
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
	
	private var fontWithoutSize: Font {
		Font(UIFont(descriptor: editingState.control.textStampFont.descriptor, size: 20))
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
}
















struct TextConfigPanel_Previews: PreviewProvider {
	static var previews: some View {
		TextConfigPanel()
			.environmentObject(EditingState())
			.environmentObject(ImageEditor())
	}
}
