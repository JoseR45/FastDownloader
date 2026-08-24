//
//  wrappers.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 18-08-26.
//

import SwiftUI
import AppKit

struct MacProgressIndicator: NSViewRepresentable {
    @Binding var isIndeterminate: Bool
    @Binding var progress: Double
    var minValue: Double = 0.0
    var maxValue: Double = 1.0
    var color: NSColor = .controlAccentColor
    var isBezeled: Bool = false
    var isControlSizeSmall: Bool = false
    
    func makeNSView(context: Context) -> NSProgressIndicator {
        let progressIndicator = NSProgressIndicator()
        
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = isIndeterminate
        progressIndicator.minValue = minValue
        progressIndicator.maxValue = maxValue
        progressIndicator.doubleValue = progress
        progressIndicator.isBezeled = isBezeled
        progressIndicator.controlSize = isControlSizeSmall ? .small : .regular
        
        progressIndicator.usesThreadedAnimation = true
        
        return progressIndicator
    }
    
    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
        if nsView.isIndeterminate != isIndeterminate {
            nsView.isIndeterminate = isIndeterminate
        }
        
        if isIndeterminate {
            nsView.startAnimation(nil)
        } else {
            nsView.stopAnimation(nil)
            nsView.doubleValue = progress
        }
    }
}
