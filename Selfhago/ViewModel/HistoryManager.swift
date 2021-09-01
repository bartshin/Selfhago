//
//  HistoryManager.swift
//  Selfhago
//
//  Created by bart Shin on 16/07/2021.
//

import UIKit
import SwiftUI

class HistoryManager {
	
	private(set) var imageHistory: [CIImage]
	/// Original Image and results  by not tunable filters
	private var sourceImages: [CIImage]
	/// Suquence of used filters
	private(set) var filterStateHistory: [FilterState]
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
	
	var currentImage: CIImage {
		imageHistory[currentImageIndex]
	}
	
	var previousImage: CIImage? {
		currentImageIndex > 0 ? imageHistory[currentImageIndex - 1]: nil
	}
	
	private(set) var lastFilter: CIFilter?
	var imageWithoutCurrentFilter: CIImage?
	private var currentState: FilterState?
	
	func clearHistory() {
		filterStateHistory = []
		imageHistory = []
		sourceImages = []
		nextFilterIndex = 0
		setRedoAndUndo()
		imageWithoutCurrentFilter = nil
		lastFilter = nil
		currentState = nil
	}
	
	func reset() {
		filterStateHistory = []
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
		let state = filterStateHistory[nextFilterIndex]
		if state.filter.isUnmanaged {
			sourceImages.append(currentImage)
		}
		setRedoAndUndo()
		return state
	}
	
	func redo() -> FilterState {
		nextFilterIndex += 1
		let state = filterStateHistory[nextFilterIndex - 1]
		if state.filter.isUnmanaged {
			sourceImages.append(currentImage)
		}
		setRedoAndUndo()
		return state
	}
	
	func isCurrentEditingFilter(_ filter: CIFilter) -> Bool {
		if filter == lastFilter {
			return true
		}else {
			lastFilter = filter
			return false
		}
	}
	
	func changeCurrentState(for filter: CIFilter, specificKey: String? = nil) {
		guard var state = FilterState(from: filter) ?? FilterState(by: specificKey!) else {
			assertionFailure("Fail to create state for \(filter) with key \(specificKey ?? "none")")
			currentState = FilterState.unManagedFilter
			return
		}
		if let lastState = filterStateHistory.last,
		   lastState.filter == state.filter{
			state.beforeState = lastState.beforeState
		}else {
			let currentState = state.captureState(from: filter)
			state.beforeState = currentState
		}
		currentState = state
	}
	
	func detachCurrentState() -> FilterState? {
		if let state = currentState {
			return state
		}else {
			return nil
		}
	}
	
	func writeHistory(filter: CIFilter, state: FilterState, image: CIImage) {
		
		lastFilter = nil
		if state.filter.isUnmanaged {
			sourceImages.append(image)
		}
		if filterStateHistory.isEmpty ||
			(filterStateHistory.count == nextFilterIndex && filterStateHistory[nextFilterIndex - 1].filter != state.filter) {
			imageHistory.append(image)
			filterStateHistory.append(state)
		}
		else if nextFilterIndex != 0 && filterStateHistory[nextFilterIndex - 1].filter == state.filter {
			// Changing last Not correspond to unmanaged filters
			imageHistory[currentImageIndex] = image
			nextFilterIndex -= 1
			filterStateHistory[nextFilterIndex] = state
		}
		else {
			// Write new history at medium
			filterStateHistory[nextFilterIndex] = state
			imageHistory[currentImageIndex + 1] = image
			
			filterStateHistory.removeLast(filterStateHistory.count - nextFilterIndex - 1)
			imageHistory.removeLast(imageHistory.count - currentImageIndex - 2)
		}
		
		nextFilterIndex += 1
		setRedoAndUndo()
	}
	
	private func setRedoAndUndo() {
		redoAble = filterStateHistory.count > nextFilterIndex
		undoAble = nextFilterIndex > 0
	}
	
	
	init() {
		imageHistory = []
		sourceImages = []
		filterStateHistory = []
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
			case perspective
			case BackgroundToneRetouch
			case Sketch
			case GammaAdjustment
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
		
		func captureState(from ciFilter: CIFilter) -> [String: Any] {
			
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
				case .Sketch:
					keys = [Sketch.thresholdKey, Sketch.noiseLevelKey, Sketch.edgeIntensityKey,
					kCIInputColorKey, kCIInputBackgroundImageKey]
				case .Vignette:
					keys = [kCIInputIntensityKey, kCIInputRadiusKey,
					kCIInputBrightnessKey]
				case .Glitter:
					keys = [ kCIInputBrightnessKey, kCIInputAngleKey ]
				case .Kuwahara, .KuwaharaMetal:
					keys = [ kCIInputRadiusKey ]
				case .BackgroundToneRetouch:
					keys = [ kCIInputIntensityKey ]
				case .perspective:
					keys = [ "inputTopLeft", "inputTopRight", "inputBottomLeft", "inputBottomRight" ]
				case .GammaAdjustment:
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
