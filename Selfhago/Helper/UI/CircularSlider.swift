//
//  CircularSlider.swift
//  Selfhago
//
//  Created by bart Shin on 19/07/2021.
//

import SwiftUI
import Combine

struct CircularSlider<BgV, BtnV>: View where BgV: View, BtnV: View {
	
	typealias AngleAndRadiusPair = (angle: CGFloat, radius: CGFloat)
	
	private let backgroundView: BgV
	@Binding var anglesAndRadius : [CGFloat: CGFloat]
	@State private var points: [Point]
	private let drawButton:(_ size: CGSize) -> BtnV
	private var initialPair: AngleAndRadiusPair = ( -.pi/2, 0.5)
	var handleValueChanged: () -> Void
	
	var body: some View {
		GeometryReader { geometry in
			let frame = geometry.frame(in: .local)
			let outmostRadius = min(geometry.size.width, geometry.size.height) * 0.5
			let center = CGPoint(x: frame.midX,
								 y: frame.midY)
			ZStack{
				backgroundView
					.position(center)
					.clipShape(Circle()
								.size(geometry.size))
				
				ForEach(points) { point in
					drawPoint(point,
							  center: center,
							  in: outmostRadius)
				}
				.onReceive(Just(anglesAndRadius)) { newValue in
					updatePoints(from: newValue)
				}
				drawButton(CGSize(width: outmostRadius * 0.4, height: outmostRadius * 0.4))
					.onTapGesture(perform: tapbutton)
			}
			.frame(width: geometry.size.width,
				   height: geometry.size.height)
			.coordinateSpace(name: String(describing: Self.self))
			
		}
	}
	
	private func tapbutton() {
		if points.first(where: {
			$0.angle == initialPair.angle
		}) == nil {
			let newPoint = Point(angle: initialPair.angle, radius: 0)
			points.append(newPoint)
			withAnimation(.interactiveSpring()) {
				points[points.count - 1].radius = initialPair.radius
			}
		}
	}
	
	@ViewBuilder
	private func drawPoint(_ point: Point, center: CGPoint, in outmostRadius: CGFloat) -> some View {
		let vetor = CIVector(x: cos(point.angle) * outmostRadius,
							 y: sin(point.angle) * outmostRadius )
		ZStack {
			Path { path in
				path.move(to: center)
				path.addLine(to: CGPoint(x: center.x + vetor.x, y: center.y + vetor.y))
			}.stroke(Color(point.lineColor), lineWidth: outmostRadius / 8)
			.scaleEffect(x: point.radius, y: point.radius)
			Circle()
				.frame(width: outmostRadius / 4, height: outmostRadius / 4)
				.foregroundColor(.white)
				.offset(x: vetor.x * point.radius, y: vetor.y * point.radius)
				.transition(.scale(scale: 1.5))
				.gesture(createDragGesture(for: point, center: center, in: outmostRadius))
		}
	}
	
	
	private func createDragGesture(for point: Point, center: CGPoint, in outmostRadius: CGFloat) -> some Gesture {
		DragGesture(coordinateSpace: .named(String(describing: Self.self)))
			.onChanged { lastestPanningValue in
				guard let index = points.firstIndex(where: {
					$0.id == point.id
				}) else {
					return
				}
				let location = CGPoint(x: lastestPanningValue.location.x - center.x,
									   y: lastestPanningValue.location.y - center.y)
				var nomalizedValues = calcAngleAndRadius(from: location, in: outmostRadius)
				if nomalizedValues.radius > 1 {
					return
				}
				if location.x < 0 {
					nomalizedValues.angle += .pi
				}
				var newPoint = point
				newPoint.angle = nomalizedValues.angle
				newPoint.radius = nomalizedValues.radius
				points[index] = newPoint
				updateBindingValues()
			}
			.onEnded { lastestPanningValue in
				guard let index = points.firstIndex(where: {
					$0.id == point.id
				}) else {
					return
				}
				let location = CGPoint(x: lastestPanningValue.location.x - center.x,
									   y: lastestPanningValue.location.y - center.y)
				let nomalizedValues = calcAngleAndRadius(from: location, in: outmostRadius)
				if nomalizedValues.radius > 1.1 {
					points.remove(at: index)
				}
				updateBindingValues()
				handleValueChanged()
			}
	}
	
	private func calcAngleAndRadius(from location: CGPoint, in outmostRadius: CGFloat) -> (angle: CGFloat, radius: CGFloat) {
		let radius = sqrt(location.x * location.x + location.y * location.y) / outmostRadius;
		let angle = atan(location.y / location.x)
		return (angle, radius)
		
	}
	
	private func updateBindingValues() {
		anglesAndRadius = points.reduce(into: [:]) { dict, point in
			dict[point.angle] = point.radius
		}
	}

	private func updatePoints(from newValue: [CGFloat: CGFloat]) {
		if newValue.count > points.count {
			points = Self.createPoints(from: newValue)
		}else if newValue.count < points.count {
			let interval = DateInterval(start: points.last!.id, end: Date())
			if interval.duration > 2 {
				points = Self.createPoints(from: newValue)
			}
		}
	}
	
	fileprivate static func createPoints(from anglesAndRadius: [CGFloat: CGFloat]) -> [Point] {
		anglesAndRadius.map { (angle, radius) in
			Point(angle: angle, radius: radius)
		}
	}
	
	init(anglesAndRadius: Binding<[CGFloat: CGFloat]>,
		 handleValueChanged: @escaping () -> Void = {},
		 backgroundView: BgV,
		 drawButton: @escaping (CGSize) -> BtnV) {
		self.backgroundView = backgroundView
		self._anglesAndRadius = anglesAndRadius
		self.drawButton = drawButton
		self.handleValueChanged = handleValueChanged
		_points = State(initialValue: Self.createPoints(from: anglesAndRadius.wrappedValue))
	}
	
	fileprivate struct Point: Identifiable {
		var angle: CGFloat
		var radius: CGFloat
		let id = Date()
		let lineColor = UIColor.getRandom()
	}
}
fileprivate struct PreviewBindingProvider: View {
	@State private var anglesAndRadius = [CGFloat: CGFloat]()
	
	var body: some View {
		CircularSlider(
			anglesAndRadius: $anglesAndRadius,
			backgroundView: Color(.lightGray),
			drawButton: { size in
				Text("New")
					.frame(width: size.width, height: size.height)
					.background(Color.blue)
					.clipShape(Circle())
			})
	}
}

struct CircleAngleSlider_Previews: PreviewProvider {
	
    static var previews: some View {
		PreviewBindingProvider()
    }
}
