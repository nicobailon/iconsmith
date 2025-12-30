import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Dashboard")
                    .font(.largeTitle.bold())
                
                if appState.recentActivity.isEmpty && appState.folders.isEmpty && appState.iconLibrary.icons.isEmpty {
                    EmptyStateView()
                } else {
                    StatsSection(appState: appState)
                    
                    if !appState.recentActivity.isEmpty {
                        RecentActivitySection(entries: appState.recentActivity)
                    } else {
                        NoActivityView()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

struct StatsSection: View {
    let appState: AppState
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Icons",
                value: "\(appState.iconLibrary.icons.count)",
                icon: "photo.on.rectangle",
                color: .blue
            )
            
            StatCard(
                title: "Folders",
                value: "\(appState.folders.count)",
                icon: "folder",
                color: .orange
            )
            
            StatCard(
                title: "Presets",
                value: "\(appState.presets.count)",
                icon: "doc.badge.gearshape",
                color: .purple
            )
            
            StatCard(
                title: "Applied",
                value: "\(totalApplied)",
                icon: "checkmark.circle",
                color: .green
            )
        }
    }
    
    var totalApplied: Int {
        appState.recentActivity
            .filter { $0.action == .applied || $0.action == .batchApplied }
            .reduce(0) { $0 + $1.fileCount }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct NoActivityView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No Recent Activity")
                .font(.headline)
            
            Text("Applied icons will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
                subtitle: "Start by adding a project folder",
                destination: .folders
            )
            
            SuggestedActionRow(
                icon: "square.grid.2x2",
                title: "Browse icon library",
                subtitle: "50 curated icons ready to use",
                destination: .library
            )
            
            SuggestedActionRow(
                icon: "wand.and.stars",
                title: "Generate a custom icon",
                subtitle: "Create unique icons with AI",
                destination: .generate
            )
            
            SuggestedActionRow(
                icon: "doc.badge.gearshape",
                title: "Create an icon preset",
                subtitle: "Map extensions to icons automatically",
                destination: .presets
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
    let destination: SidebarSection
    
    @State private var isHovering = false
    
    var body: some View {
        Button {
            NotificationCenter.default.post(name: .navigateToSection, object: destination)
        } label: {
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
            .background(isHovering ? .quaternary : .quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 500)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
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
