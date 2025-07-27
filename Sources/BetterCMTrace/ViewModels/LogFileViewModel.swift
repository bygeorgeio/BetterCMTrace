//
//  LogFileViewModel.swift
//  BetterCMTrace
//
//  An observable controller responsible for loading one or more log
//  files, parsing them into `LogEntry` objects and keeping the data
//  up to date.  The view model periodically polls the underlying
//  files for modifications and merges their contents by timestamp.
//  Filtering based on a search string is handled by the view.

import Foundation
import Combine

/// View model for a group of log files.  Each instance can manage one
/// or more files; when multiple files are provided they are merged
/// into a single list sorted by timestamp.  Use `searchText` to
/// filter entries in the view and `followTail` to automatically
/// scroll to the latest entry when new data arrives.
public final class LogFileViewModel: ObservableObject {
    /// The list of file URLs managed by this view model.
    public let fileURLs: [URL]
    /// All parsed log entries from every file, sorted by timestamp.
    @Published public private(set) var entries: [LogEntry] = []
    /// The last modification date seen for each file.  Used to
    /// detect changes during polling.
    private var lastModified: [URL: Date] = [:]
    /// The polling timer.  When running, it checks for file updates
    /// every second.  We choose polling over file system events to
    /// avoid the complexity of dispatch sources and because log
    /// files are typically appended to rather than overwritten.
    private var pollingTimer: Timer?
    /// Whether to automatically scroll to the bottom of the view
    /// whenever new entries are appended.  Bound to a toggle in the
    /// UI.
    @Published public var followTail: Bool = true
    /// The user provided search text.  The view filters `entries`
    /// using this value but does not modify the underlying data.
    @Published public var searchText: String = ""

    public init(fileURLs: [URL]) {
        self.fileURLs = fileURLs
        self.loadAll()
        self.startPolling()
    }

    deinit {
        pollingTimer?.invalidate()
    }

    /// Trigger a manual reload of all files.  Parses each file
    /// sequentially on a background queue and updates `entries` on
    /// the main thread.
    public func loadAll() {
        DispatchQueue.global(qos: .userInitiated).async {
            var combined: [LogEntry] = []
            for url in self.fileURLs {
                let fileName = url.lastPathComponent
                do {
                    let data = try String(contentsOf: url)
                    let parsed = LogParser.parse(data, fileName: fileName)
                    combined.append(contentsOf: parsed)
                } catch {
                    // Append a synthetic error entry to inform the user.
                    let entry = LogEntry(timestamp: nil,
                                        rawTimestamp: nil,
                                        component: nil,
                                        severity: .error,
                                        message: "Failed to read \(fileName): \(error.localizedDescription)",
                                        fileName: fileName)
                    combined.append(entry)
                }
            }
            // Sort by timestamp when available; fall back to the order
            // encountered.  Entries without timestamps are placed
            // after those with timestamps.
            combined.sort { lhs, rhs in
                switch (lhs.timestamp, rhs.timestamp) {
                case let (l?, r?):
                    return l < r
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                default:
                    return false
                }
            }
            DispatchQueue.main.async {
                self.entries = combined
            }
        }
    }

    /// Begin polling the file modification dates.  If any file has
    /// changed since the last check, reload all entries.  The timer
    /// runs on the main run loop.
    private func startPolling() {
        // Record initial modification times.
        for url in fileURLs {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let mtime = attrs[.modificationDate] as? Date {
                lastModified[url] = mtime
            }
        }
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            var changed = false
            for url in self.fileURLs {
                guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                      let mtime = attrs[.modificationDate] as? Date else { continue }
                if let last = self.lastModified[url] {
                    if mtime > last {
                        changed = true
                        self.lastModified[url] = mtime
                    }
                } else {
                    self.lastModified[url] = mtime
                    changed = true
                }
            }
            if changed {
                self.loadAll()
            }
        }
    }
}
