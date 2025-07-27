//
//  LogEntry.swift
//  BetterCMTrace
//
//  A simple data model representing a single log record.  Entries
//  contain the parsed timestamp (when available), the component
//  reporting the message, the severity and the full message text.  A
//  stable `id` is provided for use in SwiftUI lists and tables.
//

import Foundation

/// Represents the severity of a log entry.  Values mirror the
/// CMTrace enumeration (0: Unknown, 1: Information, 2: Warning,
/// 3: Error).  Conforms to `Comparable` for ease of sorting.
public enum LogSeverity: Int, Comparable, CaseIterable {
    case unknown = 0
    case information = 1
    case warning = 2
    case error = 3

    public static func < (lhs: LogSeverity, rhs: LogSeverity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    /// Returns a human friendly name.
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .information: return "Information"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

/// A parsed log entry.  The `timestamp` field is optional because
/// plain text lines may lack structured date information.  When
/// provided, `timestamp` stores the full `Date`.  The `rawTimestamp`
/// string retains the exact date/time text extracted from the log.
public struct LogEntry: Identifiable {
    public let id: UUID
    public let timestamp: Date?
    public let rawTimestamp: String?
    public let component: String?
    public let severity: LogSeverity
    public let message: String
    public let fileName: String?

    public init(timestamp: Date? = nil,
                rawTimestamp: String? = nil,
                component: String? = nil,
                severity: LogSeverity = .information,
                message: String,
                fileName: String? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.rawTimestamp = rawTimestamp
        self.component = component
        self.severity = severity
        self.message = message
        self.fileName = fileName
    }

    /// A non-optional timestamp used solely for sorting.  Entries without
    /// a timestamp are sorted to the beginning of the file using
    /// `.distantPast`.  You can modify this behaviour if you prefer
    /// plain text lines to appear at the end of the list.
    public var sortTimestamp: Date {
        timestamp ?? Date.distantPast
    }

    /// A non-optional component used for sorting.  Nil components sort
    /// as empty strings.
    public var sortComponent: String {
        component ?? ""
    }

    /// A non-optional severity value used for sorting.  Unknown
    /// severities sort before informational messages.
    public var sortSeverity: Int {
        severity.rawValue
    }

    /// A non-optional filename used for sorting.  Nil file names sort
    /// as empty strings.
    public var sortFileName: String {
        fileName ?? ""
    }
}
