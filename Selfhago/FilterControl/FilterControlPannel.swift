//
//  FilterControlPannel.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/06.
//

import SwiftUI

struct FilterControlPannel: View {
	
	@EnvironmentObject var imageEditor: ImageEditor
	@EnvironmentObject var editingState: EditingState
	let category: FilterCategory<Any>
	let size: CGSize
	
    var body: some View {
		if let mainSliderControl = category.control as? SingleSliderFilterControl {
			MainSliderControlView(size: size, control: mainSliderControl)
		}else if let drawableFilter = category.control as? DrawableFilterControl{
			drawControls(for: drawableFilter)
		}else if let onOffFilter = category.control as? OnOffFilter {
			drawOnOffControl(for: onOffFilter)
		}else if let multiSliderFilter = category.control as? MultiSliderFilterControl {
			drawMultiSliderControl(for: multiSliderFilter)
		}else if let distortionFilter = category.control as? DistortionFilterControl {
			drawControls(for: distortionFilter)
		}
    }
	
//	@State private var showingToolPicker = false
	private func drawControls(for filter: DrawableFilterControl) -> some View {
		VStack {
			
			if filter == .maskBlur {
				HStack {
					Text(filter.labelStrings[LocaleManager.currentLanguageCode.rawValue])
					Spacer()
					canvasToolButtons
				}
				.onAppear {
					editingState.control.isDrawing = true
					editingState.changeDrawingTool(type: .marker)
				}
				blurSlierControls
			}
			else if filter == .drawing {
				VStack {
					Text(filter.labelStrings[LocaleManager.currentLanguageCode.rawValue])
					DrawingToolPicker(isPresenting: $editingState.control.isDrawing,
									  canvas: editingState.drawingMaskView,
									  picker: editingState.drawingToolPicker)
						.frame(height: size.height * 0.1)
						.onAppear {
							editingState.control.isDrawing = true
						}
				}
			}
		}
	}
	
	private var canvasToolButtons: some View {
		Group {
			Button {
				editingState.control.isDrawing = true
			} label: {
				Image(systemName: "pencil")
					.resizable()
					.renderingMode(.template)
			}
			.buttonStyle(SubButtonStyle(isActive: editingState.control.isDrawing))
			
			Button {
				editingState.control.isDrawing = false
			} label: {
				Image(systemName: "pencil.tip.crop.circle.badge.minus")
					.resizable()
					.renderingMode(.template)
			}
			.buttonStyle(SubButtonStyle(isActive: !editingState.control.isDrawing))
		}
	}
	
	private var blurSlierControls: some View {
		Group {
			HStack {
				Text("Intensity")
				Slider(value: $editingState.control.blurIntensity,
					   in: 0...20, step: 1)
					.disabled(!editingState.control.isDrawing)
					.opacity(editingState.control.isDrawing ? 1: 0.3)
			}
			HStack {
				Text("Radius")
				Slider(value:Binding<CGFloat> {
					editingState.control.drawingTool.width
				} set: {
					editingState.changeDrawingTool(width: $0)
				}, in: 10...60, step: 1) // Marker width range is 10...60 in Pencil kit
					.disabled(!editingState.control.isDrawing)
					.opacity(editingState.control.isDrawing ? 1: 0.3)
			}
		}
	}
	
	private func drawMultiSliderControl(for control: MultiSliderFilterControl) -> some View {
		let title = control.labelStrings[LocaleManager.currentLanguageCode.rawValue]
		let values = binding(to: control)
		let ranges = getRanges(for: control)
		return
			HStack {
				VerticalSliderView(title: title,
								   values: values,
								   ranges: ranges,
								   drawGraph: false,
								   onValueChanging: { index in
									onValueChanging(of: control)
								   })
				if control == .textStamp {
					TextConfigPanel()
				}
			}
			.frame(height: size.height * 0.25)
	}
	
	private func binding(to control: MultiSliderFilterControl) -> [Binding<CGFloat>] {
		switch control {
			case .bilateral:
				return [
					$editingState.control.bilateralControl.radius,
					$editingState.control.bilateralControl.intensity
				]
			case .vignette:
				return [
					$editingState.control.vignetteControl.radius,
					$editingState.control.vignetteControl.intensity,
					$editingState.control.vignetteControl.edgeBrightness,
				]
			case .outline:
				return [
					$editingState.control.outlineControl.bias,
					$editingState.control.outlineControl.weight
				]
			case .textStamp:
				return [
					$editingState.control.textStampFont.fontSize,
					$editingState.control.textStampControl.opacity,
					$editingState.control.textStampControl.rotation
				]
			default:
				return []
		}
	}
	
