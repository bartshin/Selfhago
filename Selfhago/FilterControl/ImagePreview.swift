//
//  ImagePreview.swift
//  moody
//
//  Created by bart Shin on 24/06/2021.
//

import SwiftUI
import PencilKit

struct ImagePreview: View, TextImageProvider {

	@Environment(\.colorScheme) var colorScheme
	@EnvironmentObject var imageEditor: ImageEditor
	@EnvironmentObject var editingState: EditingState
	@Binding var currentCategory: FilterCategory<Any>?
	@StateObject private var gestureDelegate = GestureDelegate()
	
	private var image: UIImage {
		if let image = imageEditor.uiImage {
			gestureDelegate.imageSize = image.size
			return image
		}
		else {
			return UIImage()
		}
	}
	
	private var isUsingPanningControl: Bool {
		currentCategory != nil && currentCategory!.control is DrawableFilterControl
	}
	
	var body: some View {
		if imageEditor.uiImage != nil {
			GeometryReader { geometry in
				drawImage(in: geometry.size)
					.scaleEffect(zoomScale)
					.position(x: geometry.size.width / 2 + gestureDelegate.panOffset.width,
							  y: geometry.size.height / 2 + gestureDelegate.panOffset.height)
					.gesture(createGesture(in: geometry.size))
					.allowsHitTesting(!isUsingPanningControl)
					.clipped()
					.onChange(of: currentCategory) { _ in
						if currentCategory == nil {
							gestureDelegate.zoomToFit(for: geometry.size)
						}
					}
			}
		}
	}
	
	private func drawImage(in size: CGSize) -> some View {
		Image(uiImage: image)
			.aspectRatio(contentMode: .fit)
			.onAppear {
				guard !editingState.isRecording else {
					return
				}
				editingState.control.blurMaskWidth = min(60 / gestureDelegate.zoomScale, 60)
				gestureDelegate.geometrySize = size
				gestureDelegate.zoomToFit(for: size, animated: false)
				gestureDelegate.textLabelPosition = CGPoint(x: image.size.width/2, y: image.size.height/2)
				imageEditor.textImageProvider = self
			}
			.onReceive(editingState.$isRecording) {
				if $0 {
					gestureDelegate.zoomToFit(for: size)
				}
			}
			.overlay(drawOverLayView(in: size).clipped())
	}
	
	private func drawOverLayView(in size: CGSize) -> some View {
		Group {
			if let category = currentCategory{
				if category.subCategory == DrawableFilterControl.mask.rawValue{
					blurmaskView
						.allowsHitTesting(isUsingPanningControl)
				}
				if category.subCategory == MultiSliderFilterControl.textStamp.rawValue {
					textArrangeView
						.gesture(gestureDelegate.createDragTextGesture(in: size))
				}
			}
		}
	}
	
	private var textArrangeView: some View {
		
		let font = Font(UIFont(descriptor: editingState.control.textStampFont.descriptor,
										  size: editingState.control.textStampFont.fontSize/zoomScale))
		return
			Text(editingState.control.textStampContent)
			.font(font)
			.foregroundColor(Color(editingState.control.textStampColor))
			.opacity(Double(editingState.control.textStampControl.opacity))
			.rotationEffect(Angle(radians: Double(editingState.control.textStampControl.rotation)))
			.position(gestureDelegate.textLabelPosition)
	}
	
	func provideTextImage() -> UIImage {
		ZStack {
			Color.clear
				.overlay(
					textArrangeView
			)
		}
		.frame(width: image.size.width,
			   height: image.size.height)
		.snapshot()
	}
	
	private var blurmaskView: some View {
		let colorScheme = UIApplication.shared.windows.first?.traitCollection.userInterfaceStyle
		return Group {
			if colorScheme == .dark {
				BlurMaskView(canvas: imageEditor.drawingMaskView, markerWidth: $editingState.control.blurMaskWidth, gestureDelegate: gestureDelegate)
				.colorInvert()
			}else {
				BlurMaskView(canvas: imageEditor.drawingMaskView, markerWidth: $editingState.control.blurMaskWidth, gestureDelegate: gestureDelegate)
			}
		}
	}
	
