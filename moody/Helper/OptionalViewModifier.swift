//
//  OptionalViewModifier.swift
//  moody
//
//  Created by bart Shin on 05/07/2021.
//

import SwiftUI

extension View {
	@ViewBuilder
	func modifyOptional<VT>(condition: Bool, modifierFunction: () -> VT) -> some View where VT: View {
		if condition {
			modifierFunction()
		}else {
			self
		}
	}
}
