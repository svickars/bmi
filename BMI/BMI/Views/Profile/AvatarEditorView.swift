import SwiftUI
import SwiftData

struct AvatarEditorView: View {
    let user: UserProfile
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @Environment(\.modelContext) private var modelContext

    @State private var style: AvatarStyle = .emoji
    @State private var emoji: String = "🍔"
    @State private var initials: String = ""
    @State private var backgroundHex: String = AvatarAppearance.defaultBackgroundHex(for: .emoji)
    @State private var isSaving = false

    private let emojiSuggestions = ["🍔", "🍟", "🥤", "✈️", "🗺️", "🌮", "🗼", "🦘", "🍜", "⭐️"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BMIAvatarView(
                    presentation: AvatarPresentation(
                        style: style,
                        emoji: emoji,
                        initials: initials,
                        backgroundHex: backgroundHex
                    ),
                    size: 96
                )
                .padding(.top, 8)

                Picker("Avatar Style", selection: $style) {
                    ForEach(AvatarStyle.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                BMICard {
                    VStack(alignment: .leading, spacing: 16) {
                        switch style {
                        case .emoji:
                            Text("Choose an emoji")
                                .font(BMITypography.ui(.subheadline, weight: .semibold))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                                ForEach(emojiSuggestions, id: \.self) { suggestion in
                                    Button {
                                        emoji = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                            .background(emoji == suggestion ? Color.bmiCream : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            TextField("Or type your own", text: $emoji)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: emoji) { _, newValue in
                                    if newValue.count > 4 {
                                        emoji = String(newValue.prefix(4))
                                    }
                                }
                        case .initials:
                            Text("Initials")
                                .font(BMITypography.ui(.subheadline, weight: .semibold))
                            TextField("SV", text: $initials)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .onChange(of: initials) { _, newValue in
                                    initials = AvatarAppearance.sanitizedInitials(newValue)
                                }
                            Text("Up to 2 letters or numbers.")
                                .font(BMITypography.ui(.caption))
                                .foregroundStyle(Color.bmiMuted)
                        }

                        Text("Background")
                            .font(BMITypography.ui(.subheadline, weight: .semibold))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                            ForEach(AvatarAppearance.presetBackgroundHexes, id: \.self) { hex in
                                Button {
                                    backgroundHex = hex
                                } label: {
                                    Circle()
                                        .fill(AvatarAppearance.backgroundColor(from: hex))
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            if backgroundHex == hex {
                                                Circle()
                                                    .strokeBorder(Color.bmiInk, lineWidth: 2)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                BMIPrimaryButton(title: isSaving ? "Saving…" : "Save Avatar", isLoading: isSaving) {
                    Task { await save() }
                }
            }
            .padding()
        }
        .background(BMIScreenBackground())
        .navigationTitle("Edit Avatar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            style = user.avatarStyle
            emoji = user.avatarEmoji
            initials = user.avatarInitials.isEmpty
                ? AvatarAppearance.defaultInitials(from: user.displayName)
                : user.avatarInitials
            backgroundHex = user.avatarBackgroundHex.isEmpty
                ? AvatarAppearance.defaultBackgroundHex(for: user.avatarStyle)
                : user.avatarBackgroundHex
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        user.avatarStyle = style
        user.avatarEmoji = emoji.isEmpty ? "🍔" : emoji
        user.avatarInitials = AvatarAppearance.sanitizedInitials(initials)
        user.avatarBackgroundHex = backgroundHex

        if user.isRegisteredPublicly {
            do {
                try await syncCoordinator.cloudSync.registerCurrentUser(user)
            } catch {
                syncCoordinator.lastError = error.localizedDescription
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AvatarEditorView(user: UserProfile(displayName: "Alex Morgan", username: "alexm"))
    }
    .modelContainer(PreviewData.previewContainer)
    .environmentObject(SyncCoordinator())
}
