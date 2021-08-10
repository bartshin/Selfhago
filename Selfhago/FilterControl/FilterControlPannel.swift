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
			drawSliderControls(for: drawableFilter)
		}else if let onOffFilter = category.control as? OnOffFilter {
			drawOnOffControl(for: onOffFilter)
		}else if let multiSliderFilter = category.control as? MultiSliderFilterControl {
			drawMultiSliderControl(for: multiSliderFilter)
		}
    }
	
	private func drawSliderControls(for filter: DrawableFilterControl) -> some View {
		VStack {
			Text(filter.labelStrings[LocaleManager.currentLanguageCode.rawValue])
			HStack {
				Text("Intensity")
				Slider(value: Binding<CGFloat> {
					editingState.control.blurIntensity
				} set: {
					editingState.control.blurIntensity = $0
				}, in: 0...20, step: 1)
			}
			HStack {
				Text("Radius")
				Slider(value:Binding<CGFloat> {
					editingState.control.blurMaskWidth
				} set: {
					editingState.control.blurMaskWidth = $0
				}, in: 10...60, step: 5)
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
			case .textStamp:
				break
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
					Image(uiImage: preset.label)
						.resizable()
						.renderingMode(.template)
						.frame(width: Constant.subCategoryButtonSize.width,
							   height: Constant.subCategoryButtonSize.height)
						.foregroundColor(preset == currentPreset ? .blue: .black)
				}
			}
		}
	}
	
	private var presetFilterMenus: [MenuScrollView.Menu] {
		
		return
			currentPreset.luts.map { lutName in
				let iconImage = editingState.presetThumnails[lutName] ?? DesignConstant.presetFilterImage
			return .init(title: lutName, filterImage: iconImage)
		}
	}
	
	private struct Constant {
		static let referenceHeight: CGFloat = DesignConstant.referenceSize.height
		static let subCategoryButtonSize = CGSize(width: 30, height: 30)
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
