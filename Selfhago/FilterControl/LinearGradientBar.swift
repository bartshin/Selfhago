//
//  LinearGradientBar.swift
//  iOS
//
//  Created by bart Shin on 2021/08/05.
//

import SwiftUI

struct LinearGradientBar: View {
	private let cornerRadius: CGFloat
	private let colors: [Color]
	private let isHorizontal: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
			.fill(LinearGradient(
					gradient:
						Gradient(colors: colors),
					startPoint: isHorizontal ? .leading: .top,
					endPoint: isHorizontal ? .trailing: .bottom))
    }
	init(cornerRadius: CGFloat, colors: [Color] = [.black, .white], isHorizontal: Bool = true) {
		self.cornerRadius = cornerRadius
		self.colors = colors
		self.isHorizontal = isHorizontal
	}
}

struct BrightGradintBar_Previews: PreviewProvider {
    static var previews: some View {
		LinearGradientBar(cornerRadius: 30)
			.frame(width: 300, height: 50)
    }
}
