//
//  OBJFileView.swift
//  IFC-Viewer
//
//  Created by Danil Starikov on 29.04.24.
//

import SwiftUI
import SceneKit

struct SceneView: View {
    let filePath: String
    
    var body: some View {
        SceneViewWrapper(filePath: filePath)
    }
}


//#Preview {

//    SceneView(objFilePath: "/Users/danilstarikov/Desktop/AC20-FZK-Haus.obj")
//}
