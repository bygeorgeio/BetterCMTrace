//
//  LogParser.swift
//  BetterCMTrace
//
//  A lightweight parser for CMTrace formatted log files.  The
//  parser scans for XML‑like tags in the form:
//  `<![LOG[Message]LOG]!><time="HH:mm:ss.SSS" date="MM-dd-yyyy" component="Component" context="..." type="1" thread="TID" file="Ref">`
//  and extracts the message, date/time, component and severity.
//  Any lines that do not match the pattern are returned as raw
//  informational messages.  This parser is forgiving – if a value
//  cannot be parsed (for example an unknown severity or invalid date),
//  it falls back to sensible defaults.

import Foundation

public struct LogParser {
    /// Regular expression used to match CMTrace log entries.  The
    /// pattern captures eight groups:
    ///   1. Message text between `<![LOG[` and `]LOG]!>`
    ///   2. Time component (may include a UTC offset)
    ///   3. Date component
    ///   4. Component name
    ///   5. Context (ignored)
    ///   6. Severity type number
    ///   7. Thread id (ignored)
    ///   8. File reference (ignored)
    private static let pattern: NSRegularExpression = {
        let pattern = "<!\\[LOG\\[(.*?)\\]LOG\\]!>\\<time=\"(.*?)\"\\s+date=\"(.*?)\"\\s+component=\"(.*?)\"\\s+context=\"(.*?)\"\\s+type=\"(\d)\"\\s+thread=\"(\d+)\"\\s+file=\"(.*?)\">"
        // DotMatchesLineSeparators allows `.` to match newline characters.
        return try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
    }()

    /// Date formatter for microsecond resolution.
    private static let microsecondFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "MM-dd-yyyy HH:mm:ss.SSSSSSS"
        return fmt
    }()

    /// Date formatter for millisecond resolution.
    private static let millisecondFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "MM-dd-yyyy HH:mm:ss.SSS"
        return fmt
    }()

    /// Parse an entire file content into an array of `LogEntry` objects.
    /// - Parameters:
    ///   - content: The raw file contents as a `String`.
    ///   - fileName: The originating file name (used when merging files).
    /// - Returns: An array of `LogEntry` records, in the order they
    ///   appear in the input.
    public static func parse(_ content: String, fileName: String?) -> [LogEntry] {
        var entries: [LogEntry] = []
        // Break the content into lines.  We don't use native
        // String.lines here because we need to preserve the order and
        // handle multi‑line log records gracefully.  Splitting on
        // newline characters works for both Unix and Windows line
        // endings.
        let rawLines = content.split(omittingEmptySubsequences: false, whereSeparator: \Character.isNewline)
        for rawLine in rawLines {
            let line = String(rawLine)
            entries.append(parseLine(line, fileName: fileName))
        }
        return entries
    }

    /// Parse a single line.  If the line matches the CMTrace pattern
    /// then return a structured entry; otherwise return a generic
    /// informational entry with the raw message.
    private static func parseLine(_ line: String, fileName: String?) -> LogEntry {
        let range = NSRange(location: 0, length: line.utf16.count)
        if let match = pattern.firstMatch(in: line, options: [], range: range) {
            // Extract capture groups.  Use optional binding to safely
            // unwrap results.  The regex uses greedy matching, so
            // groups should always exist when a match is found.
            func substring(from range: NSRange) -> String? {
                guard let r = Range(range, in: line) else { return nil }
                return String(line[r])
            }
            let message = substring(from: match.range(at: 1)) ?? ""
            let timeString = substring(from: match.range(at: 2)) ?? ""
            let dateString = substring(from: match.range(at: 3)) ?? ""
            let component = substring(from: match.range(at: 4))
            let typeString = substring(from: match.range(at: 6)) ?? "1"
            // Combine date and time.  Remove any UTC offset such as `+60` or `-001` from the time.
            let trimmedTime: String = {
                // Look for a plus or minus sign followed by digits at the end of the time string
                if let plusRange = timeString.range(of: "\\+[0-9]+", options: .regularExpression) {
                    return String(timeString[..<plusRange.lowerBound])
                }
                if let minusRange = timeString.range(of: "\\-[0-9]+", options: .regularExpression) {
                    return String(timeString[..<minusRange.lowerBound])
                }
                return timeString
            }()
            let combined = dateString + " " + trimmedTime
            var timestamp: Date? = nil
            if let dt = microsecondFormatter.date(from: combined) {
                timestamp = dt
            } else if let dt = millisecondFormatter.date(from: combined) {
                timestamp = dt
            }
            // Parse severity number
            let severityValue = Int(typeString) ?? 1
            let severity = LogSeverity(rawValue: severityValue) ?? .unknown
            return LogEntry(timestamp: timestamp,
                            rawTimestamp: combined,
                            component: component,
                            severity: severity,
                            message: message,
                            fileName: fileName)
        } else {
            // Fallback: treat as plain text message.  Derive severity
            // heuristically by inspecting the text.  This helps
            // highlight warnings and errors in plain log files.
            let lower = line.lowercased()
            let severity: LogSeverity = {
                if lower.contains("error") { return .error }
                if lower.contains("warning") { return .warning }
                return .information
            }()
            return LogEntry(timestamp: nil,
                            rawTimestamp: nil,
                            component: nil,
                            severity: severity,
                            message: line,
                            fileName: fileName)
        }
    }
}
