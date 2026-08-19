//
//  dowloader.swift
//  FastDowloader
//
//  Created by Jose Fidalgo on 13-08-26.
//
import Foundation
import OSLog

class VideoDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var currentURL = ""
    @Published var downloadSpeed = ""
    @Published var estimatedTime = ""
    @Published var downloadedSize = ""
    @Published var downloadedProgress = ""
    
    
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private let logger = Logger.downloadManager
    private var LogBuffer: [String] = []
    
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
            "--console-title", "false"
        ]
        
        switch quality {
            case .normal:
                logger.info("Download NORMAL quality")
                arguments.append(contentsOf: [
                    "-f", "bestvideo+bestaudio/best"
                ])
                
            case .low:
            logger.info("Download LOW quality")
                arguments.append(contentsOf: [
                    "-f", "bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480]/best",
                    "--recode-video", "mp4",
                    "--postprocessor-args", "-vf scale=854:480 -c:v libx264 -crf 28 -preset slow -maxrate 500k -bufsize 1000k -c:a aac -b:a 96k"
                ])
                
            case .extra_low:
            logger.info("Download EXTRA_LOW quality")
                arguments.append(contentsOf: [
                    "-f", "bestvideo[height<=360][ext=mp4]+bestaudio[ext=m4a]/best[height<=360]/worst",
                    "--recode-video", "mp4",
                    "--postprocessor-args", "-vf scale=640:360 -c:v libx264 -crf 32 -preset slow -maxrate 300k -bufsize 600k -c:a aac -b:a 64k"
                ])
        }
        
        return arguments
    }
    
    

    func downloadVideo(url: String, quality: Quality) {
        let downloadPath = getDownloadPath()
        
        isDownloading = true
        progress = 0.0
        statusMessage = "50"
        downloadSpeed = ""
        estimatedTime = ""
        downloadedSize = ""
        downloadedProgress = ""
        currentURL = url
        LogBuffer = []
        
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
                    
            guard let ytDlpPath = Bundle.main.path(forResource: "yt-dlp", ofType: nil, inDirectory: "yt-dlp") else {
                logger.error("yt-dlp not found in bundle")
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.statusMessage = "400"
                }
                return
            }
           
            process.environment = environment
            process.executableURL = URL(fileURLWithPath: ytDlpPath)
            
            
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
            
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let error = String(data: data, encoding: .utf8), !error.isEmpty {
                    self.LogBuffer.append(error)
                }
            }
            
            self.process = process
            self.outputPipe = outputPipe
            self.errorPipe = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let alreadyDownloaded = self.LogBuffer.contains { $0.contains("has already been downloaded") }
                print(self.LogBuffer)
                DispatchQueue.main.async {
                    self.isDownloading = false
                    if process.terminationStatus == 0 || self.progress >= 1.0 || alreadyDownloaded {
                        self.progress = 0.0
                        self.statusMessage = "200"
                    } else {
                        self.statusMessage = "400"
                    }
                    
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                }
                
                
            } catch {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.statusMessage = "400"
                    self.logger.error("[Exception] \(error.localizedDescription)")
                }
            }
        }
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

            if lineStr.contains("Merging") {
                DispatchQueue.main.async {
                    self.statusMessage = "100"
                }
            }
            
            if lineStr.contains("[download]") {
                DispatchQueue.main.async {
                    self.statusMessage = "60"
                }
            }
            
        }
    }
    
    func cancelDownload() {
        process?.terminate()
        process = nil
        DispatchQueue.main.async {
            self.isDownloading = false
            self.statusMessage = "500"
            self.progress = 0.0
        }
    }
}


