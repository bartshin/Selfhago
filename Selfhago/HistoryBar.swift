//
//  HistoryBar.swift
//  iOS
//
//  Created by bart Shin on 2021/08/04.
//

import SwiftUI

struct HistoryBar: View {
	
	@EnvironmentObject var imageEditor: ImageEditor
	@Binding var currentCategory: FilterCategory<Any>?
	
    var body: some View {
		HStack (spacing: 32) {
			resetButton
			Spacer()
			undoButton
			redoButton
			if currentCategory != nil {
				Spacer()
				confirmButton
			}
		}
    }
	
	private var resetButton: some View {
		Button {
			imageEditor.clearAllFilter()
		} label : {
			Image("reset")
				.resizable()
				.renderingMode(.template)
				.frame(width: Constant.iconSize.width,
					   height: Constant.iconSize.height)
				.foregroundColor(imageEditor.historyManager.nextFilterIndex > 0 ?
									Constant.resetButtonColor:
									Constant.disabledResetButtonColor)
		}
	}
	
	private var undoButton: some View {
		Button {
			imageEditor.undo()
		} label: {
			Image("undo")
				.resizable()
				.renderingMode(.template)
				.frame(width: Constant.iconSize.width,
					   height: Constant.iconSize.height)
				.foregroundColor(imageEditor.historyManager.undoAble ?
									Constant.buttonColor:
									Constant.disabledButtonColor)
		}
		.disabled(!imageEditor.historyManager.undoAble)
	}
	
	private var redoButton: some View {
		Button {
			imageEditor.redo()
		} label: {
			Image("redo")
				.resizable()
				.renderingMode(.template)
				.frame(width: Constant.iconSize.width,
					   height: Constant.iconSize.height)
				.foregroundColor(imageEditor.historyManager.redoAble ?
									Constant.buttonColor:
									Constant.disabledButtonColor)
		}
		.disabled(!imageEditor.historyManager.redoAble)
	}
	
	private var confirmButton: some View {
		Button(action: tapCofirmButton) {
			Image("checkmark")
				.resizable()
				.frame(width: Constant.iconSize.width,
					   height: Constant.iconSize.height)
				.foregroundColor(Constant.buttonColor)
		}
		
	}
	
	private func tapCofirmButton() {
		guard let category = currentCategory else {
			return
		}
		defer {
			withAnimation {
				currentCategory = nil
			}
		}
		if category.subCategory == MultiSliderFilterControl.textStamp.rawValue {
			imageEditor.applyTextStamp()
		}
		else if category.subCategory == DrawableFilterControl.mask.rawValue {
			imageEditor.applyMaskBlur()
		}
		
	}
	
	private struct Constant {
		static let iconSize = CGSize(width: 32, height: 32)
		static let buttonColor: Color = .black
		static let disabledButtonColor: Color = .gray.opacity(0.7)
		static let resetButtonColor: Color = .red
		static let disabledResetButtonColor: Color = .red.opacity(0.5)
	}
}

struct HistoryBar_Previews: PreviewProvider {
    static var previews: some View {
		HistoryBar(currentCategory: .constant(nil))
    }
}
