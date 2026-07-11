import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContactSearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            SearchBarView(
                text: viewModel.searchText,
                resultCount: viewModel.filteredContacts.count,
                isSearching: !viewModel.searchText.isEmpty,
                dialableNumber: viewModel.dialableNumber,
                onDial: { viewModel.callRawNumber(viewModel.dialableNumber ?? "") }
            )
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 8)

            resultsArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            KeyboardView(searchText: $viewModel.searchText)
        }
        .background(Color.black)
        .task { await viewModel.setup() }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.refreshFilter()
        }
        .alert(L.str("Contacts Access Required", "需要通讯录权限"),
               isPresented: $viewModel.showPermissionDenied) {
            Button(L.str("Open Settings", "打开设置")) {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button(L.str("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(verbatim: L.str("This app needs access to your contacts to search and dial.\n\nPlease enable Contacts in Settings → Privacy & Security.",
                                 "此应用需要访问您的通讯录才能搜索和拨号。\n\n请在 设置 → 隐私与安全 中开启通讯录权限。"))
        }
        .confirmationDialog(
            L.str("Select Number", "选择号码"),
            isPresented: $viewModel.showCallAlert,
            presenting: viewModel.selectedContact
        ) { contact in
            ForEach(contact.phoneNumbers, id: \.self) { number in
                Button(number) {
                    viewModel.callContact(contact, phoneNumber: number)
                }
            }
            Button(L.str("Cancel", "取消"), role: .cancel) {}
        } message: { contact in
            Text(verbatim: L.str("Choose a number for %@", "为 %@ 选择号码", contact.fullName))
        }
    }

    private var headerBar: some View {
        HStack {
            Image(systemName: "phone")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.green)
                .padding(6)
                .background(Circle().fill(Color.green.opacity(0.15)))

            L.text("Smart Dialer", "智能拨号")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            if viewModel.isAuthorized {
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("\(viewModel.contacts.count)").font(.caption).foregroundColor(.gray)
                }
            }

            Button { Task { await viewModel.loadContacts() } } label: {
                Image(systemName: "arrow.clockwise").font(.system(size: 13)).foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var resultsArea: some View {
        if viewModel.isLoading {
            Spacer()
            VStack(spacing: 12) {
                ProgressView().progressViewStyle(.circular).tint(.green)
                L.text("Loading contacts…", "正在加载通讯录…").font(.caption).foregroundColor(.gray)
            Spacer()
        } else if viewModel.showPermissionDenied {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "lock.shield").font(.system(size: 40)).foregroundColor(.gray)
                L.text("No Contact Access", "无法访问通讯录").font(.headline).foregroundColor(.white)
                L.text("Enable access in Settings to search contacts",
                       "请在设置中开启通讯录权限").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            Spacer()
        } else if !viewModel.searchText.isEmpty && viewModel.filteredContacts.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "person.slash").font(.system(size: 40)).foregroundColor(.gray.opacity(0.5))
                Text(verbatim: L.str("No contacts match \"%@\"",
                                     "没有联系人匹配 \"%@\"", viewModel.searchText))
                    .font(.body).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            Spacer()
        } else if !viewModel.filteredContacts.isEmpty {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        Color.clear.frame(height: 1).id("top")
                        ForEach(Array(viewModel.filteredContacts.enumerated()), id: \.element) { _, contact in
                            ContactRowView(contact: contact, isHighlighted: viewModel.selectedContact?.id == contact.id)
                                .onTapGesture {
                                    if viewModel.searchText.contains(where: \.isNumber)
                                        || contact.phoneNumbers.count == 1 {
                                        viewModel.callContact(contact)
                                    } else {
                                        viewModel.selectContact(contact)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollDismissesKeyboard(.immediately)
                .onChange(of: viewModel.filteredContacts.count) { _, _ in proxy.scrollTo("top", anchor: .top) }
            }
        } else if !viewModel.callHistory.isEmpty, viewModel.searchText.isEmpty {
            callHistoryView
        } else {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 44)).foregroundColor(.gray.opacity(0.4))
                VStack(spacing: 4) {
                    L.text("Start typing to find contacts", "输入关键词搜索联系人").font(.headline).foregroundColor(.white.opacity(0.7))
                    L.text("Supports pinyin initials, full pinyin,\nEnglish names & partial phone numbers",
                           "支持拼音首字母、全拼、英文名和号码搜索").font(.caption).foregroundColor(.gray.opacity(0.5)).multilineTextAlignment(.center)
                }
                HStack(spacing: 16) {
                    hintChip("zs → 张三")
                    hintChip("jd → John Doe")
                    hintChip(L.str("138 → Phone", "138 → 电话"))
                }
                .padding(.top, 4)
            }
            Spacer()
        }
    }

    // MARK: - Call History

    private var callHistoryView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath").font(.caption).foregroundColor(.green)
                L.text("Recent Calls", "最近通话").font(.caption).foregroundColor(.gray)
                Spacer()
                Button(L.str("Clear", "清空")) {
                    CallHistoryStore.shared.clear()
                    viewModel.callHistory = []
                }
                .font(.caption).foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.callHistory) { record in
                        HStack(spacing: 12) {
                            // Avatar with initials (same style as ContactRowView)
                            Group {
                                ZStack {
                                    Circle()
                                        .fill(callAvatarColor(record.contactName))
                                    Text(callInitials(record.contactName))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )

                            // Name, phone, metadata
                            VStack(alignment: .leading, spacing: 2) {
                                // Name row + direction badge
                                HStack(spacing: 6) {
                                    Text(record.contactName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    // Direction badge
                                    Label(
                                        record.direction == .outgoing
                                            ? L.str("Outgoing", "已拨")
                                            : L.str("Incoming", "已接"),
                                        systemImage: record.direction == .outgoing
                                            ? "arrow.up.right" : "arrow.down.left"
                                    )
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(record.direction == .outgoing ? .green : .orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        (record.direction == .outgoing ? Color.green : Color.orange)
                                            .opacity(0.12)
                                    )
                                    .cornerRadius(4)
                                }

                                // Phone number
                                Text(record.phoneNumber)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)

                                // Relative timestamp
                                Text(callRelativeTime(record.timestamp))
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray.opacity(0.6))
                            }

                            Spacer()

                            // Call button
                            Image(systemName: "phone.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.green.opacity(0.8))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.03), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let clean = record.phoneNumber.components(
                                separatedBy: CharacterSet.decimalDigits.inverted
                            ).joined()
                            if let url = URL(string: "tel://\(clean)"),
                               UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Call History Helpers

    private func callInitials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        return String(parts.compactMap { $0.first }.prefix(2)).uppercased()
    }

    private func callAvatarColor(_ name: String) -> Color {
        let colors: [Color] = [.blue, .cyan, .mint, .teal, .indigo, .purple, .pink, .orange]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }

    private func callRelativeTime(_ date: Date) -> String {
        let interval = -date.timeIntervalSinceNow
        switch interval {
        case ..<60: return L.str("Just now", "刚刚")
        case ..<3600: return L.str("%dm ago", "%d分钟前", Int(interval / 60))
        case ..<86400: return L.str("%dh ago", "%d小时前", Int(interval / 3600))
        case ..<172800: return L.str("Yesterday", "昨天")
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }

    // MARK: - Hints

    private func hintChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.gray.opacity(0.6))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color(white: 0.12).cornerRadius(8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.05), lineWidth: 0.5))
    }
}
