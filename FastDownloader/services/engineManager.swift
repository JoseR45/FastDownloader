//
//  EngineManager.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 03-09-26.
//

import Foundation
import OSLog

private final class EngineDownloadDelegate: NSObject, URLSessionDownloadDelegate {

    private let logger = Logger.downloadManager

    var progressHandler: ((Double) -> Void)?
    var completionHandler: ((URL, URLResponse?) -> Void)?
    var errorHandler: ((Error) -> Void)?
    var destinationURL: URL?

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else {
            return
        }

        let progress =
            Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        progressHandler?(progress)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        do {
            guard let destinationURL else {
                throw NSError(
                    domain: "FastDownloader",
                    code: 3,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Engine destination URL is missing"
                    ]
                )
            }

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.moveItem(
                at: location,
                to: destinationURL
            )

            progressHandler?(1.0)

            completionHandler?(
                destinationURL,
                downloadTask.response
            )

        } catch {
            errorHandler?(error)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            errorHandler?(error)
        }
    }

    private var fileManager: FileManager {
        .default
    }
}


final class EngineManager: ObservableObject {
    
    private let logger = Logger.downloadManager
    
    static let shared = EngineManager()

    @Published var isUpdatingEngine = false
    @Published var engineUpdateProgress: Double = 0.0

    private init() {}


    private var fileManager: FileManager {
        .default
    }

