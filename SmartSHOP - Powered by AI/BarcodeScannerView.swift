//
//  BarcodeScannerView.swift
//  SmartSHOP - Powered by AI
//
//  Created by Sreesh Srinivasan on 3/24/24.
//

import SwiftUI

struct BarcodeScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ScannerViewController

    func makeUIViewController(context: Context) -> ScannerViewController {
        return ScannerViewController()
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        // Update the view controller if needed
    }
}

#Preview {
    BarcodeScannerView()
}
