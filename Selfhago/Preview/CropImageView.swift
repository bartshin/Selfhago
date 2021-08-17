//
//  CropImageView.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/11.
//

import SwiftUI

struct CropImageView: View {
	
	@Binding var viewFinderRect: CGRect
	private var viewFinderRatio: CGFloat?
	@State private var fixedViewFinderOffset: CGPoint
	@State private var fixedViewFinderSize: CGSize
	@State private var isDraggingViewFinder = false
	@State private var isdraggingCenter = false
	
	private let imageSize: CGSize
	private let dragRatio: CGFloat
	private let scale: CGFloat
	private let edgePadding: CGFloat = 80
	private let lineWidth: CGFloat

	private var viewFinderOffset: CGPoint {
		CGPoint(x: fixedViewFinderOffset.x + gestureViewFinderOffset.x,
			   y: fixedViewFinderOffset.y + gestureViewFinderOffset.y)
	}
	private var viewFinderSize: CGSize {
		CGSize(width: fixedViewFinderSize.width + gestureViewFinderSize.width,
			   height: fixedViewFinderSize.height + gestureViewFinderSize.height)
	}
	
	var body: some View {
			ZStack {
			
				GeometryReader { geometry in
					let frame = geometry.frame(in: .local)
					outerBlur
					ViewFinder( isDragging: $isDraggingViewFinder, size: viewFinderSize, lineWidth: lineWidth)
						.frame(width: viewFinderSize.width,
							   height: viewFinderSize.height)
						.position(x: frame.midX + viewFinderOffset.x,
								  y: frame.midY + viewFinderOffset.y)
					Rectangle()
						.fill(Color.clear)
						.contentShape(Rectangle())
						.frame(width: fixedViewFinderSize.width,
							   height: fixedViewFinderSize.height)
						.gesture(panningViewFinderGesture)
						.position(x: frame.midX + fixedViewFinderOffset.x,
								  y: frame.midY + fixedViewFinderOffset.y)
						.padding()
					ViewFinder.CenterCircle()
						.stroke(isDraggingViewFinder ? Color.white: Color.gray.opacity(0.4), lineWidth: lineWidth * (isdraggingCenter ? 3: 1))
						.aspectRatio(1, contentMode: .fit)
						.frame(width: viewFinderSize.width * 0.15,
							   height: viewFinderSize.height * 0.15)
						.position(x: frame.midX + viewFinderOffset.x,
								  y: frame.midY + viewFinderOffset.y)
				}
				.onChange(of: viewFinderRatio) { newValue in
					isdraggingCenter = true
					isDraggingViewFinder = true
					withAnimation (.easeOut(duration: 0.5)) {
						fixedViewFinderOffset = CGPoint(x: imageSize.width/2 - viewFinderRect.midX,
														y: imageSize.height/2 - viewFinderRect.midY)
						fixedViewFinderSize = viewFinderRect.size
					}
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						isDraggingViewFinder = false
						isdraggingCenter = false
					}
				}
		}
	}
	
	private var outerBlur: some View {
		let offset = viewFinderOffset
		let viewFinderSize = viewFinderSize
		let viewFinderInImageView = CGRect(
			origin:
				CGPoint(x: offset.x + (imageSize.width - viewFinderSize.width)/2,
						y: offset.y + (imageSize.height - viewFinderSize.height)/2),
			size: viewFinderSize)
		let blurColor = Color.black.opacity(isDraggingViewFinder ? 0.4: 0.6)
		let overlayMargin: CGFloat = 2
		
		return	GeometryReader { geometry in
			let frame = CGRect(x: 0, y: 0, width: geometry.size.width * 1/scale, height: geometry.size.height * 1/scale)
			let horizontalPadding = (frame.width - imageSize.width)/2
			let verticalPadding = (frame.height - imageSize.height)/2
			Group {
				Rectangle()
					.fill(blurColor)
					.frame(width: max(horizontalPadding + viewFinderInImageView.origin.x, 0),
						   height: frame.height)
					.offset(x:(viewFinderInImageView.minX - imageSize.width - horizontalPadding)/2)
				Rectangle()
					.fill(blurColor)
					.frame(width: viewFinderInImageView.width + overlayMargin,
						   height: max(verticalPadding + viewFinderInImageView.origin.y, 0))
					.offset(x: viewFinderInImageView.midX - imageSize.width/2 ,
							y: (viewFinderInImageView.minY - imageSize.height - verticalPadding)/2)
				Rectangle()
					.fill(blurColor)
					.frame(width: max(horizontalPadding + imageSize.width - viewFinderInImageView.maxX, 0),
						   height: frame.height)
					.offset(x: (viewFinderInImageView.maxX + horizontalPadding)/2, y: 0)
				Rectangle()
					.fill(blurColor)
					.frame(width: viewFinderInImageView.width + overlayMargin,
						   height: max(verticalPadding + imageSize.height - viewFinderInImageView.maxY, 0))
					.offset(x: viewFinderInImageView.midX - imageSize.width/2,
							y: (viewFinderInImageView.maxY + verticalPadding)/2)
			}
			.frame(width: frame.size.width,
				   height: frame.size.height)
			.position(x: geometry.size.width/2, y: geometry.size.height/2)
		}
		.blur(radius: isDraggingViewFinder ? 20: 0, opaque: false)
	}
	
	
	@State private var gestureViewFinderOffset: CGPoint = .zero
	@State private var gestureViewFinderSize: CGSize = .zero
	
	private var panningViewFinderGesture: some Gesture {
		DragGesture()
			.onChanged { dragValue in
				isDraggingViewFinder = true
				let startLocation = dragValue.startLocation
				
				let corner = determineCorner(from: startLocation)
				
				guard corner.isLeft || corner.isRight || corner.isTop || corner.isBottom else {
					gestureViewFinderOffset = CGPoint(x: dragValue.translation.width, y: dragValue.translation.height)
					isdraggingCenter = true
					return
				}
				let scaledTranslation = CGSize(width: dragValue.translation.width / dragRatio, height: dragValue.translation.height / dragRatio)
				let previousOffset = gestureViewFinderOffset
				let previousSize = gestureViewFinderSize
				
				if corner.isLeft {
					gestureViewFinderOffset.x = scaledTranslation.width
					gestureViewFinderSize.width = -scaledTranslation.width * 2
					if viewFinderOffset.x < -(imageSize.width - viewFinderSize.width)/2 {
						gestureViewFinderOffset.x = previousOffset.x
						gestureViewFinderSize.width = previousSize.width
					}
				}
				else if corner.isRight{
					gestureViewFinderOffset.x = scaledTranslation.width
					gestureViewFinderSize.width = scaledTranslation.width * 2
					if viewFinderOffset.x + viewFinderSize.width > imageSize.width {
						gestureViewFinderOffset.x = previousOffset.x
						gestureViewFinderSize.width = previousSize.width
					}
				}
				if (corner.isLeft || corner.isRight),
				   viewFinderRatio != nil {
					gestureViewFinderSize.height = gestureViewFinderSize.width * 1/viewFinderRatio!
					if viewFinderSize.height > imageSize.height {
						gestureViewFinderOffset = previousOffset
						gestureViewFinderSize = previousSize
					}
				}
				if corner.isTop {
					gestureViewFinderOffset.y = scaledTranslation.height
					gestureViewFinderSize.height = -scaledTranslation.height * 2
					if viewFinderOffset.y < -(imageSize.height - viewFinderSize.height)/2{
						gestureViewFinderOffset.y = previousOffset.y
						gestureViewFinderSize.height = previousSize.height
					}
				}
				else if corner.isBottom {
					gestureViewFinderOffset.y = scaledTranslation.height
					gestureViewFinderSize.height = scaledTranslation.height * 2
					if viewFinderOffset.y + viewFinderSize.height > imageSize.height {
						gestureViewFinderOffset.y = previousOffset.y
						gestureViewFinderSize.height = previousSize.height
					}
				}
				if (corner.isTop || corner.isBottom),
				   viewFinderRatio != nil {
					gestureViewFinderSize.width = gestureViewFinderSize.height * viewFinderRatio!
					if viewFinderSize.width > imageSize.width {
						gestureViewFinderOffset = previousOffset
						gestureViewFinderSize = previousSize
					}
				}
				if viewFinderSize.width < imageSize.width * 0.1 {
					gestureViewFinderSize.width = previousSize.width
					gestureViewFinderOffset.x = previousOffset.x
				}
				if viewFinderSize.height < imageSize.height * 0.1 {
					gestureViewFinderSize.height = previousSize.height
					gestureViewFinderOffset.y = previousOffset.y
				}
			}
			.onEnded { dragValue in
				let startLocation = dragValue.startLocation
				let corner = determineCorner(from: startLocation)
				let animationDuration: Double
				if corner.isLeft || corner.isRight || corner.isTop || corner.isBottom {
					fixedViewFinderSize = viewFinderSize
					fixedViewFinderOffset = viewFinderOffset
					animationDuration = 0
				}
				else {
					
					fixedViewFinderOffset = CGPoint(x: fixedViewFinderOffset.x + dragValue.translation.width,
												   y: fixedViewFinderOffset.y + dragValue.translation.height)
					let maxiumOffset = CGPoint(x: -(imageSize.width - fixedViewFinderSize.width) / 2,
											   y: -(imageSize.height - fixedViewFinderSize.height) / 2)
					let exceedSize = CGSize(width: fixedViewFinderOffset.x + fixedViewFinderSize.width/2 - imageSize.width/2,
											height: fixedViewFinderOffset.y + fixedViewFinderSize.height/2 - imageSize.height/2)
					let isWidthChanged = fixedViewFinderOffset.x < maxiumOffset.x || exceedSize.width > 0
					let isHeightChanged = fixedViewFinderOffset.y < maxiumOffset.y || exceedSize.height > 0
					animationDuration = (isWidthChanged || isHeightChanged) ? 0.5: 0
					withAnimation (.easeOut(duration: 0.5)) {
						
						if fixedViewFinderOffset.x < maxiumOffset.x{
							let exceedWidth = maxiumOffset.x - fixedViewFinderOffset.x
							fixedViewFinderOffset.x += exceedWidth/2
							fixedViewFinderSize.width -= exceedWidth
						}
						if fixedViewFinderOffset.y < maxiumOffset.y{
							let exceedHeight = maxiumOffset.y - fixedViewFinderOffset.y
							fixedViewFinderOffset.y += exceedHeight/2
							fixedViewFinderSize.height -= exceedHeight
						}
						if exceedSize.width > 0 {
							fixedViewFinderSize.width -= exceedSize.width
							fixedViewFinderOffset.x -= exceedSize.width/2
						}
						if exceedSize.height > 0 {
							fixedViewFinderSize.height -= exceedSize.height
							fixedViewFinderOffset.y -= exceedSize.height/2
						}
					
						if viewFinderRatio != nil,
						   isWidthChanged	{
							fixedViewFinderSize.height = fixedViewFinderSize.width * 1/viewFinderRatio!
						}
						if viewFinderRatio != nil,
						   isHeightChanged {
							fixedViewFinderSize.width = fixedViewFinderSize.height * viewFinderRatio!
						}
						
					}
				}
				self.viewFinderRect = CGRect(
						origin:
							CGPoint(x: imageSize.width/2 + fixedViewFinderOffset.x - fixedViewFinderSize.width/2,
									y: imageSize.height/2 + fixedViewFinderOffset.y - fixedViewFinderSize.height/2),
						size: fixedViewFinderSize)
				gestureViewFinderOffset = .zero
				gestureViewFinderSize = .zero
				DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
					isDraggingViewFinder = false
					isdraggingCenter = false
				}
			}
	}
	
	private func determineCorner(from startLocation: CGPoint) -> (isLeft: Bool, isRight: Bool, isTop: Bool, isBottom: Bool){
		
		let rectOnStart = CGRect(x: fixedViewFinderOffset.x, y: fixedViewFinderOffset.y,
								 width: fixedViewFinderSize.width, height: fixedViewFinderSize.height)
		
		let isLeft = abs(startLocation.x ) < max(rectOnStart.width * 0.2, edgePadding)
		let isRight = abs(startLocation.x - rectOnStart.width) < max(rectOnStart.width * 0.2, edgePadding)
		let isTop = abs(startLocation.y) < max(rectOnStart.height * 0.2, edgePadding)
		let isBottom =  abs(startLocation.y - rectOnStart.height) < max(rectOnStart.height * 0.2, edgePadding)
		return (isLeft, isRight, isTop, isBottom)
	}
	
	init(imageSize: CGSize, scale: CGFloat, viewFinderRect: Binding<CGRect>, viewFinderRatio: CGFloat?) {
		self.imageSize = imageSize
		self.scale = scale
		_viewFinderRect = viewFinderRect
		self.viewFinderRatio = viewFinderRatio
		fixedViewFinderOffset = CGPoint(x: viewFinderRect.wrappedValue.midX - viewFinderRect.wrappedValue.width/2,
										y: viewFinderRect.wrappedValue.midY - viewFinderRect.wrappedValue.height/2)
		fixedViewFinderSize = viewFinderRect.wrappedValue.size
		dragRatio =  max(min(1/scale, 5.0), 1.0)
		lineWidth = min(imageSize.width, imageSize.height) * 0.005
	}
}


