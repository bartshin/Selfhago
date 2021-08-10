//
//  MainSliderControlView.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/06.
//

import SwiftUI

struct MainSliderControlView: View {
	
	@EnvironmentObject var imageEditor: ImageEditor
	@EnvironmentObject var editingState: EditingState
	let size: CGSize
	let control: SingleSliderFilterControl
	var title: String {
		control.labelStrings[LocaleManager.currentLanguageCode.rawValue]
	}
	var range: ClosedRange<CGFloat> {
		control.getRange()
	}
	
	var body: some View {
		VStack (spacing: 20) {
			HorizontalSliderView(title: title, value: bindingSliderValue(for: control), in: range) {
				onValueChange(for: control)
			}
			if control == .brightness || control == .saturation {
				advancedControls
			}
			else if control == .backgroundTone {
				imageSelectView
			}
			else if control == .glitter {
				glitterControls
			}
		}
		.padding(.bottom, 10)
	}
	
	private var advancedControls: some View {
		Group {
			Divider()
				.frame(height: 1)
				.background(Color.black)
			HStack {
				if control == .saturation {
					rgbSelectButtons
				}
				drawAdditionalSliders(for: control)
					.frame(height: size.height * Constant.verticalSlidersHeight)
			}
			drawGradientBar(for: control)
				.frame(width: size.width * 0.9,
					   height: size.height * Constant.gradientBarHeight)
		}
	}
	
	
	@State private var isShowingImagePicker = false
	private var imageSelectView: some View {
		Group {
			if editingState.depthDataAvailable {
				MenuScrollView(menus: toneImageMenus, tapMenu: tapToneMenu(_:))
					.sheet(isPresented: $isShowingImagePicker) {
						ImagePicker(passImage: imageEditor.setMaterialImage(_:))
					}
			}
			else {
				Text("Need depth data Please pick potrait photo")
					.font(.subheadline)
			}
		}
	}

	private var toneImageMenus: [MenuScrollView.Menu] {
		let images: [UIImage] =  (1...6).map { index in
			UIImage(named: "tone_sample\(index)")!
		}
		let hasPreviousImage = imageEditor.materialImage != nil
		let cameraMenu = MenuScrollView.Menu(title: hasPreviousImage ? "Change": "Cumstom",
											 filterImage: hasPreviousImage ? imageEditor.materialImage!: UIImage(systemName: "photo")!)
		return [cameraMenu] + images.enumerated().map { index, image in
			.init(title: "sameple\(index + 1)", filterImage: image)
		}
	}
	
	private func tapToneMenu(_ menu: MenuScrollView.Menu) {
		guard let index = toneImageMenus.firstIndex(where: { $0.title == menu.title }) else  {
			return
		}
		if index == 0 {
			isShowingImagePicker = true
		}else {
			imageEditor.setMaterialImage(menu.filterImage!)
			imageEditor.setBackgroundToneRetouch()
		}
	}
	
	private func onValueChange(for control: SingleSliderFilterControl) {
		switch control {
			case .brightness, .contrast, .saturation:
				imageEditor.setCIColorControl(with: control.rawValue)
			case .painter:
				imageEditor.setPainter()
			case .backgroundTone:
				imageEditor.setBackgroundToneRetouch()
			case .glitter:
				imageEditor.setGlitter()
		}
	}
	@State private var currentColorControl = ColorChannel.InputParameter.Component.red
	
	private var rgbSelectButtons: some View {
		return
			VStack{
				ForEach([MultiSliderFilterControl.red, .green, .blue], id: \.self.rawValue) { component in
					let inputComponent = ColorChannel.InputParameter.Component.init(rawValue: component.rawValue)!
					Button {
						withAnimation {
							self.currentColorControl = inputComponent
						}
					} label: {
						Image(uiImage: component.label)
							.resizable()
							.renderingMode(.template)
							.frame(width: Constant.subCategoryButtonSize.width,
								   height: Constant.subCategoryButtonSize.height)
							.foregroundColor(Color(inputComponent.representingColor).opacity(currentColorControl == inputComponent ? 1: 0.3))
					}
				}
			}
	}
	private func drawAdditionalSliders(for control: SingleSliderFilterControl) -> some View {
		let language = LocaleManager.currentLanguageCode
		var title: String
		if control == .brightness {
			title =  MultiSliderFilterControl.rgb.labelStrings[language.rawValue]
		}
		else {
			let colorControl = MultiSliderFilterControl(rawValue: currentColorControl.rawValue)!
			title = colorControl.labelStrings[language.rawValue]
		}
		let bindingValues = bindingMultipleValues(for: control)
		let ranges: [ClosedRange<CGFloat>] = (0..<bindingValues.count).map { index in
			control == .brightness ? MultiSliderFilterControl.rgb.getRange(for: 0):
				MultiSliderFilterControl.red.getRange(for: 0)
		}
		return
			VerticalSliderView(title: title,
							   values: bindingValues,
							   ranges: ranges, drawGraph: true,
							   onValueChanging : { _ in
								imageEditor.setColorChannel()
							   }
			)
	}
	
