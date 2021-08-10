//
//  CollapeableView.swift
//  iOS
//
//  Created by bart Shin on 2021/08/02.
//

import SwiftUI

struct CollapeableView<MainView, PlaceHolder, AttacedView>: View where MainView: View, PlaceHolder: View, AttacedView: View {
	
	@Binding var isCollapsed: Bool
	private let mainView: MainView
	private let placeHolder: PlaceHolder
	private let attachedView: AttacedView
	private var attacedViewYPostion: CGFloat {
		isCollapsed ? Constant.expanedHeight + Constant.collapseHeight: Constant.expanedHeight * 0.8
	}
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				mainView
					.frame(width: geometry.size.width,
						   height: geometry.size.height)
					.overlay(
						placeHolder
							.opacity(isCollapsed ? 1: 0)
							.frame(width: geometry.size.width,
								   height: geometry.size.height * Constant.placeHolderHeight)
							.offset(y: -geometry.size.height / 2)
					)
				
				attachedView
					.frame(width: geometry.size.width,
						   height: geometry.size.height * (isCollapsed ? Constant.collapseHeight: Constant.expanedHeight))
					.position(x: geometry.size.width / 2,
							  y: geometry.size.height * attacedViewYPostion)
					.opacity(isCollapsed ? 0: 1)
			}
		}
		
	}
	
	
	init(bindingTo collapse: Binding<Bool>, mainView: MainView, collapesePlaceHolder: PlaceHolder, attachedView: AttacedView) {
		_isCollapsed = collapse
		self.mainView = mainView
		self.placeHolder = collapesePlaceHolder
		self.attachedView = attachedView
	}
}

fileprivate struct Constant {
	static let collapseHeight: CGFloat = 0.1
	static let expanedHeight: CGFloat = 0.9
	static let placeHolderHeight: CGFloat = 0.05
}
