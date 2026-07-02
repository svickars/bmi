import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreateReport = false

    var body: some View {
        TabView(selection: $selectedTab) {
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
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 2 {
                showCreateReport = true
                selectedTab = 0
            }
        }
        .sheet(isPresented: $showCreateReport) {
            CreateReportView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewData.previewContainer)
        .environmentObject(AuthenticationService())
        .environmentObject(SyncCoordinator())
}
