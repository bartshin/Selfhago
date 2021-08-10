

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
	@Environment(\.presentationMode) var presentationMode
	private let passImage: (UIImage) -> Void
	
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
		var configuration = PHPickerConfiguration()
		configuration.filter = .images
		configuration.selectionLimit = 1

		configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context){
         
    }
    
    
    class Coordinator : NSObject, PHPickerViewControllerDelegate {
        
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
		}
		
		func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			self.parent.presentationMode.wrappedValue.dismiss()
			if let selected = results.first ,
			   selected.itemProvider.canLoadObject(ofClass: UIImage.self) {
				selected.itemProvider.loadObject(ofClass: UIImage.self) { result, error in
					if let image = result as? UIImage {
						self.parent.passImage(image)
					}
					else {
						print("Fail to load image \(error?.localizedDescription ?? "")")
					}
				}
			}
		}
    }
	
	init(passImage: @escaping (UIImage) -> Void) {
		self.passImage = passImage
	}
}

