//
//  DragableGraph.swift
//  DragableGraph
//
//  Created by bart Shin on 2021/09/08.
//

import SwiftUI
import simd
import Accelerate

struct DragableGraph<T, BV>: View where T: BinaryFloatingPoint, BV: View {
	
	private struct Point: Equatable {
		var x: CGFloat
		var y: CGFloat
		var tuple: (x: CGFloat, y: CGFloat ) { (x, y) }
	}
	@StateObject private var polynomial: PolynomialGenerator<Float>
	@State private var points = [Point]()
	@State private var graphYValues: [Float] = []
	@Binding var values: [T]
	private let lineColor: Color
	private let lineWidth: CGFloat
	private let pointColor: Color
	private let pointRadius: CGFloat
	private let backgroundView: BV
	private let onChange: ([Float]) -> Void
	
	
    var body: some View {
		GeometryReader{ geometry in
			ZStack {
				GraphLine(size: geometry.size,
						  yValues: graphYValues)
					.stroke(lineColor, lineWidth: lineWidth)
					.background(backgroundView)
				drawPointsView(in: geometry.size)
			}
			.onAppear {
				graphYValues = polynomial.getResult(for: geometry.size.width)
			}
			.onChange(of: values) {
				refreshGraph(from: $0, in: geometry.size)
			}
		}
		.clipped()
    }
	
	private func drawPointsView(in size: CGSize) -> some View {
		Group {
			ForEach(points.indices) { index in
				Circle()
					.fill(pointColor)
					.frame(width: pointRadius * 2, height: pointRadius * 2)
					.padding()
					.contentShape(Rectangle())
					.position(x: points[index].x * size.width ,
							  y: (1 - points[index].y) * size.height)
					.gesture(dragPoint(of: index, in: size))
			}
		}
	}
	
	private func dragPoint(of index: Int, in size: CGSize) -> some Gesture {
		DragGesture()
			.onChanged { dragValue in
				points[index].y = max(min(1 - dragValue.location.y/size.height, 1), 0)
				polynomial.setPoints(points.compactMap{ $0.tuple })
				let result = polynomial.getResult(in: 0...255)
				onChange(vDSP.clip(result, to: 0...1))
				graphYValues = polynomial.getResult(for: size.width)
			}
			.onEnded { dragValue in
				values = points.compactMap {
					T($0.y)
				}
			}
	}
	
	private func getXPoisitions(in size: CGSize) -> [CGFloat] {
		let margin = size.width / CGFloat(values.count)
		return (1...4).compactMap {
			CGFloat($0) * margin
		}
	}
	
	private struct GraphLine: Shape {
		let size: CGSize
		let yValues: [Float]
		func path(in rect: CGRect) -> Path {
			Path { path in
				path.move(to: CGPoint(x: 0, y: CGFloat( 1 - yValues[0]) * size.height))
				for x in stride(from: 0, to: size.width, by: 1) {
					path.addLine(to: CGPoint(x: x, y: CGFloat(1 - yValues[Int(x)]) * size.height))
				}
			}
		}
	}
	
	private func refreshGraph(from controlPoints: [T], in size: CGSize) {
		let newPoints = Self.getPoints(from: controlPoints)
		if newPoints != points {
			points = newPoints
			polynomial.setPoints(points.compactMap{ $0.tuple })
			graphYValues = polynomial.getResult(for: size.width)
		}
	}
	
	private static func getPoints(from values: [T]) -> [Point] {
		values.enumerated().compactMap{
			let x = (CGFloat($0.offset) + 0.5) / CGFloat(values.count)
			let y = CGFloat($0.element)
			return Point(x: x, y: y)
		}
	}
	
	init(values: Binding<[T]>, lineColor: Color = .red, lineWidth: CGFloat = 2, pointColor: Color = .white, pointRadius: CGFloat = 5, backgroundView: BV, onChange: @escaping ([Float]) -> Void) {
		_values = values
		self.lineColor = lineColor
		self.lineWidth = lineWidth
		self.pointColor = pointColor    
		self.pointRadius = pointRadius
		self.backgroundView = backgroundView
		let points: [Point] = Self.getPoints(from: values.wrappedValue)
		_points = .init(initialValue: points)
		_polynomial = .init(wrappedValue: PolynomialGenerator(points: points.compactMap { (Float($0.x), Float($0.y))}))
		self.onChange = onChange
	}
}
