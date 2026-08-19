//
//  FastDowloaderApp.swift
//  FastDowloader
//
//  Created by Jose Fidalgo on 12-08-26.
//

import SwiftUI
import AppKit

@main
struct FastDowloaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Fast Downloader")
            button.image = image
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PanelView())
        popover.contentSize = NSSize(width: 320, height: 130)
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}


