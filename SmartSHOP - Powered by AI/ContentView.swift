//
//  ContentView.swift
//  SmartSHOP - Powered by AI
//
//  Created by Sreesh Srinivasan on 7/19/23.
//

import SwiftUI

struct ContentView: View {
    @State var showingScanSuggestorView: Bool = false
    @State var showingCameraView: Bool = false
    @State var showingBarcodeScanView: Bool = false
    @State var showingSuggestionsView: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                Button("Get suggestions (BETA)") {
                    showingScanSuggestorView = true
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
                .frame(width: 200, height: 150)
                .sheet(isPresented: $showingScanSuggestorView) {
                    ScannerView2()
                

                }
                .padding()
            }
            Text("SmartSHOP - Powered by AI").font(.title)
            
            ZStack {
                //RoundedRectangle(cornerRadius: 10)
                Button("Find it Online") {
                    showingBarcodeScanView = true
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                .frame(width: 200, height: 150)
                .sheet(isPresented: $showingBarcodeScanView) {
                    BarcodeScannerView()

                }
                .padding()
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
