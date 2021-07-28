
import SwiftUI

@main
struct SelfhagoApp: App {

	
    var body: some Scene {
        WindowGroup {
			NavigationView{
				HomeView()
					.preferredColorScheme(.dark)
			}
        }
    }
}
