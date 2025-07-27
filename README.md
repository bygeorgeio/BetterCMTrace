# BetterCMTrace

BetterCMTrace is an open–source log viewer for macOS inspired by
[CMTrace](https://learn.microsoft.com/en-us/intune/configmgr/core/support/cmtrace),
[Panda Log](https://github.com/bygeorgeio/Panda-Log) and the
[CmTrace](https://github.com/MarkusBux/CmTrace) project.  The goal of
BetterCMTrace is to provide a modern, native SwiftUI experience for
viewing SCCM/CMTrace formatted log files and plain text logs.  It
combines the real-time tailing and tabbed interface of Panda Log with
the structured parsing, highlighting and sorting capabilities of the
CmTrace project.

## Features

- **Multi-file viewer:** open one or more log files at the same time.  If
  you select multiple files they are merged into a single table and
  sorted by timestamp.  Alternatively you can open files in separate
  tabs via repeated selections.
- **Structured parsing:** entries written by the Configuration
  Manager tracing API (`<![LOG[...]]LOG]!>` records) are parsed into
  timestamp, component and severity fields.  Plain text lines are
  preserved verbatim.  A lightweight regular-expression based
  parser extracts the important fields without depending on
  pre-existing C/C++ code.  The parser falls back gracefully when a
  line does not match the CMTrace format.
- **Live tailing:** BetterCMTrace polls the underlying files for
  changes and appends new entries to the view.  When *Follow Tail* is
  enabled the table automatically scrolls to reveal the most recent
  lines.
- **Fast search and filter:** a built in search bar filters the
  currently displayed entries as you type.  Matches are applied to
  the message, component and severity columns.
- **Sorting:** click on the header of any column to sort ascending or
  descending.  Sorting works across merged files and respects
  timestamps when available.
- **Severity highlighting:** warning and error entries are
  highlighted with orange and red background colours respectively
  (similar to CMTrace’s colour scheme).  Informational messages use the
  default row background.
- **Tabs and windows:** each file (or merged group of files) is
  presented in its own tab.  You can also open a new window to view
  logs side by side.

## Building

This project is distributed as a Swift package.  You can open the
package directly in Xcode (File → Open) and run the `BetterCMTrace`
scheme.  The app requires macOS 13 or later.

If you prefer, run the following commands from a Terminal on a Mac
with the Swift toolchain installed:

```sh
git clone <repository-url>
cd BetterCMTrace
xcodebuild -scheme BetterCMTrace -configuration Release
```

Because this repository is unsigned, macOS Gatekeeper may warn the
first time you open the resulting app.  You can use the context menu
to select **Open** and confirm, or remove the quarantine attribute
with:

```sh
xattr -r -d com.apple.quarantine BetterCMTrace.app
```

## License

BetterCMTrace is released under the MIT license.  See [LICENSE](LICENSE)
for details.
