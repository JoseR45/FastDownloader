//
//  interfaces.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 22-08-26.
//

import Foundation


struct Download: Identifiable, Hashable {
    let id = UUID()
    var url: String
    var quality: Quality
    var title: String? = nil
    var folderDir: URL? = nil
    var status: DownloadStatus = DownloadStatus.pending
    var errors: [String] = []
}
