import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject private var navigationRouter: AppNavigationRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var reports: [BigMacReport]

    @State private var showCreateReport = false

    var body: some View {
        TabView(selection: $navigationRouter.selectedTab) {
            HomeView()
                .tabItem { Label("Feed", systemImage: "list.bullet.rectangle") }
                .tag(0)

            MapReportsView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(1)

            Color.clear
                .tabItem { Label("Report", systemImage: "plus.circle.fill") }
                .tag(2)

            StatisticsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(.bmiRed)
        .toolbarBackground(Color.bmiPaper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: navigationRouter.selectedTab) { _, newValue in
            if newValue == 2 {
                showCreateReport = true
                navigationRouter.selectedTab = 0
            }
        }
        .sheet(isPresented: $showCreateReport) {
            CreateReportView()
        }
        .sheet(isPresented: reportSheetBinding) {
            if let report = presentedReport {
                NavigationStack {
                    ReportDetailView(report: report)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") { navigationRouter.presentedReportID = nil }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: profileSheetBinding) {
            if let username = navigationRouter.presentedUsername {
                NavigationStack {
                    PublicUserProfileView(username: username)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") { navigationRouter.presentedUsername = nil }
                            }
                        }
                }
            }
        }
    }

    private var presentedReport: BigMacReport? {
        guard let id = navigationRouter.presentedReportID else { return nil }
        return reports.first { $0.id == id }
    }

    private var reportSheetBinding: Binding<Bool> {
        Binding(
            get: { navigationRouter.presentedReportID != nil },
            set: { if !$0 { navigationRouter.presentedReportID = nil } }
        )
    }

    private var profileSheetBinding: Binding<Bool> {
        Binding(
            get: { navigationRouter.presentedUsername != nil },
            set: { if !$0 { navigationRouter.presentedUsername = nil } }
        )
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AuthenticationService())
        .environmentObject(SyncCoordinator())
        .environmentObject(AppNavigationRouter.shared)
}
