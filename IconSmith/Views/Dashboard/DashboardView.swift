import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Dashboard")
                    .font(.largeTitle.bold())
                
                if appState.recentActivity.isEmpty {
                    EmptyStateView()
                } else {
                    RecentActivitySection(entries: appState.recentActivity)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Get Started")
                .font(.title2.bold())
                .padding(.bottom, 8)
            
            SuggestedActionRow(
                icon: "folder.badge.plus",
                title: "Configure a folder to scan",
                subtitle: "Start by adding a project folder"
            )
            
            SuggestedActionRow(
                icon: "square.grid.2x2",
                title: "Browse icon library",
                subtitle: "50 curated icons ready to use"
            )
            
            SuggestedActionRow(
                icon: "wand.and.stars",
                title: "Generate a custom icon",
                subtitle: "Create unique icons with AI"
            )
            
            SuggestedActionRow(
                icon: "doc.badge.gearshape",
                title: "Create an icon preset",
                subtitle: "Map extensions to icons automatically"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct SuggestedActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: 500)
    }
}

struct RecentActivitySection: View {
    let entries: [ActivityEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title2.bold())
            
            LazyVStack(spacing: 8) {
                ForEach(entries.prefix(20)) { entry in
                    ActivityRow(entry: entry)
                }
            }
        }
    }
}

struct ActivityRow: View {
    let entry: ActivityEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.action.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.summary)
                    .font(.body)
                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
