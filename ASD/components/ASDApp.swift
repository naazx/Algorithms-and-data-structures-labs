//
//  ASDApp.swift
//  ASD
//
//  Created by Nazar Dydyn on 18.09.2026.
//

import SwiftUI

@main
struct ASDApp: App {
    @State private var stats = StatsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stats)
                .environment(\.locale, Format.locale)
        }
    }
}
