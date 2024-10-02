//
//  IFC_ViewerApp.swift
//  IFC-Viewer
//
//  Created by Danil Starikov on 22.04.24.
//

import SwiftUI

@main
struct IFCSimpleView: App {
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: MainViewViewModel())
        }
    }
}