	private func getRanges(for control: MultiSliderFilterControl) -> [ClosedRange<CGFloat>] {
		(0..<control.tunableFactors).map { index in
			control.getRange(for: index)
		}
	}
	
	@State private var currentPreset = PresetFilter.portraitLut
	private func drawOnOffControl(for filter: OnOffFilter) -> some View {
		Group {
			if filter == .presetFiter {
				HStack {
					presetCategoryButtons
					MenuScrollView(menus: presetFilterMenus) { menu in
						imageEditor.setLutCube(menu.title)
					}
				}
			}
		}
	}
	
	private func onValueChanging(of control: MultiSliderFilterControl) {
		switch control {
			case .bilateral:
				imageEditor.setBilateral()
			case .outline:
				imageEditor.setOutline()
			case .vignette:
				imageEditor.setVignette()
			default:
				break
		}
	}
	
	private var presetCategoryButtons: some View {
		VStack {
			ForEach(PresetFilter.allCases, id: \.self.lutCode) { preset in
				Button {
					withAnimation {
						currentPreset = preset
					}
				} label: {
					Image(uiImage: preset.labelImage)
						.resizable()
						.renderingMode(.template)
						.frame(width: Constant.squareButtonSize.width,
							   height: Constant.squareButtonSize.height)
						.foregroundColor(preset == currentPreset ? .blue: .black)
				}
			}
		}
	}
	
	@State private var currentRatioPresetCategory = "vertical"
	
	private func tapRatioButton(of menu: MenuScrollView.Menu) {
		let title = menu.title
		
		if DistortionFilterControl.CropRatioPreset.freeformLabelStrings.contains(title) {
			editingState.setViewFinderRatio(nil)
		}
		else if DistortionFilterControl.CropRatioPreset.orignalLabelStrings.contains(title) {
			editingState.setViewFinderRatio(editingState.originalRatio)
		}
		else if let selectedPreset = DistortionFilterControl.CropRatioPreset.allCases.first(where: { preset in
			preset.labelStrings.contains(title)
		}) {
			editingState.setViewFinderRatio(selectedPreset.ratio)
		}
		else {
			assertionFailure("Fail to get ratio for \(menu.title)")
		}
	}
	
	private func drawControls(for filter: DistortionFilterControl) -> some View {
		 VStack {
			 if filter == .rotate {
				 rotationTopBar
				 GraduationSlider(bindingTo: $editingState.control.rotation,
								  range: 45,
								  step: 1,
								  width: size.width * 0.8)
					 .frame(width: size.width * 0.8,
							height: 20)
			}
			 else if filter == .crop {
				 MenuScrollView(menus: ratioPresetCategoryMenu,
								tapMenu: { menu in
					 withAnimation {
						 currentRatioPresetCategory = menu.title
					 }
				 }, activeMenuTitles: .init(get: {
					 [currentRatioPresetCategory]
				 }, set: { _ in}))
					 .frame(width: size.width * 0.4)
				 MenuScrollView(menus: ratioPresetMenu,
								tapMenu: tapRatioButton(of:),
								activeMenuTitles: .init {
					 if editingState.control.viewFinderRatio == nil {
						 return DistortionFilterControl.CropRatioPreset.freeformLabelStrings
					 } else {
						 return []
					 }
				 } set: {_ in })
			 }
		}
		 .padding(.bottom, 20)
	}
	
	private var rotationTopBar: some View {
		HStack (spacing: 10) {
			rotationBy90DegreeButtons
			Spacer()
			Text(String(Float(Int(editingState.control.rotation)%360*10)/10))
				.foregroundColor(DesignConstant.getColor(for: .primary, isDimmed: true))
			Spacer()
			flipButtons
		}
		.padding(.vertical, 15)
	}
	
	private var rotationBy90DegreeButtons: some View {
		let buttonStyle = SubButtonStyle()
		return Group {
			Button {
				withAnimation {
					editingState.control.rotation -= 90
				}
			} label: {
				Image(systemName: "rotate.left")
					.renderingMode(.template)
					.resizable()
			}
			.buttonStyle(buttonStyle)
			Button {
				withAnimation {
					editingState.control.rotation += 90
				}
			} label: {
				Image(systemName: "rotate.right")
					.renderingMode(.template)
					.resizable()
			}
			.buttonStyle(buttonStyle)
		}
	}
	
