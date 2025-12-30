import SwiftUI

struct ProgressBarView: View {
    let operation: String
    let current: Int
    let total: Int
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Text(operation)
                .font(.subheadline)
            
            ProgressView(value: Double(current), total: Double(total))
                .frame(width: 200)
            
            Text("\(current)/\(total)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            
            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
