import SwiftUI
import PhotosUI
import SwiftData

struct CreateReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var syncCoordinator: SyncCoordinator

    @Query private var friendLinks: [FriendLink]
    @Query(filter: #Predicate<UserProfile> { $0.isCurrentUser }) private var currentUsers: [UserProfile]

    @StateObject private var locationService = LocationService()

    @State private var costText = ""
    @State private var currencyCode = "USD"
    @State private var rating = 4
    @State private var reviewText = ""
    @State private var locationName = ""
    @State private var country = ""
    @State private var subRegion = ""
    @State private var locationType: LocationType = .urban
    @State private var purchasedItems: Set<PurchasedItem> = [.bigMac]
    @State private var selectedFriendAppleUserIDs: Set<String> = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var isSubmitting = false

    private var currentUser: UserProfile? { currentUsers.first }

    private var acceptedFriends: [FriendLink] {
        guard let appleUserID = currentUser?.appleUserID else { return [] }
        return friendLinks.filter {
            $0.ownerAppleUserID == appleUserID && $0.statusRaw == FriendLinkStatus.accepted.rawValue
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What did you order?") {
                    PurchasedItemsPicker(selection: $purchasedItems)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Price & Rating") {
                    HStack {
                        TextField("Cost", text: $costText)
                            .keyboardType(.decimalPad)
                        TextField("Currency", text: $currencyCode)
                            .frame(width: 70)
                            .textInputAutocapitalization(.characters)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quality Rating")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        StarRatingView(rating: rating, size: 28, interactive: true) { rating = $0 }
                    }
                    .padding(.vertical, 4)
                }

                Section("Location") {
                    Button {
                        locationService.requestLocation()
                    } label: {
                        Label(
                            locationService.isLoading ? "Detecting location…" : "Use Current Location",
                            systemImage: "location.fill"
                        )
                    }
                    .disabled(locationService.isLoading)

                    if let error = locationService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    TextField("Location name", text: $locationName)
                    TextField("Country", text: $country)
                    TextField("State / Region", text: $subRegion)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location Type")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        LocationTypePicker(selection: $locationType)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
                }

                Section("Photos") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                        Label("Add Photos", systemImage: "camera.fill")
                    }
                    .onChange(of: selectedPhotos) { _, newItems in
                        Task { await loadPhotos(from: newItems) }
                    }

                    if !photoData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(photoData.enumerated()), id: \.offset) { _, data in
                                    if let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Review") {
                    TextField("How was your Big Mac?", text: $reviewText, axis: .vertical)
                        .lineLimit(3...6)
                }

                if !acceptedFriends.isEmpty {
                    Section("Tag Friends") {
                        TagLinkedFriendsView(
                            friends: acceptedFriends,
                            selectedFriendAppleUserIDs: $selectedFriendAppleUserIDs
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                } else {
                    Section("Tag Friends") {
                        Text("Add accepted friends in Profile → Friends to tag them in reports.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Sharing") {
                    Text("Reports and meal photos sync to the global BMI public index via CloudKit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(BMIScreenBackground())
            .navigationTitle("New Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Saving…" : "Submit") {
                        Task { await submitReport() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSubmitting)
                }
            }
            .onChange(of: locationService.currentLocation) { _, location in
                guard let location else { return }
                locationName = location.name
                country = location.country
                subRegion = location.subRegion
                currencyCode = location.currencyCode
            }
            .alert("Missing Information", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        await MainActor.run { photoData = loaded }
    }

    private func submitReport() async {
        guard let currentUser else { return }

        guard let cost = Double(costText.replacingOccurrences(of: ",", with: ".")),
              cost > 0 else {
            validationMessage = "Enter a valid price for your meal."
            showValidationAlert = true
            return
        }

        guard !purchasedItems.isEmpty else {
            validationMessage = "Select at least one item you purchased."
            showValidationAlert = true
            return
        }

        guard !locationName.isEmpty, !country.isEmpty else {
            validationMessage = "Add a location or use current location detection."
            showValidationAlert = true
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let reportDate = Date()
        let snapshot = await PriceNormalizationService.captureUSDSnapshot(
            for: cost,
            currencyCode: currencyCode.uppercased(),
            on: reportDate
        )

        let latitude = locationService.currentLocation?.latitude ?? 0
        let longitude = locationService.currentLocation?.longitude ?? 0
        let taggedProfiles = acceptedFriends
            .filter { selectedFriendAppleUserIDs.contains($0.friendAppleUserID) }
            .compactMap { link -> UserProfile? in
                let descriptor = FetchDescriptor<UserProfile>(
                    predicate: #Predicate { $0.appleUserID == link.friendAppleUserID }
                )
                return try? modelContext.fetch(descriptor).first
            }

        let photos = photoData.enumerated().map { index, data in
            ReportPhoto(imageData: data, sortIndex: index)
        }

        let report = BigMacReport(
            cost: cost,
            currencyCode: currencyCode.uppercased(),
            rating: rating,
            reviewText: reviewText,
            purchasedItems: Array(purchasedItems),
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            country: country,
            subRegion: subRegion.isEmpty ? country : subRegion,
            locationType: locationType,
            createdAt: reportDate,
            usdAtReportDate: snapshot.usd,
            exchangeRateDate: snapshot.rateDate,
            authorAppleUserID: currentUser.appleUserID,
            taggedFriendAppleUserIDs: Array(selectedFriendAppleUserIDs),
            isPublic: true,
            author: currentUser,
            taggedFriends: taggedProfiles,
            photos: photos
        )

        modelContext.insert(report)
        try? modelContext.save()

        await syncCoordinator.uploadReport(report, author: currentUser, modelContext: modelContext)
        dismiss()
    }
}

#Preview {
    CreateReportView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(SyncCoordinator())
}
