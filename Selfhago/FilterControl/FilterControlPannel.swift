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
	
	private func drawControls(for filter: DrawableFilterControl) -> some View {
		VStack {
			if filter == .maskBlur {
				HStack {
					Text(filter.labelStrings[LocaleManager.currentLanguageCode.rawValue])
					Spacer()
					canvasToolButtons
				}
				blurSlierControls
					.onAppear {
						editingState.control.isDrawing = true
						editingState.changeDrawingTool(type: .marker, color: .black)
					}
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
		return VStack {
			if control == .outline {
				outlineFilterButtons
			}
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
		}
		.frame(height: size.height * 0.25)
	}
	
	private var outlineFilterButtons: some View {
		HStack {
			MenuScrollView(menus: outlineFilterMenu,
						   tapMenu: { menu in
				if editingState.control.selectedOutlineFilter == .color, MultiSliderFilterControl.OutlineFilter.grayscale.labelStrings.contains(menu.title) {
					editingState.resetOutlineColor(to: .grayscale)
				}
				else if editingState.control.selectedOutlineFilter == .grayscale,
						MultiSliderFilterControl.OutlineFilter.color.labelStrings.contains(menu.title) {
					editingState.resetOutlineColor(to: .color)
				}
			}, activeMenuTitles: .init {
				editingState.control.selectedOutlineFilter.labelStrings
			} set: { _ in })
			if editingState.control.selectedOutlineFilter == .grayscale {
				backgroundColorPicker
			}
		}
	}
	
	private var backgroundColorPicker: some View {
		Group{
			VStack{
				ColorPicker("", selection: .init{
					Color(editingState.control.outlineSketchColor)
				} set: {
					editingState.control.outlineSketchColor = UIColor($0)
					imageEditor.setOutline()
				})
					.frame(width: size.width * 0.2)
				Text("Pen")
					.font(.caption)
			}
			VStack{
				ColorPicker("", selection: .init{
					Color(editingState.control.outlineBackgroundColor)
				} set: {
					editingState.control.outlineBackgroundColor = UIColor($0)
					imageEditor.setOutline()
				})
					.frame(width: size.width * 0.2)
				Text("Background")
					.font(.caption)
			}
		}
	}
	
	private var outlineFilterMenu: [MenuScrollView.Menu] {
		let languageCode = LocaleManager.currentLanguageCode.rawValue
		var grayscale = MenuScrollView.Menu(title: MultiSliderFilterControl.OutlineFilter.grayscale.labelStrings[languageCode], iconImage: MultiSliderFilterControl.OutlineFilter.grayscale.labelImage, hasBorder: false)
		grayscale.sizeRatio = 0.7
		grayscale.displayTitle = false
		var color = MenuScrollView.Menu(title: MultiSliderFilterControl.OutlineFilter.color.labelStrings[languageCode], iconImage: MultiSliderFilterControl.OutlineFilter.color.labelImage, hasBorder: false)
		color.sizeRatio = 0.7
		color.displayTitle = false
		return [grayscale, color]
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
				if editingState.control.selectedOutlineFilter == .color {
					return [
						$editingState.control.outlineControl[0],
						$editingState.control.outlineControl[1]
					]
				}else {
					return (0...2).compactMap {
						$editingState.control.outlineControl[$0]
					}
				}
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
		if control == .outline{
			return (0..<editingState.control.selectedOutlineFilter.tunableFactor).map {
				editingState.control.selectedOutlineFilter.getRange(for: $0)
			}
		}else {
			return (0..<control.tunableFactors).map { index in
				control.getRange(for: index)
			}
		}
	}
	
	@State private var currentPreset = PresetFilter.portraitLut
	private func drawOnOffControl(for filter: OnOffFilter) -> some View {
		Group {
			if filter == .presetFiter {
				HStack {
					presetCategoryButtons
					MenuScrollView(menus: presetFilterMenus, tapMenu: { menu in
						editingState.control.selectedLutName = menu.title
						imageEditor.setLutCube()
					}, activeMenuTitles: .init {
						editingState.control.selectedLutName != nil ? [editingState.control.selectedLutName!]: []
					} set: { _ in })
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
	
	@State private var isShowingHPerspective = true
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
			 else if filter == .perspective {
				 VStack (alignment: .center, spacing: 20) {
					 selectPerspectiveButtons
						 .frame(width: size.width * 0.5)
					 QuadAngleControl(isHorizontal: isShowingHPerspective,
									  topOrLeft: bindingPerspectiveControl(isTopOrLeft: true),
									  bottomOrRight: bindingPerspectiveControl(isTopOrLeft: false)) {
						 imageEditor.setPerspective()
					 }
									  .frame(width: size.width * 0.6,
											 height: 200)
				 }
			 }
		}
		 .padding(.bottom, 20)
	}
	
	private func bindingPerspectiveControl(isTopOrLeft: Bool) -> Binding<ClosedRange<CGFloat>> {
		.init {
			if isShowingHPerspective {
				return isTopOrLeft ? editingState.control.perspectiveControl[0].x...editingState.control.perspectiveControl[1].x:
				editingState.control.perspectiveControl[2].x...editingState.control.perspectiveControl[3].x
			}else {
				return isTopOrLeft ? editingState.control.perspectiveControl[0].y...editingState.control.perspectiveControl[2].y:
				editingState.control.perspectiveControl[1].y...editingState.control.perspectiveControl[3].y
			}
		} set: { newRange in
			let lowerPointIndex: Int
			let upperPointIndex: Int
			if isTopOrLeft {
				lowerPointIndex = 0
				upperPointIndex = isShowingHPerspective ? 1: 2
			}else {
				lowerPointIndex = isShowingHPerspective ? 2: 1
				upperPointIndex = 3
			}
			if isShowingHPerspective {
				editingState.control.perspectiveControl[lowerPointIndex].x = newRange.lowerBound
				editingState.control.perspectiveControl[upperPointIndex].x = newRange.upperBound
			}else {
				editingState.control.perspectiveControl[lowerPointIndex].y = newRange.lowerBound
				editingState.control.perspectiveControl[upperPointIndex].y = newRange.upperBound
			}
		}

	}
	
	private var selectPerspectiveButtons: some View {
		MenuScrollView(menus: selectPerspectiveMenus, tapMenu: { menu in
			let tappedHorizontal = menu.title == "horizontal"
			if isShowingHPerspective != tappedHorizontal {
				editingState.resetPerspectiveControl()
				withAnimation {
					isShowingHPerspective = tappedHorizontal
				}
			}
		}, activeMenuTitles: .init {
			isShowingHPerspective ? ["horizontal"]: ["vertical"]
		} set: {_ in})
	}
	
	private var selectPerspectiveMenus: [MenuScrollView.Menu] {
		var horizontal = MenuScrollView.Menu(title:"horizontal", iconImage: UIImage(systemName: "h.square")!, hasBorder: false)
		horizontal.displayTitle = false
		horizontal.sizeRatio = 0.7
		var vertical = MenuScrollView.Menu(title: "vertical", iconImage: UIImage(systemName: "v.square")!, hasBorder: false)
		vertical.displayTitle = false
		vertical.sizeRatio = 0.7
		return [horizontal, vertical]
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
		static var subButtonForegroundColor: (normal: Color, pressed: Color) = (DesignConstant.getColor(for: .primary), DesignConstant.getColor(for: .onPrimary))
		static var subButtonBackgroundColor: (normal: Color, pressed: Color) = (DesignConstant.getColor(for: .background), DesignConstant.getColor(for: .primary))
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
