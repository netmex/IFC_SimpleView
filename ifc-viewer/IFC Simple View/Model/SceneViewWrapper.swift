//
//  OBJFileViewViewModel.swift
//  IFC-Viewer
//
//  Created by Danil Starikov on 01.05.24.
//

import Foundation
import SceneKit
import SwiftUI
import GeometryConverter

struct SceneViewWrapper: NSViewRepresentable {
    let filePath: String
    
    func makeNSView(context: Context) -> SCNView {
        return GeometryConverter.extractGeometry(filePath)
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        // not necessary
    }
}
