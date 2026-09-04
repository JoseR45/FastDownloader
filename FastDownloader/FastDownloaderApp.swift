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
    static weak var shared: AppDelegate?
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    private var progressHostingView: NSHostingView<MenuBarProgressView>?
    private var isUpdatingEngine = false
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStarted),
            name: .engineUpdateStarted,
            object: EngineManager.shared
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateEnded),
            name: .engineUpdateEnded,
            object: EngineManager.shared
        )
    }
    @objc func updateStarted() {
        isUpdatingEngine = true
        showUpdateProgress()
    }

    @objc func updateEnded() {
        isUpdatingEngine = false
        hideUpdateProgress()
    }
    
    @objc func togglePopover() {
        
        guard !isUpdatingEngine else {
            return
        }
        
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    func showUpdateProgress() {

        DispatchQueue.main.async {

            guard let button = self.statusItem.button else {
                return
            }

            let hostingView = NSHostingView(
                rootView: MenuBarProgressView()
            )

            hostingView.translatesAutoresizingMaskIntoConstraints = false

            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor

            button.image = nil
            button.title = ""

            button.addSubview(hostingView)

            NSLayoutConstraint.activate([
                hostingView.centerXAnchor.constraint(
                    equalTo: button.centerXAnchor
                ),
                hostingView.centerYAnchor.constraint(
                    equalTo: button.centerYAnchor
                ),
                hostingView.widthAnchor.constraint(
                    equalToConstant: 16
                ),
                hostingView.heightAnchor.constraint(
                    equalToConstant: 16
                )
            ])

            self.progressHostingView = hostingView
        }
    }
    
    func hideUpdateProgress() {
        DispatchQueue.main.async {

            guard let button = self.statusItem.button else {
                return
            }

            self.progressHostingView?.removeFromSuperview()
            self.progressHostingView = nil

            button.title = ""

            if let image = NSImage(named: "FastDownloaderIcon") {
                image.isTemplate = true
                image.size = NSSize(width: 32, height: 32)
                button.image = image
            }
        }
    }
    
}