	private func bindingMultipleValues(for control: SingleSliderFilterControl) ->  [Binding<CGFloat>] {
		var bindingValues = [Binding<CGFloat>]()
		
		(0..<4).forEach { index in
			bindingValues.append(
				Binding<CGFloat> {
					if control == .brightness {
						let sum = editingState.control.colorChannelControl.values.reduce(0) { $0 + $1[index] }
						return sum/3
					}else {
						return editingState.control.colorChannelControl[currentColorControl]![index]
					}
				} set: { value in
					if control == .brightness {
						[ColorChannel.InputParameter.Component.red, .green, .blue].forEach { key in
							editingState.control.colorChannelControl[key]![index] = value
						}
					} else {
						editingState.control.colorChannelControl[currentColorControl]![index] = value
					}
				}
			)
		}
		return bindingValues
	}
	
	
	private func bindingSliderValue(for control: SingleSliderFilterControl) -> Binding<CGFloat> {
		
		switch control {
			case .brightness, .contrast, .saturation:
				return .init {
					editingState.control.colorControl[control]!
				} set: {
					editingState.control.colorControl[control] = $0
				}
			case .painter:
				return $editingState.control.painterRadius
			case .backgroundTone:
				return $editingState.control.depthFocus
			case .glitter:
				return .init {
					1 - editingState.control.thresholdBrightness
				} set: {
					editingState.control.thresholdBrightness = 1 - $0
				}

		}
	}
	
	private func drawGradientBar(for control: SingleSliderFilterControl) -> some View {
		let colors: [Color]
		if control == .brightness {
			colors = [.black, .white]
		}else {
			switch currentColorControl {
				case . red:
					colors = [.init(red: Double(64/255), green: 0, blue: 0), .init(red: 1, green: 0, blue: 0)]
				case .blue:
					colors = [.init(red: 0, green: 0, blue: Double(64/255)), .init(red: 0, green: 0, blue: 1)]
				case .green:
					colors = [.init(red: 0, green: Double(64/255), blue: 0), .init(red: 0, green: 1, blue: 0)]
				default:
					colors = []
			}
		}
		return LinearGradientBar(cornerRadius: 30, colors: colors)
			.padding(.top, -5)
	}
	
	@State private var isShowingCustomGlitter = false
	private var glitterControls: some View {
		Group {
			if isShowingCustomGlitter {
				HStack {
					customGlitterControls
						.frame(width: size.height * Constant.customGlitterControlSize,
							   height: size.height * Constant.customGlitterControlSize)
					Button {
						withAnimation {
							isShowingCustomGlitter = false
						}
						editingState.control.glitterAnglesAndRadius = customAngleAndRadius
						imageEditor.setGlitter()
					} label: {
						Text("Done")
					}
					Button {
						customAngleAndRadius = [:]
					} label: {
						Text("Reset")
							.foregroundColor(.red)
					}
				}
			}
			else {
				MenuScrollView(menus: glitterFilterMenus, tapMenu: tapGlitterMenu(_:))
			}
		}
	}
	
	private var glitterFilterMenus: [MenuScrollView.Menu] {
		[.init(title: "Custom",
			   filterImage: customAngleAndRadius.isEmpty ? UIImage(systemName: "slider.vertical.3")!:
			imageEditor.createGlitterPreview(for: customAngleAndRadius, in: Glitter.presetImageSize))] +
		editingState.glitterPresetImages.enumerated().map { index, image in
			.init(title: "Sample\(index + 1)", filterImage: image)
		}
	}
	
	private func tapGlitterMenu(_ menu: MenuScrollView.Menu) {
		guard let index = glitterFilterMenus.firstIndex(where: { $0.title == menu.title}) else {
			return
		}
		if index == 0 {
			withAnimation {
				isShowingCustomGlitter = true
			}
		}
		else {
			withAnimation {
				isShowingCustomGlitter = false
			}
			editingState.control.glitterAnglesAndRadius = Glitter.presetAngleAndRadius[index - 1]
			imageEditor.setGlitter()
		}
	}
	
	@State private var customAngleAndRadius = [CGFloat:CGFloat]()
	private var customGlitterControls: some View {
		CircularSlider(
			anglesAndRadius: $customAngleAndRadius,
			handleValueChanged:  {
				
			}, backgroundView: customGlitterBackground ) { size in
			Image(systemName: "plus.circle")
				.resizable()
				.renderingMode(.template)
				.foregroundColor(.white)
				.frame(width: size.width, height: size.height)
				.clipShape(Circle())
		}
	}
	private var customGlitterBackground: some View {
		let previewImage = imageEditor.createGlitterPreview(
			for: customAngleAndRadius,
			in: CGSize(width: size.height * Constant.customGlitterControlSize,
					   height: size.height * Constant.customGlitterControlSize))
		return Image(uiImage: previewImage)
	}
	
	private struct Constant {
		static let referenceHeight = DesignConstant.referenceSize.height
		static let verticalSlidersHeight: CGFloat = 159/referenceHeight
		static let gradientBarHeight: CGFloat = 21/referenceHeight
		static let subCategoryButtonSize = CGSize(width: 30, height: 30)
		static let customGlitterControlSize: CGFloat = 0.2
	}
	
}
