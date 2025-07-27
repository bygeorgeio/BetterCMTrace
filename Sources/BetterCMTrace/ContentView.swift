//
//  ContentView.swift
//  BetterCMTrace
//
//  The root view of BetterCMTrace.  It provides a toolbar for
//  opening log files and displays each file (or merged group of
//  files) in its own tab.  When there are no open documents the
//  user is prompted to select files.

import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Represents a single open log document.  A document may be backed
/// by one file or a collection of files merged together.  The
/// `viewModel` property drives the UI for that tab.
private struct LogDocument: Identifiable {
    let id: UUID = UUID()
    let viewModel: LogFileViewModel
    let name: String

    init(urls: [URL]) {
        self.viewModel = LogFileViewModel(fileURLs: urls)
        if urls.count == 1 {
            self.name = urls.first?.lastPathComponent ?? "Untitled"
        } else {
            // When multiple files are opened at once, group them
            // under a descriptive label.
            let baseNames = urls.map { $0.lastPathComponent }.joined(separator: ", ")
            self.name = "Merged (\(baseNames))"
        }
    }
}

struct ContentView: View {
    /// The collection of open documents displayed as tabs.
    @State private var documents: [LogDocument] = []
    /// The identifier of the selected tab.
    @State private var selectedDocID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar: file open button anchored at leading edge.
            HStack {
                Button(action: openFiles) {
                    Label("Open…", systemImage: "folder.badge.plus")
                }
                .help("Open one or more log files")
                Spacer()
            }
            .padding([.horizontal, .top])

            Divider()

            // Main area: either show an empty prompt or a tab view.
            if documents.isEmpty {
                VStack {
                    Spacer()
                    Text("Select \u201cOpen…\u201d to choose log files.")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                TabView(selection: $selectedDocID) {
                    ForEach(documents) { doc in
                        LogView(viewModel: doc.viewModel)
                            .tabItem { Text(doc.name) }
                            .tag(doc.id)
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    /// Presents an open panel allowing the user to select log files.
    /// When multiple files are selected they are merged into a single
    /// document.  Each subsequent call creates a new tab.
    private func openFiles() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.allowedContentTypes = nil // allow any extension
        if panel.runModal() == .OK {
            guard !panel.urls.isEmpty else { return }
            let urls = panel.urls
            let doc = LogDocument(urls: urls)
            documents.append(doc)
            selectedDocID = doc.id
        }
        #endif
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
