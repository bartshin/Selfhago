
import SwiftUI

@main
struct SelfhagoApp: App {
	
	let albumHandler = AlbumHandler()
	private var designConstant = DesignConstant.shared
	@State private var navigationTag: String?
	
    var body: some Scene {
		WindowGroup {
			NavigationView {
				ImagePickerView(navigationTag: $navigationTag)
					.environmentObject(albumHandler)
					.navigationBarHidden(true)
			}
        }
    }
}
