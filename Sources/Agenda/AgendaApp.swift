import SwiftUI

@main
struct AgendaApp: App {
    @StateObject private var calendarService = CalendarService()

    var body: some Scene {
        WindowGroup {
            ContentView(calendarService: calendarService)
                .environmentObject(calendarService)
                .task {
                    await calendarService.requestAccessIfNeeded()
                }
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 700)
        #endif
    }
}
