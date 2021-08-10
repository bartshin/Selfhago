
import SwiftUI

@main
struct SelfhagoApp: App {
	let albumHandler = AlbumHandler()
	@StateObject private var designConstant = DesignConstant.shared
	@State private var navigationTag: String?
	
    var body: some Scene {
		WindowGroup {
			NavigationView {
				ImagePickerView(navigationTag: $navigationTag)
					.environmentObject(albumHandler)
					.preferredColorScheme(.light)
					.navigationBarHidden(true)
			}
			.statusBar(hidden: designConstant.isStatusbarHidden)
        }
    }
}
