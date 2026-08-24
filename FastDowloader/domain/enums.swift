//
//  enums.swift
//  FastDowloader
//
//  Created by Jose Fidalgo on 18-08-26.
//

import Foundation

enum Quality: String, CaseIterable, Identifiable {
    case normal, low, extra_low
    var id: Self { self }
}

enum DownloadStatus: String, CaseIterable, Identifiable{
    case pending, downloaded, canceled, error
    var id: Self { self }
}

enum DownloadError {
    case ytDlpNotFound
    case noInternetConnection
    case invalidURL
    case videoUnavailable
    case formatUnavailable
    case restrictedVideo
    case unknown

    var userMessage: String {
        switch self {
        case .ytDlpNotFound:
            return "The downloader is not available."

        case .noInternetConnection:
            return "There is no internet connection."

        case .invalidURL:
            return "The URL is not supported."

        case .videoUnavailable:
            return "The video is not available."

        case .formatUnavailable:
            return "The requested video quality is not available."

        case .restrictedVideo:
            return "This video is restricted or private."

        case .unknown:
            return "The video could not be downloaded."
        }
    }
}
