//
//  Manager.swift
//  SmartSHOP - Powered by AI
//
//  Created by Sreesh Srinivasan on 7/19/23.
//

import Foundation
import UIKit


struct AnalysisResult: Decodable {
    let colors: [String]
    let predictedClothingLabel: String
}

struct NamedColor {
    let name: String
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
}


extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: targetSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
}

extension UIImage {
    func resized(to size:CGSize) -> UIImage {
        let f = UIGraphicsImageRendererFormat()
        f.scale = 1
        f.preferredRange = .standard
        let ren = UIGraphicsImageRenderer(size: size, format: f)
        let res = ren.image { (context) in
            self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        }
        return res
    }
    
    func getPixels() -> [UIColor] {
        guard let cgImage = self.cgImage else {
            return []
        }
        assert(cgImage.bitsPerPixel == 32, "only support 32 bit images")
        assert(cgImage.bitsPerComponent == 8,  "only support 8 bit per channel")
        guard let imageData = cgImage.dataProvider?.data as Data? else {
            return []
        }
        let size = cgImage.width * cgImage.height
        let buffer = UnsafeMutableBufferPointer<UInt32>.allocate(capacity: size)
        _ = imageData.copyBytes(to: buffer)
        var result = [UIColor]()
        result.reserveCapacity(size)
        for pixel in buffer {
            var r : UInt32 = 0
            var g : UInt32 = 0
            var b : UInt32 = 0
            if cgImage.byteOrderInfo == .orderDefault || cgImage.byteOrderInfo == .order32Big {
                r = pixel & 255
                g = (pixel >> 8) & 255
                b = (pixel >> 16) & 255
            } else if cgImage.byteOrderInfo == .order32Little {
                r = (pixel >> 16) & 255
                g = (pixel >> 8) & 255
                b = pixel & 255
            }
            let color = UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1)
            result.append(color)
        }
        return result
    }
    
    func getAverageColor(image: UIImage) -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

func colorName(for components: [CGFloat]) -> String? {
    let colors: [String: [CGFloat]] = [
        "Black": [0, 0, 0, 1],
        "White": [1, 1, 1, 1],
        "Red": [1, 0, 0, 1],
        "Green": [0, 1, 0, 1],
        "Blue": [0, 0, 1, 1],
        "Yellow": [1, 1, 0, 1],
        "Cyan": [0, 1, 1, 1],
        "Magenta": [1, 0, 1, 1],
        "Brown": [0.647, 0.165, 0.165, 1],
        "Orange": [1, 0.647, 0, 1],
        "Pink": [1, 0.753, 0.796, 1],
        "Purple": [0.502, 0, 0.502, 1],
        "Gray": [0.502, 0.502, 0.502, 1],
        "Beige": [0.961, 0.961, 0.863, 1],
        "Lavender": [0.902, 0.902, 0.98, 1],
        "Maroon": [0.502, 0, 0, 1],
        "Olive": [0.502, 0.502, 0, 1],
        "Teal": [0, 0.502, 0.502, 1],
        "Navy": [0, 0, 0.502, 1],
    ]



    var closestColor: String?
    var closestDistance: CGFloat = .greatestFiniteMagnitude

    for (name, colorComponents) in colors {
        let distance = sqrt(
            pow(colorComponents[0] - components[0], 2) +
            pow(colorComponents[1] - components[1], 2) +
            pow(colorComponents[2] - components[2], 2) +
            pow(colorComponents[3] - components[3], 2)
        )

        if distance < closestDistance {
            closestDistance = distance
            closestColor = name
        }
    }

    return closestColor
}

func getColorName(image: UIImage) -> String? {
    guard let averageColor = image.getAverageColor(image: image) else {
        return nil
    }

    guard let components = averageColor.cgColor.components else {
        return nil
    }

    let red = CGFloat(components[0])
    let green = CGFloat(components[1])
    let blue = CGFloat(components[2])
    let alpha = CGFloat(components[3])

    let colorComponents = [red, green, blue, alpha]

    return colorName(for: colorComponents)
}











