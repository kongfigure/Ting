//
//  TingApp.swift
//  Ting
//
//  Created by Nicole Kong Mei Ning on 27/07/2026.
//

import SwiftUI
import FirebaseCore

@main
struct TingApp: App {
    @StateObject private var store = LessonStore()

    init() {
        // Without the plist, FirebaseApp.configure() throws an NSException
        // and crashes at launch — so only configure when it's present.
        if Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            FirebaseApp.configure()
        } else {
            print("⚠️ GoogleService-Info.plist missing — Firebase disabled, using local storage")
        }
    }

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
