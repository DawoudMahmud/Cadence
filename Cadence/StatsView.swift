import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StatSnapshot.date) private var snapshots: [StatSnapshot]

    @State private var showingLogSheet = false
    @State private var showingImportSheet = false
    @State private var selectedPlatform: Platform = .instagram

    private var filtered: [StatSnapshot] {
        snapshots.filter { $0.platform == selectedPlatform }
    }

    private var latestFollowers: Int {
        filtered.last?.followers ?? 0
    }

    private var followerDelta: Int? {
        guard filtered.count >= 2 else { return nil }
        return filtered[filtered.count - 1].followers - filtered[filtered.count - 2].followers
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Platform", selection: $selectedPlatform) {
                        ForEach(Platform.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    headlineCard
                    chartCard
                    historyCard
                }
                .padding(.vertical)
            }
            .navigationTitle("Cadence")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingLogSheet = true
                        } label: {
                            Label("Type manually", systemImage: "keyboard")
                        }
                        Button {
                            showingImportSheet = true
                        } label: {
                            Label("Import from screenshot", systemImage: "photo.badge.plus")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingLogSheet) {
                LogStatsSheet(defaultPlatform: selectedPlatform)
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportFromScreenshotSheet(defaultPlatform: selectedPlatform)
            }
        }
    }

    private var headlineCard: some View {
        VStack(spacing: 8) {
            Text("\(latestFollowers)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text("followers")
                .foregroundStyle(.secondary)
            if let delta = followerDelta {
                let symbol = delta >= 0 ? "arrow.up.right" : "arrow.down.right"
                let color: Color = delta >= 0 ? .green : .red
                Label("\(abs(delta)) since last", systemImage: symbol)
                    .foregroundStyle(color)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Followers over time")
                .font(.headline)
            if filtered.count < 2 {
                Text("Log at least two days to see a trend.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(filtered) { snap in
                    LineMark(
                        x: .value("Date", snap.date),
                        y: .value("Followers", snap.followers)
                    )
                    .interpolationMethod(.monotone)
                    PointMark(
                        x: .value("Date", snap.date),
                        y: .value("Followers", snap.followers)
                    )
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)
            if filtered.isEmpty {
                Text("No entries yet — tap + to log your first.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filtered.reversed()) { snap in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(snap.date, format: .dateTime.month().day().year())
                            Text("\(snap.followers) followers · \(snap.engagement) engagement")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            modelContext.delete(snap)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct LogStatsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var platform: Platform
    @State private var date: Date = .now
    @State private var followers: Int = 0
    @State private var posts: Int = 0
    @State private var engagement: Int = 0

    init(defaultPlatform: Platform) {
        _platform = State(initialValue: defaultPlatform)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Platform", selection: $platform) {
                    ForEach(Platform.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Section("Numbers") {
                    Stepper(value: $followers, in: 0...10_000_000, step: 1) {
                        Text("Followers: \(followers)")
                    }
                    TextField("Followers (exact)", value: $followers, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Posts this period", value: $posts, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Engagement (likes + comments)", value: $engagement, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Log stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let snap = StatSnapshot(date: date,
                                platform: platform,
                                followers: followers,
                                posts: posts,
                                engagement: engagement)
        modelContext.insert(snap)
        dismiss()
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [StatSnapshot.self, Idea.self], inMemory: true)
}
