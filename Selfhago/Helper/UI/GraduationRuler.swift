import SwiftUI

struct GraduationRuler<T>: Shape where T: BinaryFloatingPoint {
	
	let step: T
	let range: ClosedRange<T>
	
	func path(in rect: CGRect) -> Path {
		let margin = rect.width / CGFloat(range.upperBound - range.lowerBound) * 2
		return Path { path in
			
			for index in stride(from: range.lowerBound, to: range.upperBound + step, by: step as! T.Stride) {
				let x = CGFloat(index) * margin + rect.midX
				if index.truncatingRemainder(dividingBy: 5) == 0 {
					path.move(to: CGPoint(x: x, y: rect.minY))
					path.addLine(to: CGPoint(x: x, y: rect.maxY))
				}
				else if index.truncatingRemainder(dividingBy: 1) == 0{
					path.move(to: CGPoint(x: x, y: rect.height * 0.2))
					path.addLine(to: CGPoint(x: x, y: rect.height * 0.8))
				}
				else {
					path.move(to: CGPoint(x: x, y: rect.height * 0.3))
					path.addLine(to: CGPoint(x: x, y: rect.height * 0.7))
				}
			}
		}
	}
}
