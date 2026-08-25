//
//  DownloadsQueue.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 20-08-26.
//

import SwiftUI

struct DownloadsQueueView: View {
    @StateObject private var downloadManager = VideoDownloader.shared
    
    private func checkIfEmptyAndClose() {
        if downloadManager.downloadQueue.isEmpty && downloadManager.downloadedQueue.isEmpty {
            DownloadsQueueWindowManager.shared.closeWindow()
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            List {
                
                    ForEach($downloadManager.downloadQueue) { $download in
                        DownloadRow(
                            download: $download,
                            retry: { download in
                                downloadManager.retry(download)
                                self.checkIfEmptyAndClose()
                            },
                            delete: { download in
                                downloadManager.removeDownload(download)
                                self.checkIfEmptyAndClose()
                            }
                        )
                    }
                    ForEach( $downloadManager.downloadedQueue) { $download in
                        DownloadRow(
                            download: $download,
                            retry: { download in
                                downloadManager.retry(download)
                                self.checkIfEmptyAndClose()
                            },
                            delete: { download in
                                downloadManager.removeDownload(download)
                                self.checkIfEmptyAndClose()
                            }
                        )
                    }
            }
        }
        .frame(width: 300, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
    }
}


class DownloadsQueueWindowManager {
    static let shared = DownloadsQueueWindowManager()
    private var window: NSWindow?
    
    func openWindow() {
        if window == nil {
            let hostingController = NSHostingController(rootView: DownloadsQueueView())
            
            window = NSWindow(contentViewController: hostingController)
            window?.title = "Downloads"
            window?.setContentSize(NSSize(width: 200, height: 150))
            window?.styleMask = [.titled, .closable, .miniaturizable]
            window?.resizeIncrements = NSSize(width: 0, height: 0)
            window?.standardWindowButton(.zoomButton)?.isEnabled = false
            window?.standardWindowButton(.zoomButton)?.isHidden = true
            window?.isReleasedWhenClosed = false
            window?.center()
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowWillClose),
                name: NSWindow.willCloseNotification,
                object: window
            )
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func windowWillClose() {
        window = nil
    }
    
    func closeWindow() {
            window?.close()
            window = nil
        }
}