    private var applicationSupportFolder: URL {
        fileManager
            .urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )
            .first!
            .appendingPathComponent(
                "FastDownloader",
                isDirectory: true
            )
    }

    // MARK: - Engine Path

    var engineURL: URL {
        applicationSupportFolder
            .appendingPathComponent("fast-downloader-engine")
    }

    var engineTempURL: URL {
        fileManager.temporaryDirectory
            .appendingPathComponent("fast-downloader-temp")
    }
    
    // MARK: - Engine Download URL
    
    func getAvailableEngineUpdateURL() async -> (url: URL, version: String)? {
        guard
            let remoteURL = URL(
                string: "https://github.com/JoseR45/fast-downloader-engine/raw/refs/heads/main/release.json"
            )
        else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                from: remoteURL
            )

            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                return nil
            }

            let remoteRelease = try JSONDecoder().decode(
                EngineRelease.self,
                from: data
            )

            guard
                let platformKey = currentPlatformKey(),
                let remotePlatform = remoteRelease.platforms[platformKey],
                let updateURL = URL(string: remotePlatform.url)
            else {
                return nil
            }
            
            let version = remoteRelease.version
            
            guard
                let localVersion = getInstalledEngineVersion()
            else {
                return (updateURL, version)
            }

            guard isVersionNewer(
                remoteRelease.version,
                than: localVersion
            ) else {
                NotificationSender.shared.send(
                    title: "Engine is up to date",
                    message: "No engine update is available."
                )
                return nil
            }

            return (updateURL, version)

        } catch {
            logger.error(
                "Could not check for engine update: \(error.localizedDescription)"
            )

            return nil
        }
    }
    
    // MARK: - Setup

    func prepareEngine() throws -> URL {
        try createFolderIfNeeded()

        if !fileManager.fileExists(atPath: engineURL.path) {
            try installBundledEngine()
            try setExecutablePermission()
        }

        try createEngineTempDirectory()

        return engineURL
    }

    // MARK: - Update

    func updateEngine() async throws {

        DispatchQueue.main.async {
            self.isUpdatingEngine = true
            self.engineUpdateProgress = 0.0

            NotificationCenter.default.post(
                name: .engineUpdateStarted,
                object: self
            )
        }
        
        defer {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.isUpdatingEngine = false
                self.engineUpdateProgress = 0.0

                NotificationCenter.default.post(
                    name: .engineUpdateEnded,
                    object: self
                )
            }
        }

        let temporaryEngineURL = fileManager.temporaryDirectory
            .appendingPathComponent("fast-downloader-engine-update")

        if fileManager.fileExists(atPath: temporaryEngineURL.path) {
            try fileManager.removeItem(at: temporaryEngineURL)
        }

        guard let update = await getAvailableEngineUpdateURL() else {
            return
        }

        let url = update.url
        let version = update.version
        

        let delegate = EngineDownloadDelegate()

        delegate.destinationURL = temporaryEngineURL

        delegate.progressHandler = { [weak self] progress in
            guard let self else { return }
            DispatchQueue.main.async {
                self.engineUpdateProgress = progress
            }
        }

        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil
        )

        let (_, response): (URL, URLResponse?) =
            try await withCheckedThrowingContinuation { continuation in

                delegate.completionHandler = { location, response in
                    continuation.resume(
                        returning: (location, response)
                    )
                }

                delegate.errorHandler = { error in
                    continuation.resume(
                        throwing: error
                    )
                }

                let task = session.downloadTask(with: url)
                task.resume()
            }

        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw NSError(
                domain: "FastDownloader",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Failed to download engine"
                ]
            )
        }

        try setExecutablePermission(
            at: temporaryEngineURL
        )

        removeQuarantine(at: temporaryEngineURL)

        if fileManager.fileExists(atPath: engineURL.path) {
            try fileManager.removeItem(at: engineURL)
        }

        try fileManager.moveItem(
            at: temporaryEngineURL,
            to: engineURL
        )
        
        try saveInstalledEngineRelease(
            version: version,
            url: url.absoluteString
        )

        logger.info("Engine updated successfully")
        
        NotificationSender.shared.send(
            title: "Engine updated",
            message: "Engine \(version) was successfully installed."
        )
    }

    // MARK: - Install

    private func installBundledEngine() throws {
        guard let bundledEngine = Bundle.main.url(
            forResource: "fast-downloader-engine",
            withExtension: nil
        ) else {
            throw NSError(
                domain: "FastDownloader",
                code: 100,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Bundled engine not found"
                ]
            )
        }

        try fileManager.copyItem(
            at: bundledEngine,
            to: engineURL
        )

        logger.info("Engine copied successfully")
    }

    // MARK: - Permissions

    private func setExecutablePermission() throws {
        try setExecutablePermission(at: engineURL)
    }

    private func setExecutablePermission(at url: URL) throws {
        try fileManager.setAttributes(
            [
                .posixPermissions: 0o755
            ],
            ofItemAtPath: url.path
        )
    }

    // MARK: - Temporary Directory

    private func createEngineTempDirectory() throws {
        try fileManager.createDirectory(
            at: engineTempURL,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Version
    
    private func saveInstalledEngineRelease(
        version: String,
        url: String
    ) throws {

        let releaseURL = applicationSupportFolder
            .appendingPathComponent("release.json")

        var releases: [String: InstalledEngineRelease] = [:]

        if let data = try? Data(contentsOf: releaseURL) {
            releases = (try? JSONDecoder().decode(
                [String: InstalledEngineRelease].self,
                from: data
            )) ?? [:]
        }

        let timestamp = ISO8601DateFormatter().string(
            from: Date()
        )

        releases[timestamp] = InstalledEngineRelease(
            version: version,
            url: url
        )

        let data = try JSONEncoder().encode(releases)

        try data.write(
            to: releaseURL,
            options: .atomic
        )
    }
    
    private func getInstalledEngineVersion() -> String? {
        getLatestInstalledEngineRelease()?.version
    }
    
    private func getLatestInstalledEngineRelease()
        -> InstalledEngineRelease? {

        let releaseURL = applicationSupportFolder
            .appendingPathComponent("release.json")

        guard
            let data = try? Data(contentsOf: releaseURL),
            let releases = try? JSONDecoder().decode(
                [String: InstalledEngineRelease].self,
                from: data
            )
        else {
            return nil
        }

        return releases.max(
            by: { $0.key < $1.key }
        )?.value
    }
    
    private func isVersionNewer(
        _ remote: String,
        than local: String
    ) -> Bool {

        let remoteParts = remote
            .split(separator: ".")
            .compactMap { Int($0) }

        let localParts = local
            .split(separator: ".")
            .compactMap { Int($0) }

        let count = max(remoteParts.count, localParts.count)

        for index in 0..<count {
            let remoteValue =
                index < remoteParts.count ? remoteParts[index] : 0

            let localValue =
                index < localParts.count ? localParts[index] : 0

            if remoteValue > localValue {
                return true
            }

            if remoteValue < localValue {
                return false
            }
        }

        return false
    }

    // MARK: - Helpers

    private func createFolderIfNeeded() throws {
        try fileManager.createDirectory(
            at: applicationSupportFolder,
            withIntermediateDirectories: true
        )
    }

    private func removeQuarantine(at url: URL) {
        let process = Process()

        process.executableURL = URL(
            fileURLWithPath: "/usr/bin/xattr"
        )

        process.arguments = [
            "-d",
            "com.apple.quarantine",
            url.path
        ]

        try? process.run()
        process.waitUntilExit()
    }
    
    // MARK: - Platform

    private func currentPlatformKey() -> String? {
            #if arch(x86_64)
            return "macos_x86_64"
            #elseif arch(arm64)
            return "macos_arm64"
            #else
            return nil
            #endif
    }
}
