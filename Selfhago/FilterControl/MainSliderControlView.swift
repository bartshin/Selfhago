//
//  MainSliderControlView.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/06.
//

import SwiftUI
import SwiftUICharts

struct MainSliderControlView: View {
	
	@EnvironmentObject var imageEditor: ImageEditor
	@EnvironmentObject var editingState: EditingState
	@State private var charts: ChartState?
	
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
			HorizontalSliderView(title: title, value: bindingSingleValue, in: range) {
				onMainValueChange()
			}
			if control == .brightness{
				gammaControls
			}
			else if control == .contrast {
				contrastControls
			}
			else if control == .saturation {
				colorChannelControls
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
	
	@State private var selectedIndex = 1
	private var isControlLinear: Bool {
		selectedIndex == 0
	}
	
	private var gammaControls: some View {
		ZStack {
			let bindingValues = bindingValues
			let ranges: [ClosedRange<CGFloat>] = (0..<bindingValues.count).map { index in
				MultiSliderFilterControl.gamma.getRange(for: isControlLinear ? index + 4: index)
			}
			chartsGraph
			VerticalSliderView(title: MultiSliderFilterControl.gamma.labelStrings[LocaleManager.currentLanguageCode.rawValue],
							   values: bindingValues,
							   ranges: ranges,
							   drawGraph: false)
			MovingSegmentButton(isHorizontal: true,
								buttonPosition: segmentPosition,
								buttons: [
									getSegmentButton(for: 0),
									getSegmentButton(for: 1)
								],
								selectedIndexBinding: $selectedIndex)
		}
		.frame(height: size.height * Constant.verticalSlidersHeight)
		.onAppear {
			charts = ChartState(values: imageEditor.setGamma())
		}
	}
	
	private var chartsGraph: some View {
		Group {
			if charts != nil {
				let chartsHeight = size.height * Constant.verticalSlidersHeight * 0.8
				LineChart()
					.data(charts!.values)
					.chartStyle(charts!.style)
					.allowsHitTesting(false)
					.frame(height: chartsHeight)
					.offset(y: chartsHeight * min(max(-charts!.minValue + 0.2, -0.5), 0.3))
			}
		}.onChange(of: editingState.control.gammaParameter) { _ in
			charts = ChartState(values: imageEditor.setGamma())
		}
	}
	
	private var segmentPosition: Binding<CGPoint> {
		.init{
			CGPoint(x: Double(editingState.control.gammaParameter.linearBoundary),
					y: 0.1)
		} set: {
			editingState.control.gammaParameter.linearBoundary = Float($0.x)
		}
	}
	
	private func getSegmentButton(for index: Int) -> some View {
		let languageCode = LocaleManager.currentLanguageCode
		return Group {
			ZStack {
				RoundedRectangle(cornerRadius: 20)
					.fill(DesignConstant.getColor(for: .background))
				HStack {
					if index == 0 {
						Image(systemName: "chevron.left")
							.renderingMode(.template)
						Text(LocaleManager.currentLanguageCode == .en ? "Linear": "선형")
							.font(.caption)
					}else {
						Text(languageCode == .en ? "Exponential": "지수형")
							.font(.caption)
						Image(systemName: "chevron.right")
							.renderingMode(.template)
					}
				}
				.foregroundColor(DesignConstant.getColor(for: .primary, isDimmed: index != selectedIndex))
			}
		}
	}
	
	private var contrastControls: some View {
		DragableGraph(values: $editingState.control.contrastControls,
					  lineColor: .blue,
					  pointColor: DesignConstant.getColor(for: .primary),
					  backgroundView: DesignConstant.getColor(for: .background)) {
			editingState.brightnessMap = $0
			imageEditor.setLabAdjust()
		}
			.frame(height: 200)
	}
	
	private var colorChannelControls: some View {
		Group {
			Divider()
				.frame(height: 1)
				.background(Color.black)
			HStack {
				rgbSelectButtons
				colorChannelSliders
					.frame(height: size.height * Constant.verticalSlidersHeight)
			}
			gradientBar
				.frame(width: size.width * 0.9,
					   height: size.height * Constant.gradientBarHeight)
		}
	}
	
	
	@State private var isShowingImagePicker = false
	private var imageSelectView: some View {
		Group {
			if let depthDataAvailable = editingState.depthDataAvailable {
				if depthDataAvailable {
					MenuScrollView(menus: toneImageMenus, tapMenu: tapToneMenu(_:))
						.sheet(isPresented: $isShowingImagePicker) {
							ImagePicker(passImage: imageEditor.setMaterialImage(_:))
						}
				}
				else {
					Text("Need depth data Please pick potrait photo")
						.font(.subheadline)
				}
			}else {
				Text("Loading...")
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
	
	private func onMainValueChange() {
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
						Circle()
							.fill(Color(inputComponent.representingColor))
							.frame(width: Constant.subCategoryButtonSize.width,
								   height: Constant.subCategoryButtonSize.height)
							.overlay(Circle()
										.size(width: Constant.subCategoryButtonSize.width - 4,
											  height: Constant.subCategoryButtonSize.height - 4)
										.fill(inputComponent == currentColorControl ? .clear: DesignConstant.getColor(for: .background))
										.offset(x: 2, y: 2)
							)
							
					}
				}
			}
	}
	private var colorChannelSliders: some View {
		let language = LocaleManager.currentLanguageCode
		let colorControl = MultiSliderFilterControl(rawValue: currentColorControl.rawValue)!
		let title = colorControl.labelStrings[language.rawValue]
		let bindingValues = bindingValues
		let ranges: [ClosedRange<CGFloat>] = (0..<bindingValues.count).map { index in
			MultiSliderFilterControl.red.getRange(for: 0)
		}
		return
			VerticalSliderView(title: title,
							   values: bindingValues,
							   ranges: ranges,
							   drawGraph: true)
	}
	
	private var bindingValues: [Binding<CGFloat>] {
		if control == .brightness {
			if isControlLinear {
				return (0...editingState.control.gammaParameter.linearCoefficients.count-1).compactMap {
					convertBindingToCGFloat($editingState.control.gammaParameter.linearCoefficients[$0])
				}
			} else {
				return [
					convertBindingToCGFloat($editingState.control.gammaParameter.inputGamma)
				] +
				(0...editingState.control.gammaParameter.exponentialCoefficients.count-1).compactMap{
					convertBindingToCGFloat($editingState.control.gammaParameter.exponentialCoefficients[$0])
				}
			}
		}
		else if control == .saturation {
			var bindingValues = [Binding<CGFloat>]()
			(0..<4).forEach { index in
				bindingValues.append(
					Binding<CGFloat> {
						editingState.control.colorChannelControl[currentColorControl]![index]
					} set: { value in
						editingState.control.colorChannelControl[currentColorControl]![index] = value
						imageEditor.setColorChannel()
					}
				)
			}
			return bindingValues
		}else {
			fatalError()
		}
		
	}
	
	private func convertBindingToCGFloat<T>(_ binding: Binding<T>) -> Binding<CGFloat> where T: BinaryFloatingPoint {
		Binding<CGFloat> {
			CGFloat(binding.wrappedValue)
		} set: {
			binding.wrappedValue = T($0)
		}
	}
	
	
	private var bindingSingleValue: Binding<CGFloat> {
		
		switch control {
			case .brightness, .contrast, .saturation:
				return .init {
					editingState.control.ciColorControl[control]!
				} set: {
					editingState.control.ciColorControl[control] = $0
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
	
	private var gradientBar: some View {
		let colors: [Color]
		switch currentColorControl {
			case . red:
				colors = [.init(red: Double(64/255), green: 0, blue: 0), .init(red: 1, green: 0, blue: 0)]
			case .blue:
				colors = [.init(red: 0, green: 0, blue: Double(64/255)), .init(red: 0, green: 0, blue: 1)]
			case .green:
				colors = [.init(red: 0, green: Double(64/255), blue: 0), .init(red: 0, green: 1, blue: 0)]
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
		static let graphHeight: CGFloat = 50/referenceHeight
	}
	
}
