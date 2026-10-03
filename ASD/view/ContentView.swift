//
//  ContentView.swift
//  ASD
//
//  Created by Nazar Dydyn on 18.09.2026.
//

import SwiftUI

enum AppTab: Hashable {
    case labs
    case profile
}

struct ContentView: View {
    @State private var selection: AppTab = .labs

    var body: some View {
        TabView(selection: $selection) {
            Tab("Лабораторні", systemImage: "flask.fill", value: AppTab.labs) {
                LabsView()
            }
            Tab("Профіль", systemImage: "person.crop.circle.fill", value: AppTab.profile) {
                ProfileView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(StatsStore())
}
