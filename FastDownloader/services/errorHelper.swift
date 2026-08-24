//
//  errorHelper.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 23-08-26.
//

import Foundation

struct ErrorHelper {

    private static let invalidURLPatterns = [
        "is not a valid url",
        "unsupported url",
        "invalid url"
    ]

    private static let formatUnavailablePatterns = [
        "requested format is not available",
        "requested format is not available for this video"
    ]

    private static let videoUnavailablePatterns = [
        "video unavailable",
        "video is unavailable",
        "this video is unavailable"
    ]

    private static let restrictedVideoPatterns = [
        "private video",
        "sign in",
        "login required",
        "age-restricted"
    ]

    private static let networkPatterns = [
        "unable to download",
        "network is unreachable",
        "connection timed out",
        "connection refused",
        "connection reset",
        "temporary failure in name resolution"
    ]

    static func parse(errors: [String]) -> DownloadError {
        let output = errors
            .joined(separator: "\n")
            .lowercased()

        if output.contains("yt-dlp not found") {
            return .ytDlpNotFound
        }

        if invalidURLPatterns.contains(where: output.contains) {
            return .invalidURL
        }

        if formatUnavailablePatterns.contains(where: output.contains) {
            return .formatUnavailable
        }

        if videoUnavailablePatterns.contains(where: output.contains) {
            return .videoUnavailable
        }

        if restrictedVideoPatterns.contains(where: output.contains) {
            return .restrictedVideo
        }

        if networkPatterns.contains(where: output.contains) {
            return .noInternetConnection
        }

        return .unknown
    }
}
