import SwiftUI

struct ClickyTabView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)

            Text("Clicky")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Text("Local-key chat UI goes here.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }
}
