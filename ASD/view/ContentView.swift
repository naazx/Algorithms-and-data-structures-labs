//
//  ContentView.swift
//  ASD
//
//  Created by Nazar Dydyn on 18.09.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Лабораторна робота 1", destination: Lab1View())
                NavigationLink("Лабораторна робота 2", destination: Lab2View())
                NavigationLink("Лабораторна робота 3", destination: Text("Скоро"))
                NavigationLink("Лабораторна робота 4", destination: Text("Скоро"))
                NavigationLink("Лабораторна робота 5", destination: Text("Скоро"))
            }
            .navigationTitle("Лабораторні роботи")
        }
    }
}

#Preview {
    ContentView()
}
