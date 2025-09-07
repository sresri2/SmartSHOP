//
//  CameraView.swift
//  SmartSHOP - Powered by AI
//
//  Created by Sreesh Srinivasan on 7/19/23.
//

import SwiftUI
import UIKit
import SafariServices
import CoreML
import ColorKit
import Vision

struct ScannerView2: View {
    @State private var showImagePicker: Bool = false
    @State private var image: UIImage?
    @State private var extendedRGBToColorName: [NamedColor] = [
        NamedColor(name: "Black", red: 0.0, green: 0.0, blue: 0.0),
        NamedColor(name: "White", red: 1.0, green: 1.0, blue: 1.0),
        NamedColor(name: "Red", red: 1.0, green: 0.0, blue: 0.0),
        NamedColor(name: "Green", red: 0.0, green: 1.0, blue: 0.0),
        NamedColor(name: "Blue", red: 0.0, green: 0.0, blue: 1.0),
    ]
    
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
    
    func colorName(for extendedRGB: UIColor) -> String? {
        
        var closestColor: NamedColor?
        var closestDistance: CGFloat = CGFloat.greatestFiniteMagnitude

        let colorComponents = extendedRGB.cgColor.components ?? []

        for namedColor in extendedRGBToColorName {
            let distance = sqrt(
                pow(namedColor.red - colorComponents[0], 2) +
                pow(namedColor.green - colorComponents[1], 2) +
                pow(namedColor.blue - colorComponents[2], 2)
            )

            if distance < closestDistance {
                closestDistance = distance
                closestColor = namedColor
            }
        }

        return closestColor?.name
    }

    
    func sendImageToServer(image: UIImage) {
        do {
            var image = image.resize(to: CGSize(width: 100, height: 100))
            let colors = getMainColors(in: image, numberOfColors: 2)
            let colorA = colors?[0].colorName()
            //let colorB = colors?[1].colorName()
            
    
            
            
            guard let ciImage = CIImage(image: image) else { return }
                  
            let config = MLModelConfiguration()
            
            let imageClassifierWrapper = try? MobileNetV2(configuration: config)


            guard let imageClassifier = imageClassifierWrapper else {
                fatalError("App failed to create an image classifier model instance.")
            }


            let imageClassifierModel = imageClassifier.model

            guard let model = try? VNCoreMLModel(for: imageClassifierModel) else {
                fatalError("App failed to create a `VNCoreMLModel` instance.")
            }
            //let model = VNCoreMLModel(for: MobileNetv2().model)
            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    return
                }
                
                let labelText = topResult.identifier
                let urlString = "\(colorA) \(labelText)"
                let url = URL(string: "https://www.google.com/search?q=" + urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)
                
                DispatchQueue.main.async {
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
            } catch {
                print("Error: \(error)")
            }
    
        
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func openURLInBrowser(urlString: String) {
        let url = URL(string: "https://www.google.com/search?q="+urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)
        DispatchQueue.main.async {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
        
    }
}

struct ScannerView2_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView2()
    }
}

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

extension UIColor {
    func distance(to color: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let rMean = (r1 + r2) / 2.0
        let r = r1 - r2
        let g = g1 - g2
        let b = b1 - b2
        
        return sqrt((2.0 + rMean) * pow(r, 2) + 4.0 * pow(g, 2) + (2.0 + (1.0 - rMean)) * pow(b, 2))
    }
}

