//
//  CameraView.swift
//  SmartSHOP - Powered by AI
//
//  Created by Sreesh Srinivasan on 7/19/23.
//

import SwiftUI
import UIKit
import SafariServices

struct ScannerView: View {
    @State private var showImagePicker: Bool = false
    @State private var image: UIImage?


    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("No Image Selected")
            }

            Button("Select Image to Scan") {
                showImagePicker = true
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image, onImageSelected: { selectedImage in
                    if let image = selectedImage {
                        sendImageToServer(image: image)
                    }
                })

            }
            .padding()
        }
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        // Calculate the scaling factor to get the desired target size while maintaining aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)

        // Calculate the new size based on the scaling factor
        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        // Create a new image context to draw the resized image
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)

        // Draw the resized image
        image.draw(in: CGRect(origin: .zero, size: scaledSize))

        // Get the resized image from the context
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()

        // End the image context
        UIGraphicsEndImageContext()

        return resizedImage
    }


    func sendImageToServer(image: UIImage) {
        //let targetSize = CGSize(width: 800, height: 800)
        //let image = image.resizeWithWidth(width: 700)!
        let compressData = image.jpegData(compressionQuality: 0.8)
        let compressedImage = UIImage(data: compressData!)
        
        guard let url = URL(string: "https://sresri.pythonanywhere.com/analyze") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let imageData = compressedImage!.pngData()
        print(imageData!)
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"tempImage.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData!)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        print(request)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error1: \(error)")
                return
            }
            
            if let data = data {
                print(data)
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let colors = jsonResponse["colors"] as? [String], let predictedClothingLabel = jsonResponse["predicted_clothing_label"] as? String {
                            print("Colors: \(colors)")
                            print("Predicted Clothing Label: \(predictedClothingLabel)")
                            
                            let url: String = colors[0] + " and " + colors[1] + " " + predictedClothingLabel
                            print("URL: \(url)")
                            openURLInBrowser(urlString: url)
                        }
                    }
                    
                } catch {
                    print("Error parsing JSON response: \(error)")
                }
            }
        }
        task.resume()
        
        
        /*
        if let image = resizeImage(image, targetSize: targetSize) {
            
        } else {
            print("Resize Image Failed")
        }
         */
    }
        
        


    func openURLInBrowser(urlString: String) {
        let url = URL(string: "https://www.google.com/search?q="+urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)
        DispatchQueue.main.async {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
        
    }






}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
/*
 struct ImagePicker: UIViewControllerRepresentable {
 @Binding var image: UIImage?
 var onImageSelected: ((UIImage?) -> Void)
 
 class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
 @Binding var image: UIImage?
 var onImageSelected: ((UIImage?) -> Void)
 
 init(image: Binding<UIImage?>, onImageSelected: @escaping (UIImage?) -> Void) {
 _image = image
 self.onImageSelected = onImageSelected
 }
 
 func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
 if let uiImage = info[.originalImage] as? UIImage {
 image = uiImage
 // Pass the selected image back to the ImagePicker
 onImageSelected(uiImage)
 }
 picker.dismiss(animated: true)
 }
 
 func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
 picker.dismiss(animated: true)
 }
 }
 
 func makeCoordinator() -> Coordinator {
 return Coordinator(image: $image, onImageSelected: onImageSelected)
 }
 
 func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
 let picker = UIImagePickerController()
 picker.delegate = context.coordinator
 return picker
 }
 
 func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
 // Do nothing
 }
 }
 */
