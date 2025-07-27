//
//  BetterCMTraceApp.swift
//  BetterCMTrace
//
//  The application entry point.  It simply hosts the `ContentView`
//  within a window group.  Additional menu commands could be added
//  here (for example a File ▸ Open… shortcut), but the default menu
//  includes standard commands such as Quit.

import SwiftUI

@main
struct BetterCMTraceApp: App {
    var body: some Scene {
        WindowGroup("BetterCMTrace") {
            ContentView()
        }
    }
}
