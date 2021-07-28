

import SwiftUI

struct HomeView: View {
	
	@State private var navigationDestination: String?
	
    var body: some View {
		Group {
			VStack {
				HomeMenu(navigationTag: $navigationDestination)
					.padding(.top, Constant.verticalMargin)
			}
		}
		.padding(.vertical, Constant.verticalMargin)
		.navigationBarTitle("Home")
    }
	
	struct Constant {
		static let verticalMargin: CGFloat = 50
	}
}

struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		HomeView()
			.preferredColorScheme(.dark)
			.environmentObject(ImageEditor.forPreview)
	}
}
