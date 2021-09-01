//
//  ChartState.swift
//  ChartState
//
//  Created by bart Shin on 2021/08/28.
//

import SwiftUI
import SwiftUICharts

struct ChartState {
	let values: [Double]
	var style = ChartStyle(backgroundColor: DesignConstant.getColor(for: .background),
						   foregroundColor: [.init(DesignConstant.getColor(for: .primary).opacity(0.2),
												   DesignConstant.getColor(for: .primary).opacity(0.5))])
	var axisColor = DesignConstant.getColor(for: .onBackground, isDimmed: true)
	
	var minValue: Double {
		values.first!
	}
	init(values: [Double]) {
		self.values = values
	}
	
}
