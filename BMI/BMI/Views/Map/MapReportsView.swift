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
            .navigationTitle("Map")
            .animation(.easeInOut, value: selectedReport?.id)
        }
    }
}

struct MapPinView: View {
    let cost: String
    let rating: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("🍔")
                .font(.caption)
            Text(cost)
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.bmiRed)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            StarRatingView(rating: rating, size: 8)
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 4)
    }
}

#Preview {
    MapReportsView()
        .modelContainer(PreviewData.previewContainer)
}
