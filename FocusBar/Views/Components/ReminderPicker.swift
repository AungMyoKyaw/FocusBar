import SwiftUI

struct ReminderPicker: View {
    @Bindable var viewModel: RemindersViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.isAuthorized {
                if let selected = viewModel.selectedReminder {
                    selectedRow(selected)
                } else {
                    unselectedHeader
                    if isExpanded {
                        expandedPickerContent
                    }
                }
            } else {
                connectRow
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .focusCardSurface(cornerRadius: FocusBarTheme.controlCornerRadius)
    }

    private var connectRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Apple Reminders")
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                if viewModel.isDenied {
                    viewModel.openPrivacySettings()
                } else {
                    Task { await viewModel.requestAccess() }
                }
            } label: {
                Text(viewModel.isDenied ? "Open Settings" : "Connect")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Connect Apple Reminders")
            .accessibilityHint(viewModel.isDenied ? "Opens System Settings to allow Reminders access" : "Requests permission to access your Apple Reminders")
        }
    }

    private func selectedRow(_ selected: ReminderItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(FocusBarTheme.shortBreakAccent)

            Text(selected.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                viewModel.selectedReminder = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear selected reminder")
            .accessibilityHint("Removes the linked reminder from this session")
        }
    }

    private var unselectedHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isExpanded.toggle()
            }
            if isExpanded && viewModel.reminders.isEmpty {
                Task { await viewModel.loadReminders() }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Link a task...")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Link a task")
        .accessibilityHint("Expands reminder search and quick add")
    }

    private var expandedPickerContent: some View {
        VStack(spacing: 6) {
            TextField("Search reminders...", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .accessibilityLabel("Search reminders")
                .accessibilityHint("Type to filter your reminders")
                .onChange(of: viewModel.searchQuery) {
                    Task { await viewModel.loadReminders() }
                }

            if !viewModel.reminders.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.reminders.prefix(5)) { reminder in
                            Button {
                                viewModel.selectedReminder = reminder
                                viewModel.searchQuery = ""
                                viewModel.reminders = []
                                isExpanded = false
                            } label: {
                                Text(reminder.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(reminder.title)
                        }
                    }
                }
                .frame(maxHeight: 84)
            }

            TextField("Quick add task...", text: $viewModel.quickAddText)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .accessibilityLabel("Quick add task")
                .accessibilityHint("Type a task name and press Return to create a new reminder")
                .onSubmit {
                    Task {
                        await viewModel.createQuickTask()
                        isExpanded = false
                    }
                }
        }
    }
}
