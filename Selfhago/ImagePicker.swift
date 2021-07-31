

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
	@Binding var isPresenting: Bool
	private let passImageData: (Data) -> Void
	
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
			DispatchQueue.main.async {
				self.parent.isPresenting = false
			}
			if let selected = results.first {
				selected.itemProvider.loadFileRepresentation(forTypeIdentifier:  UTType.image.identifier) { [self] url, error in
					guard let url = url,
						  error == nil else {
						assertionFailure("Fail to get image file url from \(selected)")
						return
					}
					if let data = try? Data(contentsOf: url) {
						parent.passImageData(data)
					}
					else {
						assertionFailure("Fail to get image data from \(url)")
					}
				}
			}
		}
    }
	
	init(isPresenting: Binding<Bool>, passImageData: @escaping (Data) -> Void) {
		self._isPresenting = isPresenting
		self.passImageData = passImageData
	}
}

