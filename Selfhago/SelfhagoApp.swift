
import SwiftUI

@main
struct SelfhagoApp: App {
	let editor = ImageEditor()
	
    var body: some Scene {
        WindowGroup {
			NavigationView{
				HomeView()
					.preferredColorScheme(.dark)
			}
			.environmentObject(editor)
			.environmentObject(editor.editingState)
               
        }
    }
}
