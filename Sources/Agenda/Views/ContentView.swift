import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject private var calendarService: CalendarService
    @StateObject private var planner: PlannerViewModel

    init(calendarService: CalendarService) {
        _planner = StateObject(wrappedValue: PlannerViewModel(calendarService: calendarService))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            CalendarFilterChips()
            Divider()
            content
        }
        .task { planner.loadVisibleRange() }
        .onChange(of: planner.mode) { planner.loadVisibleRange() }
        .sheet(isPresented: $planner.isCreatingActivity) {
            ActivityEditorView(planner: planner)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch planner.mode {
        case .day:
            DayView(planner: planner, day: planner.referenceDate.startOfDay)
        case .week:
            WeekView(planner: planner)
        }
    }

    private var header: some View {
        HStack {
            Button {
                Haptics.tap()
                planner.step(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Text(planner.headerTitle.capitalized)
                .font(.title2.bold())
                .frame(minWidth: 220)

            Button {
                Haptics.tap()
                planner.step(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }

            Spacer()

            Button("Aujourd'hui") {
                Haptics.tap()
                planner.goToToday()
            }

            Picker("Vue", selection: $planner.mode) {
                ForEach(PlannerMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .buttonStyle(.borderless)
        .padding()
    }
}
