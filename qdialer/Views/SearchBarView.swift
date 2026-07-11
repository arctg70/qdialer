import SwiftUI

// MARK: - Search Bar Display

struct SearchBarView: View {
    let text: String
    let resultCount: Int
    let isSearching: Bool
    let dialableNumber: String?
    let onDial: (() -> Void)?

    init(text: String, resultCount: Int, isSearching: Bool,
         dialableNumber: String? = nil, onDial: (() -> Void)? = nil) {
        self.text = text
        self.resultCount = resultCount
        self.isSearching = isSearching
        self.dialableNumber = dialableNumber
        self.onDial = onDial
    }

    var body: some View {
        VStack(spacing: 6) {
            // Input display area
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)

                Text(verbatim: text.isEmpty ? L.str("Type name initials to search…", "输入姓名首字母搜索…") : text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(text.isEmpty ? .gray.opacity(0.6) : .white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if dialableNumber != nil {
                    Spacer().frame(width: 4)
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    L.text("Dial", "拨打")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                } else if !text.isEmpty {
                    Image(systemName: "cursorarrow.click")
                        .font(.system(size: 12))
                        .foregroundColor(.green.opacity(0.6))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(dialableNumber != nil ? Color.green.opacity(0.08) : Color(white: 0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(dialableNumber != nil ? Color.green.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if dialableNumber != nil { onDial?() }
            }

            // Result count hint
            if isSearching {
                // Result count hint
                HStack(spacing: 4) {
                    Text("\(resultCount)")
                        .fontWeight(.bold)
                        .foregroundColor(resultCount > 0 ? .green : .gray)
                    Text(verbatim: L.str("contact", "个联系人"))
                        .foregroundColor(.gray)
                    if !L.isZh {
                        Text("found")
                            .foregroundColor(.gray.opacity(0.7))
                    }
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
        SearchBarView(text: "13800138000", resultCount: 0, isSearching: true,
                       dialableNumber: "13800138000")
    }
    .padding()
    .background(Color.black)
}
