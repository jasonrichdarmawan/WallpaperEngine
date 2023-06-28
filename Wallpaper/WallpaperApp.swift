//
//  WallpaperApp.swift
//  Wallpaper
//
//  Created by Jason Rich Darmawan Onggo Putra on 29/06/23.
//

import SwiftUI

@main
struct WallpaperApp: App {
    @StateObject private var engine = WallpaperEngine()
    
    var body: some Scene {
        MenuBarExtra("App Menu Bar Extra", systemImage: "star") {
           
            Button("Toggle Wallpaper Engine") { engine.toggle() }
           
            Divider()

            Button("Exit") { NSApplication.shared.terminate(nil) }
        }
    }
}
