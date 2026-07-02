import SwiftUI
import MapKit
import SwiftData

struct MapReportsView: View {
    @Query private var reports: [BigMacReport]
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedReport: BigMacReport?

    private var validReports: [BigMacReport] {
        reports.filter { $0.latitude != 0 || $0.longitude != 0 }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition, selection: $selectedReport) {
                    ForEach(validReports, id: \.id) { report in
                        Annotation(report.locationName, coordinate: report.coordinate) {
                            MapPinView(cost: report.formattedCost, rating: report.rating)
                        }
                        .tag(report)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .onAppear {
                    if let first = validReports.first {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: first.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
                        ))
                    }
                }

                if let selected = selectedReport {
                    NavigationLink {
                        ReportDetailView(report: selected)
                    } label: {
                        ReportCardView(report: selected)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(BMIScreenBackground())
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut, value: selectedReport?.id)
        }
    }
}

struct MapPinView: View {
    let cost: String
    let rating: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(cost)
                .font(BMITypography.data(11, weight: .bold))
                .foregroundStyle(Color.bmiRed)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.bmiSurface)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color.bmiBorder, lineWidth: 1)
                }
            StarRatingView(rating: rating, size: 8)
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

#Preview {
    MapReportsView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AppNavigationRouter.shared)
}
