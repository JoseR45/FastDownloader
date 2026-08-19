//
//  PopoverView.swift
//  FastDowloader
//
//  Created by Jose Fidalgo on 13-08-26.
//
import SwiftUI

struct PanelView: View {
    @State private var urlText = ""
    @State private var message = ""
    @FocusState private var isFocused: Bool
    @State private var selectedQuality: Quality = .normal
    @StateObject private var downloadManager = VideoDownloader()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack{
                Text("Fast Downloader")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .symbolRenderingMode(.hierarchical)
                Image(systemName: "folder")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .symbolRenderingMode(.hierarchical)
                
                Divider()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .help("Close application")
            }
            Divider()
            
            HStack {
                TextField("Paste download URL here", text: $urlText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .onSubmit {
                        sendURLToDownload()
                    }
                
                Button(action: sendURLToDownload) {
                    Label("", systemImage: "arrow.down.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(urlText.isEmpty)
            }
            .disabled(downloadManager.isDownloading)
            
            HStack {
                Picker("Quality", selection: $selectedQuality) {
                    Text("Normal").tag(Quality.normal)
                    Text("Low").tag(Quality.low)
                    Text("Extra Low").tag(Quality.extra_low)
                }
            }
            .pickerStyle(.menu)
            .padding(.all, 5.0)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .accessibilityLabel("Quality Picker")
            .disabled(downloadManager.isDownloading)
            
            if downloadManager.isDownloading || downloadManager.progress > 0 {
                Divider()
                HStack {
                    Spacer()
                    Button(action: {
                        downloadManager.cancelDownload()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel download")
                }
                
                
                VStack(spacing: 4) {
                    HStack {
                        if downloadManager.statusMessage != "50" {
                            Text("\(Int(downloadManager.progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 40, alignment: .leading)
                        }
                        
                        if downloadManager.statusMessage == "50" {
                            MacProgressIndicator(
                                isIndeterminate: .constant(true),
                                progress: .constant(0.0),
                                color: .systemBlue
                            )
                            .frame(height: 12)
                            .padding(.vertical, 2)
                        } else {
                            ProgressView(value: downloadManager.progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .tint(Color.blue)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        }
                    }
                    
                    HStack {
                        if !downloadManager.downloadSpeed.isEmpty {
                            Text("Speed: \(downloadManager.downloadSpeed)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if !downloadManager.downloadedSize.isEmpty {
                            Text("\(downloadManager.downloadedProgress)/\(downloadManager.downloadedSize)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
    
    func sendURLToDownload() {
        let cleanText = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.isEmpty {
            downloadManager.statusMessage = "Please enter a URL first"
            return
        }
        
        downloadManager.downloadVideo(url: cleanText, quality: selectedQuality)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            urlText = ""
            message = ""
        }
    }
}

