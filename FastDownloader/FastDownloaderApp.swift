//
//  FastDownloaderApp.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 12-08-26.
//

import SwiftUI
import AppKit

@main
struct FastDownloaderApp: App {
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
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let dockIcon = NSImage(named: "AppIcon") {
                    NSApp.applicationIconImage = dockIcon
                }
        if let button = statusItem.button {
            if let image = NSImage(named: "FastDownloaderIcon") {
                    image.isTemplate = true
                    image.size = NSSize(width: 32, height: 32)
                    button.image = image
                }
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


