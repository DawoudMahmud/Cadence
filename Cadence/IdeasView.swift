import SwiftUI
import SwiftData

struct IdeasView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Idea.createdAt, order: .reverse) private var ideas: [Idea]

    @State private var showingAddSheet = false

    private func ideas(for status: IdeaStatus) -> [Idea] {
        ideas.filter { $0.status == status }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(IdeaStatus.allCases) { status in
                        column(for: status)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Ideas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("New idea", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddIdeaSheet()
            }
            .overlay {
                if ideas.isEmpty {
                    ContentUnavailableView(
                        "No ideas yet",
                        systemImage: "lightbulb",
                        description: Text("Tap + to capture your first idea.")
                    )
                }
            }
        }
    }

    private func column(for status: IdeaStatus) -> some View {
        let items = ideas(for: status)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(status.displayName)
                    .font(.headline)
                Text("\(items.count)")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal)

            if items.isEmpty {
                Text("—")
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
            } else {
                ForEach(items) { idea in
                    IdeaCard(idea: idea)
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct IdeaCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var idea: Idea

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(idea.title)
                    .font(.body.weight(.semibold))
                Spacer()
                if let p = idea.platform {
                    Image(systemName: p.symbolName)
                        .foregroundStyle(.secondary)
                }
            }
            if !idea.notes.isEmpty {
                Text(idea.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                Picker("Status", selection: $idea.statusRaw) {
                    ForEach(IdeaStatus.allCases) { s in
                        Text(s.displayName).tag(s.rawValue)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
                Button(role: .destructive) {
                    modelContext.delete(idea)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AddIdeaSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var platform: Platform? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Idea") {
                    TextField("Title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Platform (optional)") {
                    Picker("Platform", selection: $platform) {
                        Text("Either").tag(Platform?.none)
                        ForEach(Platform.allCases) { p in
                            Text(p.displayName).tag(Optional(p))
                        }
                    }
                }
            }
            .navigationTitle("New idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let idea = Idea(title: title, notes: notes, platform: platform)
        modelContext.insert(idea)
        dismiss()
    }
}

#Preview {
    IdeasView()
        .modelContainer(for: [StatSnapshot.self, Idea.self], inMemory: true)
}