	private func createGesture(in size: CGSize) -> some Gesture {
		gestureDelegate.createPanGesture(in: size)
			.simultaneously(with: gestureDelegate.createZoomGesture(in: size, with: $viewGestureZoomScale))
			.simultaneously(with: gestureDelegate.createTapGesture(
								in: size, count: editingState.isRecording ? 1: 2,
								category: $currentCategory))
	}
	
	//MARK:- Zooming
	@State var fixedZoomScale: CGFloat = 1
	@GestureState var viewGestureZoomScale: CGFloat = 1
	private var zoomScale: CGFloat {
		gestureDelegate.zoomScale * viewGestureZoomScale
	}
}

class GestureDelegate: NSObject, ObservableObject, UIGestureRecognizerDelegate {
	
	var imageSize: CGSize = .zero {
		didSet {
			
		}
	}
	var geometrySize: CGSize = .zero
	var zoomScale: CGFloat {
		fixedZoomScale * gestureZoomScale
	}
	@Published var fixedZoomScale: CGFloat = 1
	@Published var gestureZoomScale: CGFloat = 1
	var panOffset: CGSize {
		CGSize(width: (fixedPanOffset.width + gesturePanOffset.width) * zoomScale,
			   height: (fixedPanOffset.height + gesturePanOffset.height) * zoomScale)
	}
	@Published var fixedPanOffset = CGSize.zero
	@Published var gesturePanOffset = CGSize.zero
	@Published var textLabelPosition = CGPoint.zero
	
