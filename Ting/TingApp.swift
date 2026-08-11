//
//  TingApp.swift
//  Ting
//
//  Created by Nicole Kong Mei Ning on 27/07/2026.
//

import SwiftUI

@main
struct TingApp: App {
    @StateObject private var store = LessonStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                SpeakView()
                    .tabItem { Label("Speak", systemImage: "mic") }
                LessonsView()
                    .tabItem { Label("Lessons", systemImage: "book") }
                WordsView()
                    .tabItem { Label("Words", systemImage: "star") }
                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar") }
            }
            .tint(Color.primaryAccent)
            .fontDesign(.rounded)
            .environmentObject(store)
        }
    }
}
