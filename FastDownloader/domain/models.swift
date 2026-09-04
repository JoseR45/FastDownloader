//
//  models.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 03-09-26.
//

import Foundation

struct EngineRelease: Codable {
    let version: String
    let platforms: [String: EnginePlatform]
}

struct EnginePlatform: Codable {
    let file: String
    let url: String
    let components: EngineComponents
}

struct EngineComponents: Codable {
    let ytDlp: String
    let ffmpeg: String
    let deno: String

    enum CodingKeys: String, CodingKey {
        case ytDlp = "yt-dlp"
        case ffmpeg = "ffmpeg"
        case deno = "deno"
    }
}

struct InstalledEngineRelease: Codable {
    let version: String
    let url: String
}
