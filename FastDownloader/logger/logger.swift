//
//  logger.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 18-08-26.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.fastdownloader.app"
    static let app = Logger(subsystem: subsystem, category: "App")
    static let videoDownloader = Logger(subsystem: subsystem, category: "VideoDownloader")
    static let downloadManager = Logger(subsystem: subsystem, category: "DownloadManager")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let userInterface = Logger(subsystem: subsystem, category: "UI")
}
