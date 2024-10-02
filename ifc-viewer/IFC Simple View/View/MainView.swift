//
//  ContentView.swift
//  IFC-Viewer
//
//  Created by Danil Starikov on 22.04.24.
//

import SwiftUI
import AppKit
import SceneKit


struct MainView: View {
    @StateObject var viewModel: MainViewViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Menu")
                    .font(.title)
                    .padding()
                if let selectedFileURL = viewModel.selectedFileURL {
                    Text("Selected file:\t \(selectedFileURL.lastPathComponent)")
                        .frame(width: 500, height: 50)
                        .border(Color.gray, width: 2)
                        .padding(.bottom)
                }
                Button("Open File") {
                    viewModel.openPanel()
                }
                Button("View File") {
                    viewModel.viewFile = true
                }
                .disabled(viewModel.selectedFileURL == nil)
            }.navigationDestination(isPresented: $viewModel.viewFile, destination: {
                SceneView(filePath: viewModel.selectedFileURL?.path() ?? "")
            })
        }
        .padding()
    }
}

//
//#Preview {
//    MainView(viewModel: MainViewViewModel())
//}
