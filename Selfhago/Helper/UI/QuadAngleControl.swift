//
//  QuadAngleControl.swift
//
//  Created by bart Shin on 2021/08/21.
//

import SwiftUI

struct QuadAngleControl: View {
	
	let isHorizontal: Bool
	@Binding var topOrLeft: ClosedRange<CGFloat>
	@Binding var bottomOrRight: ClosedRange<CGFloat>
	@State private var topLeft: CGPoint
	@State private var topRight: CGPoint
	@State private var bottomLeft: CGPoint
	@State private var bottomRight: CGPoint
	@State private var currentDraggingCorner: Corner?
	private let onChanged: () -> Void
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				fillQuadAngle(in: geometry.size)
				Group {
					if isHorizontal {
						drawHorizontalSides(in: geometry.size)
					}else {
						drawVerticalSides(in: geometry.size)
					}
				}
				drawKnobs(in: geometry.size)
			}
			.gesture(createDragGesture(in: geometry.size))
			.onChange(of: isHorizontal) { newValue in
				if isHorizontal != newValue {
					let points = Self.getPointsFromRange(isHorizontal: newValue,
														 topOrLeft: topOrLeft,
														 bottomOrRight: bottomOrRight)
					topLeft = points[0]
					topRight = points[1]
					bottomLeft = points[2]
					bottomRight = points[3]
				}
			}
		}
	}
	
	private func drawHorizontalSides(in size: CGSize) -> some View {
		let points = getPoints(in: size)
		return ZStack {
			Path { path in
				path.move(to: .zero)
				path.addLine(to: CGPoint(x: size.width, y: 0))
				path.move(to: CGPoint(x: 0, y: size.height))
				path.addLine(to: CGPoint(x: size.width, y: size.height))
			}
			.stroke(Constant.backgroundColor, lineWidth: Constant.lineWidth)
			Path { path in
				path.move(to: points[0])
				path.addLine(to: points[1])
				path.move(to: points[2])
				path.addLine(to: points[3])
			}
			.stroke(Constant.foregroundColor, lineWidth: Constant.lineWidth)
		}
	}
	
	private func drawVerticalSides(in size: CGSize) -> some View {
		let points = getPoints(in: size)
		return ZStack {
			Path { path in
				path.move(to: .zero)
				path.addLine(to: CGPoint(x: 0, y: size.height))
				path.move(to: CGPoint(x: size.width, y: 0))
				path.addLine(to: CGPoint(x: size.width, y: size.height))
			}
			.stroke(Constant.backgroundColor, lineWidth: Constant.lineWidth)
			Path {path in
				path.move(to: points[0])
				path.addLine(to: points[2])
				path.move(to: points[1])
				path.addLine(to: points[3])
			}
			.stroke(Constant.foregroundColor,lineWidth: Constant.lineWidth)
		}
	}
	
	private func fillQuadAngle(in size: CGSize) -> some View {
		let points = getPoints(in: size)
		return Path { path in
			path.addLines([
				points[0],
				points[1],
				points[3],
				points[2]
			])
		}
		.fill(Constant.fillColor.opacity(currentDraggingCorner == nil ? 0.1: 0.3))
	}
	
	private func drawKnobs(in size: CGSize) -> some View {
		let points = [scalePoint(topLeft, in: size),
					  scalePoint(topRight, in: size),
					  scalePoint(bottomLeft, in: size),
					  scalePoint(bottomRight, in: size)]
		return Group {
			ForEach(0..<points.count) {
				drawKnob(isDragging: currentDraggingCorner?.rawValue == $0)
					.offset(x: points[$0].x + (isHorizontal && currentDraggingCorner?.rawValue == $0 ? gestureTranslation: 0),
							y: points[$0].y + (!isHorizontal && currentDraggingCorner?.rawValue == $0 ? gestureTranslation: 0))
			}
		}
	}
	
	private func drawKnob(isDragging: Bool) -> some View {
		ZStack {
			Circle()
				.size(width: Constant.knobDiameter, height: Constant.knobDiameter)
				.fill(Constant.foregroundColor.opacity(isDragging ? 0.5: 0.1))
			Circle()
				.size(width: Constant.knobDiameter/2,
					  height: Constant.knobDiameter/2)
				.stroke(Constant.foregroundColor)
				.offset(x: Constant.knobDiameter/4, y: Constant.knobDiameter/4)
			Circle()
				.size(width: Constant.knobDiameter/2 - 2,
					  height: Constant.knobDiameter/2 - 2)
				.fill(isDragging ? Constant.foregroundColor: Color.white)
				.offset(x: Constant.knobDiameter/4 + 1, y: Constant.knobDiameter/4 + 1)
		}
		.offset(x: -Constant.knobDiameter/2, y: -Constant.knobDiameter/2)
	}
	
	@State private var gestureTranslation: CGFloat = 0
	
	private func createDragGesture(in size: CGSize) -> some Gesture {
		DragGesture(coordinateSpace: .local)
			.onChanged { dragValue in
				let normalizedStartLocation = CGPoint(x: dragValue.startLocation.x / size.width, y: dragValue.startLocation.y / size.height)
				
				currentDraggingCorner = getCorner(from: normalizedStartLocation)
				guard let corner = currentDraggingCorner else {
					return
				}
				gestureTranslation = isHorizontal ? dragValue.translation.width: dragValue.translation.height
				var minValue: CGFloat
				var maxValue: CGFloat
				switch corner {
					case .topLeft:
						minValue = isHorizontal ? -topLeft.x: -topLeft.y
						maxValue = isHorizontal ? topRight.x - topLeft.x: bottomLeft.y - topLeft.y
					case .topRight:
						minValue = isHorizontal ? topLeft.x - topRight.x: -topRight.y
						maxValue = isHorizontal ? 1 - topRight.x: bottomRight.y - topRight.y
					case .bottomLeft:
						minValue = isHorizontal ? -bottomLeft.x: topLeft.y - bottomLeft.y
						maxValue = isHorizontal ? bottomRight.x - bottomLeft.x: 1 - bottomLeft.y
					case .bottomRight:
						minValue = isHorizontal ? bottomLeft.x - bottomRight.x: topRight.y - bottomRight.y
						maxValue = isHorizontal ? 1 - bottomRight.x: 1 - bottomRight.y
				}
				minValue *= isHorizontal ? size.width: size.height
				maxValue *= isHorizontal ? size.width: size.height
				gestureTranslation = max(minValue, min(maxValue, gestureTranslation))
			}
			.onEnded { dragValue in
				guard let corner = currentDraggingCorner else {
					return
				}
				
				let gestureOffset = gestureTranslation / (isHorizontal ? size.width: size.height)
				switch corner {
					case .topLeft:
						topLeft = CGPoint(x: topLeft.x + (isHorizontal ? gestureOffset: 0),
										  y: topLeft.y + (isHorizontal ? 0: gestureOffset))
						topOrLeft = (topOrLeft.lowerBound + gestureOffset)...topOrLeft.upperBound
					case .topRight:
						if isHorizontal {
							topRight.x += gestureOffset
							topOrLeft = topOrLeft.lowerBound...(topOrLeft.upperBound + gestureOffset)
						}else {
							topRight.y += gestureOffset
							bottomOrRight = (bottomOrRight.lowerBound + gestureOffset)...bottomOrRight.upperBound
						}
					case .bottomLeft:
						if isHorizontal {
							bottomLeft.x += gestureOffset
							bottomOrRight = (bottomOrRight.lowerBound + gestureOffset)...bottomOrRight.upperBound
						}else {
							bottomLeft.y += gestureOffset
							topOrLeft = topOrLeft.lowerBound...(topOrLeft.upperBound + gestureOffset)
						}
					case .bottomRight:
						bottomRight = CGPoint(x: bottomRight.x + (isHorizontal ? gestureOffset: 0),
											  y: bottomRight.y + (isHorizontal ? 0: gestureOffset))
						bottomOrRight = bottomOrRight.lowerBound...(bottomOrRight.upperBound + gestureOffset)
				}
				currentDraggingCorner = nil
				onChanged()
			}
	}
	
	private func getPoints(in size: CGSize) -> [CGPoint] {
		let points = [scalePoint(topLeft, in: size),
					  scalePoint(topRight, in: size),
					  scalePoint(bottomLeft, in: size),
					  scalePoint(bottomRight, in: size)]
		return points.enumerated().compactMap {
			if let draggingCorner = currentDraggingCorner,
			   draggingCorner.rawValue == $0.offset {
				return CGPoint(x: $0.element.x + (isHorizontal ? gestureTranslation: 0),
							   y: $0.element.y + (isHorizontal ? 0: gestureTranslation))
			}else {
				return $0.element
			}
		}
	}
	
	private func getCorner(from startLocation: CGPoint) -> Corner? {
		let distanceThreshold: CGFloat = 0.1
		if squreDistance(startLocation, topLeft) < distanceThreshold {
			return .topLeft
		}
		else if squreDistance(startLocation, topRight) < distanceThreshold {
			return .topRight
		}
		else if squreDistance(startLocation, bottomLeft) < distanceThreshold {
			return .bottomLeft
		}
		else if squreDistance(startLocation, bottomRight) < distanceThreshold {
			return .bottomRight
		}else {
			return nil
		}
	}
	
	private func squreDistance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
		(lhs.x - rhs.x) * (lhs.x - rhs.x) + (lhs.y - rhs.y) * (lhs.y - rhs.y)
	}
	
	private func scalePoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
		CGPoint(x: point.x * size.width, y: point.y * size.height)
	}
	
	private enum Corner: Int {
		case topLeft
		case topRight
		case bottomLeft
		case bottomRight
	}
	
	private struct Constant {
		static let lineWidth: CGFloat = 3
		static let foregroundColor: Color = .pink
		static let backgroundColor: Color = foregroundColor.opacity(0.5)
		static let fillColor: Color = .blue
		static let knobColor: Color = .white
		static let knobDiameter: CGFloat = 30
	}
	
	private static func getPointsFromRange(isHorizontal: Bool, topOrLeft: ClosedRange<CGFloat>, bottomOrRight: ClosedRange<CGFloat>) -> [CGPoint] {
		[
			CGPoint(x: isHorizontal ? topOrLeft.lowerBound: 0,
					y: isHorizontal ? 0: topOrLeft.lowerBound),
			CGPoint(x: isHorizontal ? topOrLeft.upperBound: 1,
					y: isHorizontal ? 0: bottomOrRight.lowerBound),
			CGPoint(x: isHorizontal ? bottomOrRight.lowerBound: 0,
					y: isHorizontal ? 1: topOrLeft.upperBound),
			CGPoint(x: isHorizontal ? bottomOrRight.upperBound: 1,
					y: isHorizontal ? 1: bottomOrRight.upperBound)
		]
	}
	
	init(isHorizontal: Bool, topOrLeft: Binding<ClosedRange<CGFloat>>, bottomOrRight: Binding<ClosedRange<CGFloat>>, onChanged: @escaping() -> Void) {
		self.isHorizontal = isHorizontal
		self.onChanged = onChanged
		_topOrLeft = topOrLeft
		_bottomOrRight = bottomOrRight
		let points = Self.getPointsFromRange(isHorizontal: isHorizontal, topOrLeft: topOrLeft.wrappedValue,
										bottomOrRight: bottomOrRight.wrappedValue)
		topLeft =  points[0]
		topRight = points[1]
		bottomLeft = points[2]
		bottomRight = points[3]
	}
}

struct QuadAngleControl_Previews: PreviewProvider {
	static var previews: some View {
		QuadAngleControl(isHorizontal: false,
						 topOrLeft: .constant(0...0.5),
						 bottomOrRight: .constant(0.2...1), onChanged: {})
			.frame(width: 300, height: 300)
	}
}