	private(set) lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = {
		let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchImage(_:)))
		pinchGesture.delegate = self
		return pinchGesture
	}()
	
	private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = {
		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panImage(_:)))
		panGesture.minimumNumberOfTouches = 2
		panGesture.delegate = self
		return panGesture
	}()
	
	private(set) lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
		tapGesture.delegate = self
		tapGesture.numberOfTouchesRequired = 2
		tapGesture.numberOfTapsRequired = 2
		return tapGesture
	}()
	
	@objc private func doubleTap() {
		let defaultScale = getScaleToFit(imageSize: imageSize, in: geometrySize)
		if defaultScale == zoomScale {
			withAnimation {
				fixedZoomScale = defaultScale * 2
			}
		}else {
			zoomToFit(for: geometrySize)
		}
	}
	
	func createPanGesture(in size: CGSize) -> some Gesture {
		DragGesture()
			.onChanged { [self] gestureValue in
				guard zoomScale > getScaleToFit(imageSize: imageSize, in: size) else {
					return
				}
				gesturePanOffset = CGSize(
					width: gestureValue.translation.width / zoomScale,
					height: gestureValue.translation.height / zoomScale)
			}
			.onEnded { [self] endValue in
				guard let panableSpace = calcPanableSpace(imageSize: imageSize, in: size) else {
					return
				}
				gesturePanOffset = .zero
				fixedPanOffset = CGSize(
					width: fixedPanOffset.width + endValue.translation.width / zoomScale,
					height: fixedPanOffset.height + endValue.translation.height / zoomScale)
				
				if checkExceedEdge(in: panableSpace) {
					withAnimation {
						fixedPanOffset = calcMaxiumOffset(in: panableSpace)
					}
				}
			}
	}
	
	func createZoomGesture(in size: CGSize, with gestureZoomScale: GestureState<CGFloat>) -> some Gesture {
		MagnificationGesture()
			.updating(gestureZoomScale) { lastScale, gestureZoomScale, _ in
				gestureZoomScale = lastScale
			}
			.onEnded { [self] scale in
				let defaultScale = getScaleToFit(imageSize: imageSize, in: size)
				fixedZoomScale *= scale
				if defaultScale > zoomScale {
					withAnimation (.easeIn(duration: 0.3)) {
						fixedZoomScale = defaultScale
						fixedPanOffset = .zero
					}
				}
			}
	}
	
	func createTapGesture(in size: CGSize, count: Int, category: Binding<FilterCategory<Any>?>) -> some Gesture {
		TapGesture(count: count)
			.onEnded { [self] in
				if count == 1 {
					withAnimation {
						category.wrappedValue = nil
					}
				}
				else {
					let defaultScale = getScaleToFit(imageSize: imageSize, in: size)
					if defaultScale == zoomScale {
						withAnimation {
							fixedZoomScale = defaultScale * 2
						}
					}else {
						zoomToFit(for: size)
					}
				}
			}
	}
	
	func createDragTextGesture(in size: CGSize) -> some Gesture {
		DragGesture()
			.onChanged { gestureValue in
				self.textLabelPosition = gestureValue.location
			}
	}
	
	func zoomToFit(for size: CGSize, animated: Bool = true) {
		if animated {
			withAnimation {
				fixedPanOffset = .zero
				fixedZoomScale = getScaleToFit(imageSize: imageSize, in: size)
			}
		}else {
			fixedPanOffset = .zero
			fixedZoomScale = getScaleToFit(imageSize: imageSize, in: size)
		}
	}

	@objc private func pinchImage(_ pinchGesture: UIPinchGestureRecognizer) {
		switch pinchGesture.state {
			case .began:
				gestureZoomScale = 1
			case .changed:
				gestureZoomScale = pinchGesture.scale
			case .ended:
				let defaultScale = getScaleToFit(imageSize: imageSize, in: geometrySize)
				fixedZoomScale *= gestureZoomScale
				gestureZoomScale = 1
				if defaultScale > zoomScale {
					withAnimation (.easeIn(duration: 0.3)){
						fixedZoomScale = defaultScale
						fixedPanOffset = .zero
					}
				}
			default:
				fixedZoomScale *= gestureZoomScale
				gestureZoomScale = 1
		}
	}
	
	@objc private func panImage(_ panGesture: UIPanGestureRecognizer) {
		guard let view = panGesture.view else {
			return
		}
		
		switch panGesture.state {
			case .began:
				gesturePanOffset = .zero
			case .changed:
				guard zoomScale > getScaleToFit(imageSize: imageSize, in: geometrySize) * 1.2 else {
					return
				}
				let translation = panGesture.translation(in: view)
				gesturePanOffset = CGSize(
					width: translation.x ,
					height: translation.y )
			case .ended:
				let endValue = panGesture.translation(in: view)
				guard let panableSpace = calcPanableSpace(imageSize: imageSize, in: geometrySize) else {
					return
				}
				gesturePanOffset = .zero
				fixedPanOffset = CGSize(
					width: fixedPanOffset.width + endValue.x,
					height: fixedPanOffset.height + endValue.y)
				
				if checkExceedEdge(in: panableSpace) {
					withAnimation {
						fixedPanOffset = calcMaxiumOffset(in: panableSpace)
					}
				}
			default:
				break
		}
	}
	
	func getScaleToFit(imageSize: CGSize, in size: CGSize) -> CGFloat {
		let horizontal = size.width / imageSize.width
		let vertical = size.height / imageSize.height
		return min(horizontal, vertical)
	}
	
	func calcPanableSpace(imageSize: CGSize, in viewSize: CGSize) -> CGSize? {
		let defaultZoomScale = getScaleToFit(imageSize: imageSize, in: viewSize)
		guard zoomScale >  defaultZoomScale else {
			return nil
		}
		return CGSize(
			width: imageSize.width * (zoomScale - defaultZoomScale) / 2,
			height: imageSize.height * (zoomScale - defaultZoomScale) / 2)
	}
	
	func checkExceedEdge(in panableSpace: CGSize) -> Bool {
		abs(panOffset.width) > panableSpace.width ||
			abs(panOffset.height) > panableSpace .height
	}
	
	func calcMaxiumOffset(in panableSpace: CGSize) -> CGSize {
		let currentOffset = panOffset
		let horizontal: CGFloat
		let vertical: CGFloat
		if abs(currentOffset.width) > panableSpace.width {
			horizontal = panableSpace.width * (currentOffset.width < 0 ? -1: 1)
		}else {
			horizontal = currentOffset.width
		}
		if abs(panOffset.height) > panableSpace.height {
			vertical = panableSpace.height * (currentOffset.height < 0 ? -1: 1)
		}else {
			vertical = currentOffset.height
		}
		return CGSize(width: horizontal / zoomScale, height: vertical / zoomScale)
	}
	
	fileprivate override init() {
		super.init()
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		true
	}
}

#if DEBUG
struct ImagePreview_Previews: PreviewProvider {
	static var previews: some View {
		ImagePreview(currentCategory: .constant(FilterCategory(rawValue: SingleSliderFilterControl.brightness.rawValue)!))
			.environmentObject(ImageEditor.forPreview)
	}
}
#endif

