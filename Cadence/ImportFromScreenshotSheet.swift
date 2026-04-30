import SwiftUI
import SwiftData
import PhotosUI

struct ImportFromScreenshotSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var platform: Platform
    @State private var date: Date = .now
    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var isProcessing = false
    @State private var parsed: ParsedStats?
    @State private var followers: Int = 0
    @State private var posts: Int = 0
    @State private var engagement: Int = 0
    @State private var errorMessage: String?

    init(defaultPlatform: Platform) {
        _platform = State(initialValue: defaultPlatform)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Platform", selection: $platform) {
                        ForEach(Platform.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Screenshot") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(image == nil ? "Choose screenshot" : "Choose another", systemImage: "photo")
                    }
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    if isProcessing {
                        HStack {
                            ProgressView()
                            Text("Reading numbers...")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section("Detected (edit if needed)") {
                    TextField("Followers", value: $followers, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Posts", value: $posts, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Engagement", value: $engagement, format: .number)
                        .keyboardType(.numberPad)
                    if let parsed, parsed.hasAnything {
                        let bits = [
                            parsed.followers.map { "Followers: \($0)" },
                            parsed.following.map { "Following: \($0)" },
                            parsed.posts.map { "Posts: \($0)" },
                            parsed.likes.map { "Likes: \($0)" },
                        ].compactMap { $0 }.joined(separator: " · ")
                        Text("OCR found — \(bits)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Import from screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(followers == 0)
                }
            }
            .task(id: pickerItem) {
                await loadAndParse()
            }
        }
    }

    private func loadAndParse() async {
        guard let pickerItem else { return }
        errorMessage = nil
        isProcessing = true
        defer { isProcessing = false }

        do {
            guard let data = try await pickerItem.loadTransferable(type: Data.self),
                  let ui = UIImage(data: data) else {
                errorMessage = "Could not load image."
                return
            }
            image = ui
            let result = await OCRService.parse(image: ui)
            parsed = result
            if let f = result.followers { followers = f }
            if let p = result.posts { posts = p }
            if let l = result.likes { engagement = l }
            if !result.hasAnything {
                errorMessage = "No numbers detected. You can still type them manually."
            }
        } catch {
            errorMessage = error.localizedDescription
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
