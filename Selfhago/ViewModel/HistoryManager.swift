//
//  HistoryManager.swift
//  moody
//
//  Created by bart Shin on 16/07/2021.
//

import UIKit

class HistoryManager {
	
	private(set) var imageHistory: [CIImage]
	/// Original Image and results  by not tunable filters
	private var sourceImages: [CIImage]
	/// Suquence of used filters
	private(set) var filterHistory: [FilterState]
	/// Filter index for undo or redo
	private(set) var nextFilterIndex: Int
	private var currentImageIndex: Int {
		nextFilterIndex
	}
	private(set) var undoAble: Bool
	private(set) var redoAble: Bool
	
	var sourceImage: CIImage {
		sourceImages.last ?? CIImage()
	}
	
	var lastImage: CIImage {
		imageHistory[currentImageIndex]
	}
	
	func clearHistory() {
		filterHistory = []
		imageHistory = []
		sourceImages = []
		nextFilterIndex = 0
		setRedoAndUndo()
	}
	
	func reset() {
		filterHistory = []
		imageHistory = sourceImages.first == nil ? []: [sourceImages.first!]
		sourceImages = sourceImages.first == nil ? []: [sourceImages.first!]
		nextFilterIndex = 0
		setRedoAndUndo()
	}
	
	func setImage(_ image: CIImage) {
		sourceImages = [image]
		imageHistory = [image]
	}
	
	func undo() -> FilterState {
		nextFilterIndex -= 1
		let state = filterHistory[nextFilterIndex]
		if state.filter.isUnmanaged {
			sourceImages.append(lastImage)
		}
		setRedoAndUndo()
		return state
	}
	
	func redo() -> FilterState {
		nextFilterIndex += 1
		let state = filterHistory[nextFilterIndex - 1]
		if state.filter.isUnmanaged {
			sourceImages.append(lastImage)
		}
		setRedoAndUndo()
		return state
	}
	
	private func setRedoAndUndo() {
		redoAble = filterHistory.count > nextFilterIndex
		undoAble = nextFilterIndex > 0
	}
	
	func createState(for filter: CIFilter, specificKey: String = "") -> FilterState {
		guard var state = FilterState(from: filter) ?? FilterState(by: specificKey) else {
			assertionFailure("Fail to create state for \(filter) with key \(specificKey)")
			return FilterState.unManagedFilter
		}
		if let lastState = filterHistory.last,
		   lastState.filter == state.filter{
			state.beforeState = lastState.beforeState
		}else {
			let currentState = state.getState(from: filter)
			state.beforeState = currentState
		}
		return state
	}
	
	func writeHistory(filter: CIFilter, state: FilterState, image: CIImage) {
		var state = state
		state.afterState = state.getState(from: filter)
		if state.filter.isUnmanaged {
			sourceImages.append(image)
		}
		if filterHistory.isEmpty ||
			(filterHistory.count == nextFilterIndex && filterHistory[nextFilterIndex - 1].filter != state.filter) {
			imageHistory.append(image)
			filterHistory.append(state)
		}
		else if nextFilterIndex != 0 && filterHistory[nextFilterIndex - 1].filter == state.filter {
			// Changing last Not correspond to unmanaged filters
			imageHistory[currentImageIndex] = image
			nextFilterIndex -= 1
			filterHistory[nextFilterIndex] = state
		}
		else {
			// Write new history at medium
			filterHistory[nextFilterIndex] = state
			imageHistory[currentImageIndex + 1] = image
			
			filterHistory.removeLast(filterHistory.count - nextFilterIndex - 1)
			imageHistory.removeLast(imageHistory.count - currentImageIndex - 2)
		}
		
		nextFilterIndex += 1
		setRedoAndUndo()
	}
	
	init() {
		imageHistory = []
		sourceImages = []
		filterHistory = []
		nextFilterIndex = 0
		undoAble = false
		redoAble = false
	}
	struct FilterState {
		
		static let unManagedFilter = FilterState()
		
		enum Filter: String {
			case ColorChannel
			case Bilateral
			case Kuwahara
			case LUTCube
			case SobelEdgeDetection3x3
			case Vignette
			case Glitter
			case brightness
			case saturation
			case contrast
			case KuwaharaMetal
			case BackgroundToneRetouch
			
			case unManaged
			
			static func ==(lhs: Filter, rhs: Filter) -> Bool {
				if lhs.rawValue == "unManaged" || rhs.rawValue == "unManaged" {
					return false
				}else {
					return lhs.rawValue == rhs.rawValue
				}
			}
			
			var isUnmanaged: Bool {
				self.rawValue == "unManaged"
			}
		}
		
		let filter: Filter
		var beforeState = [String: Any]()
		var afterState = [String: Any]()
		
		fileprivate func getState(from ciFilter: CIFilter) -> [String: Any] {
			
			let keys: [String]
			switch filter {
				case .brightness, .contrast, .saturation:
					keys = [kCIInputBrightnessKey, kCIInputContrastKey, kCIInputSaturationKey]
				case .Bilateral:
					keys = [kCIInputRadiusKey, kCIInputIntensityKey]
				case .ColorChannel:
					keys = ["red", "blue", "green", "averageLumiance"]
				case .LUTCube:
					keys = [kCIInputMaskImageKey]
				case .SobelEdgeDetection3x3:
					keys = [kCIInputBiasKey, kCIInputWeightsKey, kCIInputScaleKey]
				case .Vignette:
					keys = [kCIInputIntensityKey, kCIInputRadiusKey,
					kCIInputBrightnessKey]
				case .Glitter:
					keys = [ kCIInputBrightnessKey, kCIInputAngleKey ]
				case .Kuwahara, .KuwaharaMetal:
					keys = [ kCIInputRadiusKey ]
				case .BackgroundToneRetouch:
					keys = [ kCIInputIntensityKey ]
				case .unManaged:
					return [:]
			}
			return extractState(of: ciFilter, by: keys)
		}
		
		private func extractState(of filter: CIFilter, by keys: [String]) -> [String: Any] {
			keys.reduce(into: [:]) { state, key in
				state[key] = filter.value(forKey:key)
			}
		}
		
		init?(from filter: CIFilter) {
			if let filterName = filter.attributes[kCIAttributeFilterName] as? String,
			   let filter = Filter(rawValue: filterName){
				self.filter = filter
			}else {
				return nil
			}
		}
		
		init?(by key: String) {
			if let filter = Filter(rawValue: key){
				self.filter = filter
			}else {
				return nil
			}
		}
		
		fileprivate init() {
			self.filter = .unManaged
		}
		
	}
}
