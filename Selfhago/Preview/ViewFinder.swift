
//
//  ViewFinder.swift
//  iOS
//
//  Created by bart Shin on 2021/08/11.
//

import SwiftUI

struct ViewFinder: View {
	
	@Binding var isDragging: Bool
	let size: CGSize
	let lineWidth: CGFloat
	
	var body: some View {
		ZStack {
			ForEach(Corner.allCases) {
				drawCorner($0)
					.fill(isDragging ? .clear: .white)
			}
		}
		.border(Color.white, width: lineWidth * (isDragging ? 3 : 1))
		.contentShape(Rectangle())
	}
	
	private func drawCorner(_ corner: Corner) -> Path{
		let cornerLength: CGFloat = lineWidth * 10
		let cornerThickness: CGFloat = lineWidth * 1.5
		return Path { path in
			switch corner {
				case .topLeft:
					path.addRect(CGRect(origin: .zero,
										size: CGSize(width: cornerLength,
													 height: cornerThickness)))
					path.addRect(CGRect(origin: .zero,
										size: CGSize(width: cornerThickness,
													 height: cornerLength)))
				case .topRight:
					path.addRect(CGRect(x: size.width - cornerLength, y: 0,
										width: cornerLength, height: cornerThickness))
					path.addRect(CGRect(x: size.width - cornerThickness, y: 0,
										width: cornerThickness, height: cornerLength))
				case .bottomLeft:
					path.addRect(CGRect(x: 0, y: size.height - cornerLength,
										width: cornerThickness, height: cornerLength))
					path.addRect(CGRect(x: 0, y: size.height - cornerThickness,
										width: cornerLength, height: cornerThickness))
				case .bottomRight:
					path.addRect(CGRect(x: size.width - cornerLength,
										y: size.height - cornerThickness,
										width: cornerLength, height: cornerThickness))
					path.addRect(CGRect(x: size.width - cornerThickness,
										y: size.height - cornerLength,
										width: cornerThickness, height: cornerLength))
			}
		}
	}
	
	private enum Corner: Int, Identifiable, CaseIterable {
		
		case topLeft
		case topRight
		case bottomLeft
		case bottomRight
		
		var id: Int {
			self.rawValue
		}
	}
	
	
	struct CenterCircle: Shape {
		func path(in rect: CGRect) -> Path {
			Path { path in
				
				let margin = max(rect.width * 0.1, 3)
				path.addEllipse(in: CGRect(x: rect.minX + margin,
										   y: rect.minY + margin,
										   width: rect.width - margin * 2,
										   height: rect.height - margin * 2))
				path.move(to: CGPoint(x: rect.midX, y: rect.minY))
				path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + margin * 2))
				path.move(to: CGPoint(x: rect.minX, y: rect.midY))
				path.addLine(to: CGPoint(x: rect.minX + margin * 2, y: rect.midY))
				path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
				path.addLine(to: CGPoint(x: rect.maxX - margin * 2, y: rect.midY))
				path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
				path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - margin * 2))
			}
		}
	}
	
}
