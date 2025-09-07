//
//  CameraView.swift
//  SmartSHOP - Powered by AI
//
//  Created by Sreesh Srinivasan on 7/29/23.
//

 import SwiftUI
import Photos

struct CameraView: UIViewControllerRepresentable {
    
    @Binding var showCameraView: Bool
    @Binding var pickedImage: Image
    
    func makeCoordinator() -> CameraView.Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        let cameraViewController = UIImagePickerController()
        cameraViewController.delegate = context.coordinator
        cameraViewController.sourceType = .camera
        cameraViewController.allowsEditing = false
        return cameraViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CameraView>) {
        
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraView
        
        init(_ cameraView: CameraView) {
            self.parent = cameraView
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            parent.pickedImage = Image(uiImage: uiImage)
            parent.showCameraView = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.showCameraView = false
        }
    }
}
