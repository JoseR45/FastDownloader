//
//  DownloadsQueue.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 20-08-26.
//

import SwiftUI

struct DownloadsQueueView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var downloadManager = VideoDownloader.shared

    var body: some View {
        VStack(spacing: 0) {
            List {
                
                    ForEach($downloadManager.downloadQueue) { $download in
                        DownloadRow(
                            download: $download,
                            retry: { download in
                                downloadManager.retry(download)
                            }
                        )
                    }
                    ForEach( $downloadManager.downloadedQueue) { $download in
                        DownloadRow(
                            download: $download,
                            retry: { download in
                                downloadManager.retry(download)
                            }
                        )
                    }
            }
        }
        .frame(width: 200, height: 150)
        .background(Color(NSColor.windowBackgroundColor))
    }
}


struct DownloadRow: View {
    @Binding var download: Download
    var retry: (Download) -> Void
    
    var body: some View {
        HStack {
            if download.status == DownloadStatus.pending {
                Image(systemName: "arrow.down.circle")
            } else if download.status == DownloadStatus.downloaded  {
                Image(systemName: "checkmark.circle.fill")
            } else if download.status == DownloadStatus.error {
                Image(systemName: "exclamationmark.triangle.fill")
            }

            Text(download.url)
                .lineLimit(1)

            Spacer()

            Picker("", selection: $download.quality) {
                Text("Normal").tag(Quality.normal)
                Text("Low").tag(Quality.low)
                Text("Extra Low").tag(Quality.extra_low)

            }
            .labelsHidden()

            if download.status == DownloadStatus.error || download.status == DownloadStatus.canceled {
                Button {
                    retry(download)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

class DownloadsQueueWindowManager {
    static let shared = DownloadsQueueWindowManager()
    private var window: NSWindow?
    
    func openWindow() {
        if window == nil {
            let hostingController = NSHostingController(rootView: DownloadsQueueView())
            
            window = NSWindow(contentViewController: hostingController)
            window?.title = ""
            window?.setContentSize(NSSize(width: 200, height: 150))
            window?.styleMask = [.titled, .closable, .miniaturizable]
            window?.resizeIncrements = NSSize(width: 0, height: 0)
            window?.standardWindowButton(.zoomButton)?.isEnabled = false
            window?.standardWindowButton(.zoomButton)?.isHidden = true
            window?.isReleasedWhenClosed = false
            window?.center()
            window?.makeKeyAndOrderFront(nil)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowWillClose),
                name: NSWindow.willCloseNotification,
                object: window
            )
        } else {
            window?.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func windowWillClose() {
        window = nil
    }
}
