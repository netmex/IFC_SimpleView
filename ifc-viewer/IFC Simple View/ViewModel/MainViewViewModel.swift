//
//  ContentViewViewModel.swift
//  IFC-Viewer
//
//  Created by Danil Starikov on 22.04.24.
//

import Foundation
import AppKit
import CxxStdlib

class MainViewViewModel: ObservableObject {
    @Published var selectedFileURL: URL?
    @Published var viewFile = false
    
    func openPanel() {
        let panel = NSOpenPanel()
        panel.title = "Choose a file"
        panel.showsResizeIndicator = true
        panel.showsHiddenFiles = false
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText, .data]
        
        if panel.runModal() == .OK {
            self.selectedFileURL = panel.url
        }
    }
    
}
