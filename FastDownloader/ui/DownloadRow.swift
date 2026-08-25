//
//  DownloadRow.swift
//  FastDownloader
//
//  Created by Jose Fidalgo on 24-08-26.
//
import SwiftUI

struct DownloadRow: View {
    @Binding var download: Download
    var retry: (Download) -> Void
    var delete: (Download) -> Void
    
    var statusIcon: String {
        switch download.status {
            case .pending: return "arrow.down.circle"
            case .downloaded: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .canceled: return "xmark.circle.fill"
        }
    }
    var colorForStatus: Color {
        switch download.status {
            case .downloaded: return .green
            case .error: return .red
            case .canceled: return .secondary
            case .pending: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                delete(download)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Remove from list")
            
            HStack(spacing: 12) {
                
                Image(systemName: statusIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(colorForStatus)
                    .frame(width: 20)
                    .help(download.status == DownloadStatus.downloaded ? "" : ErrorHelper.parse(errors: download.errors).userMessage)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(download.title ?? download.url)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                    
                    
                    Picker("", selection: $download.quality) {
                        Text("Normal").tag(Quality.normal)
                        Text("Low").tag(Quality.low)
                        Text("Extra Low").tag(Quality.extra_low)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 110)
                    .controlSize(.small)
                    .disabled(download.status == DownloadStatus.downloaded)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                switch download.status {
                case .error, .canceled:
                    Button {
                        retry(download)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Retry download")
                case .downloaded:
                    Button {
                        if let fileURL = download.folderDir {
                            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                        }
                    } label: {
                        Image(systemName: "folder")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")
                default:
                    EmptyView()
                }
                
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            Divider()
        }
    }
}
