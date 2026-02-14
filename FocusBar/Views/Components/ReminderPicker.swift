import SwiftUI

struct ReminderPicker: View {
    @Bindable var viewModel: RemindersViewModel

    var body: some View {
        VStack(spacing: 6) {
            if viewModel.isAuthorized {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(.secondary)
                    TextField("Search reminders...", text: $viewModel.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                        .accessibilityLabel("Search reminders")
                        .accessibilityHint("Type to filter your reminders")
                        .onChange(of: viewModel.searchQuery) {
                            Task { await viewModel.loadReminders() }
                        }
                }

                if let selected = viewModel.selectedReminder {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(selected.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Button("Clear") {
                            viewModel.selectedReminder = nil
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear selected reminder")
                        .accessibilityHint("Removes the linked reminder from this session")
                    }
                }

                if !viewModel.reminders.isEmpty && viewModel.selectedReminder == nil {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(viewModel.reminders.prefix(5)) { reminder in
                                Button {
                                    viewModel.selectedReminder = reminder
                                    viewModel.searchQuery = ""
                                    viewModel.reminders = []
                                } label: {
                                    Text(reminder.title)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .accessibilityLabel(reminder.title)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 80)
                }

                HStack {
                    TextField("Quick add task...", text: $viewModel.quickAddText)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                        .accessibilityLabel("Quick add task")
                        .accessibilityHint("Type a task name and press Return to create a new reminder")
                        .onSubmit {
                            Task { await viewModel.createQuickTask() }
                        }
                }
            } else {
                Button("Connect Apple Reminders") {
                    Task { await viewModel.requestAccess() }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .accessibilityHint("Requests permission to access your Apple Reminders")
            }
        }
    }
}
