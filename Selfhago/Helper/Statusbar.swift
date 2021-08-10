//
//  Statusbar.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/07.
//

import SwiftUI

struct HiddenStatusbar: ViewModifier {
	func body(content: Content) -> some View {
		content.onAppear {
			DesignConstant.shared.isStatusbarHidden = true
		}
	}
}
struct Showingstatusbar: ViewModifier {
	func body(content: Content) -> some View {
		content.onAppear {
			DesignConstant.shared.isStatusbarHidden = false
		}
	}
}

extension View {
	func isStatusbarHidden(_ isHidden: Bool) -> some View {
		Group {
			if isHidden {
				self.modifier(HiddenStatusbar())
			}else {
				self.modifier(Showingstatusbar())
			}
		}
	}
}
