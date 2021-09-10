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
					.transition(.offset(x: Constant.iconSize.width, y: Constant.iconSize.height * 10).combined(with: .opacity))
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
				.foregroundColor(imageEditor.historyManager.undoAble || imageEditor.historyManager.redoAble ?
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
				.renderingMode(.template)
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
		if category.category == MultiSliderFilterControl.textStamp.rawValue {
			imageEditor.applyTextStamp()
		}
		else if category.category == DrawableFilterControl.maskBlur.rawValue {
			imageEditor.applyMaskBlur()
			imageEditor.editingState.resetDrawing()
		}
		else if category.category == DrawableFilterControl.drawing.rawValue {
			imageEditor.addDrawing()
			imageEditor.editingState.resetDrawing()
		}
		else if category.category == DistortionFilterControl.crop.rawValue {
			imageEditor.applyCrop()
		}
		else if category.category == DistortionFilterControl.rotate.rawValue {
			imageEditor.applyRotation()
		}else {
			imageEditor.storeCurrentState()
		}
	}
	
	private struct Constant {
		static let iconSize = CGSize(width: 32, height: 32)
		static var buttonColor = DesignConstant.getColor(for: .onBackground)
		static var disabledButtonColor = DesignConstant.chooseColor(in: (light: 0xB2B2B2, dark: 0x4D4D4D))
		static var resetButtonColor = DesignConstant.chooseColor(in: (light: 0xFF3B30, dark: 0xFF453A))
		static var disabledResetButtonColor = DesignConstant.chooseColor(in: (light: 0xFFC3C0, dark: 0x4D1511))
	}
}

struct HistoryBar_Previews: PreviewProvider {
    static var previews: some View {
		HistoryBar(currentCategory: .constant(nil))
    }
}
