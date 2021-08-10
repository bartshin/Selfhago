//
//  CurveGraph.swift
//  iOS
//
//  Created by bart Shin on 2021/08/05.
//

import SwiftUI

struct CurveGraph: Shape {
	
	private let points: [CGPoint]
	private let lineRadius: CGFloat
	
	func path(in rect: CGRect) -> Path {
		var path = Path()
		let origin = CGPoint(x: points.first!.x * rect.width, y: points.first!.y * rect.height)
		path.move(to: origin)
		var previousPoint = origin
		points.forEach { point in
			guard point != points.first else {
				return
			}
			let pointInRect = CGPoint(x: point.x * rect.width, y: point.y * rect.height)
			let deltaX = pointInRect.x - previousPoint.x
			let curveOffset = deltaX * lineRadius
			
			path.addCurve(to: pointInRect,
						  control1: CGPoint(x: previousPoint.x + curveOffset,
											y: previousPoint.y),
						  control2: CGPoint(x: pointInRect.x - curveOffset, y: pointInRect.y))
			previousPoint = pointInRect
		}
		return path
	}
    
	/// - parameter points: Normalized Point in 0...1 coordinates
	/// - parameter lineRadius: Between  0...1
	init(points: [CGPoint], lineRadius: CGFloat = 0.5) {
		self.points = points.sorted { lhs, rhs in
			lhs.x < rhs.x
		}
		self.lineRadius = lineRadius
	}
}

var dummyPoints: [CGPoint] = [
	.init(x: 0.1,
		  y: 0.3),
	.init(x: 0.3,
		  y: 0.7),
	.init(x: 0.5,
		  y: 0.1),
	.init(x: 0.7,
		  y: 0.8),
	.init(x: 0.9,
		  y: 0.3),
]

struct CurveGraph_Previews: PreviewProvider {
    static var previews: some View {
		CurveGraph(points: dummyPoints)
			.stroke()
			.frame(width: 300, height: 300)
			.border(Color.red, width: 2)
    }
}
