//
//  LogView.swift
//  BetterCMTrace
//
//  Presents a single tab containing a searchable, sortable table of
//  log entries.  The table supports per‑column sorting via the
//  built in `Table` view on macOS.  A search field filters entries
//  across the message, component and severity fields.  A toggle
//  controls whether the view automatically scrolls to the latest
//  entry when new data arrives.

import SwiftUI

struct LogView: View {
    @ObservedObject var viewModel: LogFileViewModel
    // The current sort order for the table.  We default to
    // ascending timestamp (oldest first).
    @State private var sortOrder: [KeyPathComparator<LogEntry>] = [
        .init(\LogEntry.sortTimestamp, order: .forward)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Controls: search bar and follow tail toggle
            HStack {
                TextField("Search…", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 200, maxWidth: 300)
                Toggle("Follow Tail", isOn: $viewModel.followTail)
                    .toggleStyle(.switch)
                    .padding(.leading, 8)
                Spacer()
            }
            .padding([.horizontal, .top])

            Divider()

            // Table of log entries.  We compute the filtered and
            // sorted entries locally to decouple view state from the
            // underlying data.
            Table(filteredAndSortedEntries, sortOrder: $sortOrder) {
                TableColumn("Time", value: \LogEntry.sortTimestamp) { entry in
                    if let ts = entry.rawTimestamp {
                        Text(ts)
                    } else {
                        Text("—")
                    }
                }
                TableColumn("Severity", value: \LogEntry.sortSeverity) { entry in
                    HStack(spacing: 4) {
                        severityIndicator(for: entry.severity)
                        Text(entry.severity.description)
                    }
                }
                TableColumn("Component", value: \LogEntry.sortComponent) { entry in
                    Text(entry.component ?? "")
                }
                TableColumn("Message") { entry in
                    Text(entry.message)
                        .textSelection(.enabled)
                }
                TableColumn("File", value: \LogEntry.sortFileName) { entry in
                    Text(entry.fileName ?? "")
                }
            }
            .tableStyle(.inset(alternatingRowBackgrounds: true))
            .animation(.default, value: filteredAndSortedEntries.count)
        }
    }

    /// Returns the entries filtered by the current search text and
    /// sorted according to the active sort descriptors.  Filtering
    /// matches case‑insensitively on the message, component and
    /// severity description.
    private var filteredAndSortedEntries: [LogEntry] {
        let search = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = viewModel.entries
        let filtered: [LogEntry] = {
            guard !search.isEmpty else { return base }
            return base.filter { entry in
                let m = entry.message.lowercased()
                let c = entry.component?.lowercased() ?? ""
                let s = entry.severity.description.lowercased()
                return m.contains(search) || c.contains(search) || s.contains(search)
            }
        }()
        return filtered.sorted(using: sortOrder)
    }

    /// Renders a coloured bullet corresponding to the severity of the
    /// entry.  Red for errors, orange for warnings, grey for
    /// informational and unknown severities.
    private func severityIndicator(for severity: LogSeverity) -> some View {
        let colour: Color = {
            switch severity {
            case .error: return Color.red
            case .warning: return Color.orange
            case .information: return Color.primary.opacity(0.4)
            default: return Color.gray
            }
        }()
        return Circle()
            .fill(colour)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Preview

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for previewing the table.
        let sampleEntries: [LogEntry] = [
            LogEntry(timestamp: Date(), rawTimestamp: "07-27-2025 15:30:00.000", component: "SMSAgent", severity: .information, message: "Agent started.", fileName: "example.log"),
            LogEntry(timestamp: Date(), rawTimestamp: "07-27-2025 15:31:00.123", component: "SMSAgent", severity: .warning, message: "Potential issue detected.", fileName: "example.log"),
            LogEntry(timestamp: Date(), rawTimestamp: "07-27-2025 15:32:00.456", component: "SMSAgent", severity: .error, message: "Failed to connect to server.", fileName: "example.log")
        ]
        let vm = LogFileViewModel(fileURLs: [])
        vm.entries = sampleEntries
        return LogView(viewModel: vm)
    }
}
