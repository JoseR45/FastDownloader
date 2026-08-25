//
//  downloader.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 13-08-26.
//
import Foundation
import OSLog

class VideoDownloader: ObservableObject {
    static let shared = VideoDownloader()
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var currentURL = ""
    @Published var downloadSpeed = ""
    @Published var estimatedTime = ""
    @Published var downloadedSize = ""
    @Published var downloadedProgress = ""
    @Published var downloadQueue: [Download] = []
    @Published var downloadedQueue: [Download] = []
    @Published var currentVideoTitle = ""
    
    private var isCancelled = false
    private var process: Process?
    private var currentDownload: Download?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private let logger = Logger.downloadManager
    private var LogBuffer: [String] = []
    
    private init() { }
    
    
    // Helpers
    private func getDownloadPath() -> String {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let fastDownloaderFolder = homeDirectory.appendingPathComponent("FastDownloader")
        return "\(fastDownloaderFolder.path)/%(title)s.%(ext)s"
    }
    
    private func splitSizeAndUnit(_ sizeString: String) -> (value: Double, unit: String)? {
        let pattern = "([\\d.]+)\\s*(KiB|MiB|GiB)"
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: sizeString, range: NSRange(sizeString.startIndex..., in: sizeString)) {
            
            if let numberRange = Range(match.range(at: 1), in: sizeString),
               let unitRange = Range(match.range(at: 2), in: sizeString) {
                
                let number = String(sizeString[numberRange])
                let unit = String(sizeString[unitRange])
                
                if let value = Double(number) {
                    return (value, unit)
                }
            }
        }
        
