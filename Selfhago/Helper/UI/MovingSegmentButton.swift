//
//  MovingSegmentButton.swift
//  MovingSegmentButton
//
//  Created by bart Shin on 2021/08/31.
//

import SwiftUI

struct MovingSegmentButton<BV>: View where BV: View{

	@Binding var buttonPosition: CGPoint
	@Binding var selectedButtonIndex: Int
	private let isHorizontal: Bool
	private let buttons: [BV]
	
    var body: some View {
		GeometryReader { geometry in
			ZStack {
				HStack {
					ForEach(0..<buttons.count) { index in
						getButton(for: index)
							.frame(width: geometry.size.width * Constant.buttonSize.width,
								   height: geometry.size.width * Constant.buttonSize.height)
					}
				}
				.position(x: geometry.size.width * (buttonPosition.x + buttonOffset.width),
						  y: geometry.size.height * (buttonPosition.y + buttonOffset.height))
				.gesture(dragButtons(in: geometry.size))
			}
		}
	}
	private func getButton(for index: Int) -> some View {
		Group {
			if index == selectedButtonIndex {
				buttons[index]
			}else {
				buttons[index]
					.onTapGesture {
						withAnimation {
							selectedButtonIndex =  index
							
						}
					}
			}
		}
	}
	
	@GestureState private var buttonOffset = CGSize(width: 0, height: 0)
	private func dragButtons(in size: CGSize) -> some Gesture {
		DragGesture()
			.onChanged { dragValue in
				if isHorizontal {
					buttonPosition.x = max(min((dragValue.location.x / size.width), 1), 0)
					
				}else {
					buttonPosition.y = max(min((dragValue.location.y / size.height), 1), 0)
				}
			}
	}
	
	init(isHorizontal: Bool, buttonPosition: Binding<CGPoint>, buttons: [BV], selectedIndexBinding: Binding<Int>?) {
		self.isHorizontal = isHorizontal
		self.buttons = buttons
		_buttonPosition = buttonPosition
		_selectedButtonIndex = selectedIndexBinding ?? State<Int>(initialValue: 0).projectedValue
	}
}

fileprivate struct Constant {
	static let buttonSize = CGSize(width: 0.3, height: 0.1)
}

