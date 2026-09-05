//
//  MenuBarProgress.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 03-09-26.
//

import Foundation
import SwiftUI

struct MenuBarProgressView: View {

    @ObservedObject private var engineManager = EngineManager.shared
    
    var body: some View {
        ProgressView(value: engineManager.engineUpdateProgress)
            .progressViewStyle(.circular)
            .controlSize(.small)
            .frame(width: 16, height: 16)
    }
}
