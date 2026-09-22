import SwiftUI
import EventKit

struct ActivityEditorView: View {
    @EnvironmentObject private var calendarService: CalendarService
    @ObservedObject var planner: PlannerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(3600)
    @State private var selectedCalendar: EKCalendar?
    @State private var errorMessage: String?

    private var isEditing: Bool { planner.editingEvent != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Activité") {
                    TextField("Titre", text: $title)
                    DatePicker("Début", selection: $start, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Fin", selection: $end, in: start..., displayedComponents: [.date, .hourAndMinute])
                }

                Section("Couleur / calendrier") {
                    calendarPicker
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                if isEditing {
                    Section {
                        Button("Supprimer", role: .destructive, action: delete)
                    }
                }
            }
            .navigationTitle(isEditing ? "Modifier" : "Nouvelle activité")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedCalendar == nil)
                }
            }
        }
        .onAppear(perform: populate)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
    }

    private var calendarPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
            ForEach(calendarService.calendars.filter(\.allowsContentModifications), id: \.calendarIdentifier) { calendar in
                let isSelected = selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
                Button {
                    Haptics.tap()
                    selectedCalendar = calendar
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(calendarService.color(for: calendar))
                            .frame(width: 10, height: 10)
                        Text(calendar.title)
                            .font(.footnote)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? calendarService.color(for: calendar).opacity(0.2) : Color.gray.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? calendarService.color(for: calendar) : .clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func populate() {
        if let event = planner.editingEvent {
            title = event.title ?? ""
            start = event.startDate
            end = event.endDate
            selectedCalendar = event.calendar
        } else {
            title = ""
            start = planner.draftStart
            end = planner.draftEnd
            selectedCalendar = calendarService.defaultCalendarForNewActivities
                ?? calendarService.calendars.first(where: \.allowsContentModifications)
        }
    }

    private func save() {
        guard let calendar = selectedCalendar else { return }
        do {
            if let event = planner.editingEvent {
                try calendarService.update(event, title: title, start: start, end: end, calendar: calendar)
            } else {
                try calendarService.createActivity(title: title, start: start, end: end, calendar: calendar)
            }
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete() {
        guard let event = planner.editingEvent else { return }
        do {
            try calendarService.delete(event)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