        return nil
    }
    private func formatSize(value: Double, unit: String) -> String {
        let bytes: Double
        switch unit {
        case "KiB":
            bytes = value * 1024
        case "MiB":
            bytes = value * 1024 * 1024
        case "GiB":
            bytes = value * 1024 * 1024 * 1024
        default:
            bytes = value
        }
        
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func getArgumentsForQuality(url: String, downloadPath: String, quality: Quality) -> [String] {
        var arguments = [
            url,
            "-o", downloadPath,
            "--merge-output-format", "mp4",
            "--no-playlist",
            "--progress",
            "--verbose",
            "--newline",
        ]
        
        switch quality {
        case .normal:
               logger.info("Download NORMAL quality")
               arguments.append(contentsOf: [
                   "-f", "best[ext=mp4]/best"
               ])
               
           case .low:
               logger.info("Download LOW quality")
               arguments.append(contentsOf: [
                   "-f", "best[height<=480][ext=mp4]/best[height<=480]/best"
               ])
               
           case .extra_low:
               logger.info("Download EXTRA_LOW quality")
               arguments.append(contentsOf: [
                   "-f", "best[height<=360][ext=mp4]/best[height<=360]/best"
               ])        }
        
        return arguments
    }
    func getDownloadFolderURL(fullPath: String) -> URL {
        let cleanPath = fullPath.replacingOccurrences(of: "/%(title)s.%(ext)s", with: "")
        return URL(fileURLWithPath: cleanPath)
    }
    
    func getYtDlpPath() -> URL? {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let fastDLFolder = appSupport.appendingPathComponent("FastDownloader", isDirectory: true)
        
        try? fileManager.createDirectory(at: fastDLFolder, withIntermediateDirectories: true)
        
        let externalYtDlp = fastDLFolder.appendingPathComponent("yt-dlp")
        if !fileManager.fileExists(atPath: externalYtDlp.path) {
            if let bundledYtDlp = Bundle.main.path(forResource: "yt-dlp", ofType: nil, inDirectory: "yt-dlp") {
                try? fileManager.copyItem(atPath: bundledYtDlp, toPath: externalYtDlp.path)
                try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: externalYtDlp.path)
            }
        }
        return externalYtDlp
    }
    

    func downloadVideo(url: String, quality: Quality) {
        if isDownloading {
            DispatchQueue.main.async {
                self.downloadQueue.append(Download(url: url, quality: quality))
            }
            return
        }
        let downloadPath = getDownloadPath()
        var download = Download(url: url, quality: quality)
        
        
        currentDownload = download
        isDownloading = true
        progress = 0.0
        statusMessage = "Preparing download…"
        downloadSpeed = ""
        estimatedTime = ""
        downloadedSize = ""
        downloadedProgress = ""
        currentURL = url
        LogBuffer = []
        currentVideoTitle = ""
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let tempDir = FileManager.default.temporaryDirectory
            let ytDlpTemp = tempDir.appendingPathComponent("yt-dlp-temp")
               
            do {
                try FileManager.default.createDirectory(at: ytDlpTemp,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
                logger.info("Temporary directory created: \(ytDlpTemp.path)")
            } catch {
                logger.error("Could not create temporary directory: \(error)")
            }
            
            let process = Process()
            
            var environment = ProcessInfo.processInfo.environment
            environment["TMPDIR"] = ytDlpTemp.path
            environment["TEMP"] = ytDlpTemp.path
            environment["TMP"] = ytDlpTemp.path
            process.environment = environment
                    
            guard let ytDlpPath = getYtDlpPath() else {
                logger.error("yt-dlp not found in bundle")
                DispatchQueue.main.async {
                       self.isDownloading = false
                       self.statusMessage = "400"
                       download.status = DownloadStatus.error
                       download.errors = ["yt-dlp not found in bundle"]
                       self.processNextDownload(lastDownload: download)
                }
                return
            }
           
            process.environment = environment
            process.executableURL = ytDlpPath
            
            
            process.arguments = getArgumentsForQuality(url: url, downloadPath: downloadPath, quality: quality)
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    self?.parseProgress(output)
                }
            }
            
            errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                if let error = String(data: data, encoding: .utf8), !error.isEmpty {
                    self?.LogBuffer.append(error)
                }
            }
            
            self.process = process
            self.outputPipe = outputPipe
            self.errorPipe = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let alreadyDownloaded = self.LogBuffer.contains { $0.contains("has already been downloaded") }
                
                DispatchQueue.main.async {
                    self.isDownloading = false
                    
                    if process.terminationStatus == 0 || self.progress >= 1.0 || alreadyDownloaded {
                        self.statusMessage = "200"
                        download.status = DownloadStatus.downloaded
                        download.title = self.currentVideoTitle
                        download.folderDir = self.getDownloadFolderURL(fullPath: downloadPath)
                    } else if self.isCancelled {
                        self.isCancelled = false
                        self.statusMessage = "500"
                        download.errors = ["the download was canceled"]
                        download.status = DownloadStatus.canceled
                    } else {
                        self.statusMessage = "400"
                        download.status = DownloadStatus.error
                        download.errors = self.LogBuffer
                    }
                    
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                    
                    self.progress = 0.0
                    self.processNextDownload(lastDownload: download)
                    
                }
                
                
            } catch {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.statusMessage = "400"
                    self.logger.error("[Exception] \(error.localizedDescription)")
                    download.status = DownloadStatus.error
                    download.errors = self.LogBuffer
                    self.processNextDownload(lastDownload: download)
                }
            }
        }
        
    }
    
    private func processNextDownload(lastDownload: Download ) {
        DispatchQueue.main.async {
            self.downloadedQueue.append(lastDownload)
        }
        guard !isDownloading else { return }
        guard let download = downloadQueue.popLast() else { return }

        downloadVideo(
            url: download.url,
            quality: download.quality
        )
    }
    
    func retry(_ download: Download) {
        downloadedQueue.removeAll { $0.id == download.id }
        downloadVideo(url: download.url, quality: download.quality)
    }
    
    func removeDownload(_ download: Download) {
        downloadQueue.removeAll { $0.id == download.id }
        downloadedQueue.removeAll { $0.id == download.id }
    }
    
    private func parseProgress(_ output: String) {
        let lines = output.split(separator: "\n")
        
        var currentPercent: Double = 0.0
        var totalSizeValue: Double = 0.0
        var totalSizeUnit: String = ""
        
        for line in lines {
            let lineStr = String(line)
            currentPercent = 0.0
            totalSizeValue = 0.0
            totalSizeUnit  = ""

            
            if let range = lineStr.range(of: "\\d+\\.?\\d*%", options: .regularExpression) {
                let percentStr = String(lineStr[range]).replacingOccurrences(of: "%", with: "")
                if let percent = Double(percentStr) {
                    currentPercent = percent
                    DispatchQueue.main.async {
                        self.progress = percent / 100.0
                    }
                }
            }
            
            if lineStr.contains("MiB/s") || lineStr.contains("KiB/s") {
                if let speedRange = lineStr.range(of: "[\\d.]+\\s*(MiB|KiB)/s", options: .regularExpression) {
                    let speed = String(lineStr[speedRange])
                    DispatchQueue.main.async {
                        self.downloadSpeed = speed
                    }
                }
            }
 
            if lineStr.contains("of") {
                if let ofRange = lineStr.range(of: "of\\s+~?\\s*[\\d.]+\\s*(KiB|MiB|GiB)", options: .regularExpression) {
                    let sizePart = String(lineStr[ofRange])
                    var cleanSize = sizePart.replacingOccurrences(of: "of ", with: "").trimmingCharacters(in: .whitespaces)
                    cleanSize = cleanSize.replacingOccurrences(of: "~", with: "").trimmingCharacters(in: .whitespaces)
        
                    if let (value, unit) = splitSizeAndUnit(cleanSize) {
                        totalSizeValue = value
                        totalSizeUnit = unit
                    }

                    DispatchQueue.main.async {
                        self.downloadedSize = cleanSize
                    }
                }
            }
            
            if currentPercent > 0 && totalSizeValue > 0 {
                let downloadedValue = (currentPercent / 100.0) * totalSizeValue
                let downloadedFormatted = formatSize(value: downloadedValue, unit: totalSizeUnit)
                DispatchQueue.main.async {
                    self.downloadedProgress = "\(downloadedFormatted)"
                }
            }
            
            if lineStr.contains("[download]") {
                DispatchQueue.main.async {
                    self.statusMessage = "60"
                }
            }
            
            if lineStr.contains("Downloading") || lineStr.contains("Checking") {
                if let range = lineStr.range(of: ":\\s*(.*)", options: .regularExpression) {
                    var text = String(lineStr[range])
                    text = text.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
                    DispatchQueue.main.async {
                        self.statusMessage = text
                    }
                }
            }
            
            if lineStr.contains("[download] Destination:") {
                let path = lineStr.replacingOccurrences(of: "[download] Destination: ", with: "")
                   let cleanTitle = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                   DispatchQueue.main.async {
                       self.currentVideoTitle = cleanTitle
                   }
            }
        }
    }
    
    func cancelDownload() {
        isCancelled = true
        process?.terminate()
        process = nil
    }
}


