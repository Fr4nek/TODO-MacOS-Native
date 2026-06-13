//
//  TODOApp.swift
//  TODO
//
//  Created by Franek Makowski on 12/06/2026.
//

import SwiftUI

@main
struct TODOApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 320, height: 430)
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .windowSize) {}
        }
    }
}