// Function to get the main colors in the image
func getMainColors(in image: UIImage, numberOfColors: Int) -> [UIColor]? {
    guard let cgImage = image.cgImage else {
        return nil
    }
    
    var pixels: [UIColor] = []
    
    // Iterate over each pixel in the image and extract its color
    for y in 20..<cgImage.height-20 {
        for x in 20..<cgImage.width-20 {
            if let pixelColor = image.getPixelColor(at: CGPoint(x: x, y: y)) {
                pixels.append(pixelColor)
            }
        }
    }
    
    // Perform clustering to identify the main colors
    var clusters: [[UIColor]] = []
    
    for pixel in pixels {
        var addedToCluster = false
        
        for var cluster in clusters {
            let centroid = cluster.reduce(UIColor.black) { total, color in
                var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
                total.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
                
                var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
                color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
                
                let r = (r1 + r2) / 2
                let g = (g1 + g2) / 2
                let b = (b1 + b2) / 2
                
                return UIColor(red: r, green: g, blue: b, alpha: 1.0)
            }
            
            let distance = pixel.distance(to: centroid)
            
            if distance < 50 { // Threshold for considering two colors as part of the same cluster
                cluster.append(pixel)
                addedToCluster = true
                break
            }
        }
        
        if !addedToCluster {
            clusters.append([pixel])
        }
    }
    
    // Sort clusters by size and get the main colors
    clusters.sort { $0.count > $1.count }
    let mainColors = clusters.prefix(numberOfColors).map { cluster -> UIColor in
        let totalRed = cluster.reduce(0) { total, color in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            return total + Int(r * 255)
        }
        let totalGreen = cluster.reduce(0) { total, color in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            return total + Int(g * 255)
        }
        let totalBlue = cluster.reduce(0) { total, color in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            return total + Int(b * 255)
        }
        let averageRed = CGFloat(totalRed) / CGFloat(cluster.count)
        let averageGreen = CGFloat(totalGreen) / CGFloat(cluster.count)
        let averageBlue = CGFloat(totalBlue) / CGFloat(cluster.count)
        
        return UIColor(red: averageRed/255.0, green: averageGreen/255.0, blue: averageBlue/255.0, alpha: 1.0)
    }
    
    return mainColors
}

extension UIImage {
    func getPixelColor(at point: CGPoint) -> UIColor? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        
        let pixelData = cgImage.dataProvider?.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        let pixelInfo: Int = ((Int(self.size.width) * Int(point.y)) + Int(point.x)) * bytesPerPixel
        
        let red = CGFloat(data[pixelInfo]) / 255.0
        let green = CGFloat(data[pixelInfo + 1]) / 255.0
        let blue = CGFloat(data[pixelInfo + 2]) / 255.0
        let alpha = CGFloat(data[pixelInfo + 3]) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension UIColor {
    func colorName() -> String? {
        let colors: [String: UIColor] = [
            "Black": .black,
            "White": .white,
            "Red": .red,
            "Green": .green,
            "Blue": .blue,
            "Cyan": .cyan,
            "Magenta": .magenta,
            "Yellow": .yellow,
            "Orange": .orange,
            "Purple": .purple,
            "Brown": UIColor(red: 0.647, green: 0.165, blue: 0.165, alpha: 1.0),
            "Pink": UIColor(red: 1, green: 0.753, blue: 0.796, alpha: 1.0),
            "Gray": UIColor.gray,
            "Beige": UIColor(red: 0.961, green: 0.961, blue: 0.863, alpha: 1.0),
            "Lavender": UIColor(red: 0.902, green: 0.902, blue: 0.98, alpha: 1.0),
            "Maroon": UIColor(red: 0.502, green: 0, blue: 0, alpha: 1.0),
            "Olive": UIColor(red: 0.502, green: 0.502, blue: 0, alpha: 1.0),
            "Teal": UIColor(red: 0, green: 0.502, blue: 0.502, alpha: 1.0),
            "Navy": UIColor(red: 0, green: 0, blue: 0.502, alpha: 1.0)
        ]
        
        var closestColorName: String?
        var closestColorDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        for (name, color) in colors {
            var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
            self.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
            
            var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0
            color.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)
            
            let distance = sqrt(pow(red1 - red2, 2) + pow(green1 - green2, 2) + pow(blue1 - blue2, 2))
            
            if distance < closestColorDistance {
                closestColorDistance = distance
                closestColorName = name
            }
        }
        
        // Adjust the threshold for considering a color a match
        let threshold: CGFloat = 0.2
        return closestColorDistance <= threshold ? closestColorName : nil
    }
}



