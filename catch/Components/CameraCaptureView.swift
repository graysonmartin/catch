import SwiftUI
import UIKit

/// Wraps `UIImagePickerController` with `.camera` source type for direct photo capture.
/// Returns compressed JPEG `Data` via a completion callback.
struct CameraCaptureView: UIViewControllerRepresentable {
    private let onCapture: (Data) -> Void
    private let onCancel: () -> Void

    init(onCapture: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
        self.onCapture = onCapture
        self.onCancel = onCancel
    }

    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (Data) -> Void
        private let onCancel: () -> Void

        init(onCapture: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                onCancel()
                return
            }
            let resized = ImageResizer.resize(image, maxDimension: ImageResizer.photoMaxDimension)
            guard let compressed = resized.jpegData(compressionQuality: CatchTheme.jpegCompressionQuality) else {
                onCancel()
                return
            }
            onCapture(EXIFStripper.stripMetadata(from: compressed))
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