	private var flipButtons: some View {
		let buttonStyle = SubButtonStyle()
		return Group {
			Button {
				imageEditor.applyFlip(horizontal: true)
			} label: {
				Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
					.renderingMode(.template)
					.resizable()
			}
			.buttonStyle(buttonStyle)
			Button {
				imageEditor.applyFlip(horizontal: false)
			} label: {
				Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down")
					.renderingMode(.template)
					.resizable()
			}
			.buttonStyle(buttonStyle)
		}
	}
	
	private var ratioPresetCategoryMenu: [MenuScrollView.Menu] {
		var vertical = MenuScrollView.Menu(title: "vertical", iconImage: DistortionFilterControl.CropRatioPreset.h9v16.labelImage,
										   hasBorder: false)
		vertical.displayTitle = false
		vertical.sizeRatio = 0.7
		var horizontal = MenuScrollView.Menu(title: "horizontal",
											 iconImage: DistortionFilterControl.CropRatioPreset.h16v9.labelImage,
											 hasBorder: false)
		horizontal.displayTitle = false
		horizontal.sizeRatio = 0.7
		return [vertical, horizontal]
	}
	
	private var ratioPresetMenu: [MenuScrollView.Menu] {
		let languageCode = LocaleManager.currentLanguageCode.rawValue
		let freeform = MenuScrollView.Menu(title: DistortionFilterControl.CropRatioPreset.freeformLabelStrings[languageCode],
										   iconImage: DistortionFilterControl.CropRatioPreset.freeformLabelImage)
		let original = MenuScrollView.Menu(title: DistortionFilterControl.CropRatioPreset.orignalLabelStrings[languageCode],
										   iconImage: DistortionFilterControl.CropRatioPreset.originalLabelImage)
		if currentRatioPresetCategory == "vertical" {
			return [freeform, original] + DistortionFilterControl.CropRatioPreset.vertical.map { preset in
				 MenuScrollView.Menu(title: preset.labelStrings[languageCode],
									iconImage: preset.labelImage)
			}
		}
		else if currentRatioPresetCategory == "horizontal" {
			return [freeform, original] + DistortionFilterControl.CropRatioPreset.horizontal.map { preset in
				MenuScrollView.Menu(title: preset.labelStrings[languageCode],
									iconImage: preset.labelImage)
			}
		}else {
			assertionFailure("Menu for preset \(currentRatioPresetCategory) is not found")
			return []
		}
	}
	
	private var presetFilterMenus: [MenuScrollView.Menu] {
			currentPreset.luts.map { lutName in
				let iconImage = editingState.presetThumnails[lutName] ?? DesignConstant.presetFilterImage
			return .init(title: lutName, filterImage: iconImage)
		}
	}
	
	private struct SubButtonStyle: ButtonStyle {
		var isActive: Bool
		func makeBody(configuration: Configuration) -> some View {
			ZStack {
				(configuration.isPressed || isActive ? Constant.subButtonBackgroundColor.pressed: Constant.subButtonBackgroundColor.normal)
					.clipShape(RoundedRectangle(cornerRadius: 5))
				configuration.label
					.foregroundColor(configuration.isPressed || isActive ? Constant.subButtonForegroundColor.pressed: Constant.subButtonForegroundColor.normal)
					.padding(5)
			}
			.frame(width: Constant.subButtonSize.width,
				   height: Constant.subButtonSize.height)
		}
		init(isActive:Bool? = nil) {
			self.isActive = isActive ?? false
		}
	}
	
	private struct Constant {
		static let referenceHeight: CGFloat = DesignConstant.referenceSize.height
		static let squareButtonSize = CGSize(width: 30, height: 30)
		static let subButtonSize = CGSize(width: 35, height: 35)
		static let subButtonForegroundColor: (normal: Color, pressed: Color) = (DesignConstant.getColor(for: .primary), DesignConstant.getColor(for: .onPrimary))
		static let subButtonBackgroundColor: (normal: Color, pressed: Color) = (DesignConstant.getColor(for: .background), DesignConstant.getColor(for: .primary))
	}
}

#if DEBUG
struct FilterControlPannel_Previews: PreviewProvider {
	static let imageEditor = ImageEditor.forPreview
	
	static var previews: some View {
		GeometryReader { geometry in
			VStack{
				Spacer()
				FilterControlPannel(category: FilterCategory<Any>(rawValue: MultiSliderFilterControl.bilateral.rawValue)!,
									size: geometry.size)
					.environmentObject(imageEditor)
					.environmentObject(imageEditor.editingState)
					.padding()
			}
		}
	}
}
#endif
