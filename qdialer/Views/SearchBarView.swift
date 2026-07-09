import SwiftUI

// MARK: - Search Bar Display

struct SearchBarView: View {
    let text: String
    let resultCount: Int
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 6) {
            // Input display area
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)

                Text(text.isEmpty ? "Type name initials to search…" : text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(text.isEmpty ? .gray.opacity(0.6) : .white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !text.isEmpty {
                    Image(systemName: "cursorarrow.click")
                        .font(.system(size: 12))
                        .foregroundColor(.green.opacity(0.6))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )

            // Result count hint
            if isSearching {
                HStack(spacing: 4) {
                    Text("\(resultCount)")
                        .fontWeight(.bold)
                        .foregroundColor(resultCount > 0 ? .green : .gray)
                    Text(resultCount == 1 ? "contact" : "contacts")
                        .foregroundColor(.gray)
                    Text("found")
                        .foregroundColor(.gray.opacity(0.7))
                    Spacer()
                }
                .font(.caption)
                .padding(.leading, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
        .animation(.easeInOut(duration: 0.2), value: resultCount)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 20) {
        SearchBarView(text: "", resultCount: 0, isSearching: false)
        SearchBarView(text: "zs", resultCount: 3, isSearching: true)
        SearchBarView(text: "zhang san", resultCount: 1, isSearching: true)
    }
    .padding()
    .background(Color.black)
}
