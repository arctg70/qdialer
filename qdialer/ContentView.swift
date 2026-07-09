import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContactSearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            SearchBarView(
                text: viewModel.searchText,
                resultCount: viewModel.filteredContacts.count,
                isSearching: !viewModel.searchText.isEmpty
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
        .alert("Contacts Access Required", isPresented: $viewModel.showPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This app needs access to your contacts to search and dial.\n\nPlease enable Contacts in Settings → Privacy & Security.")
        }
    }

    private var headerBar: some View {
        HStack {
            Image(systemName: "phone")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.green)
                .padding(6)
                .background(Circle().fill(Color.green.opacity(0.15)))

            Text("Smart Dialer")
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
                Text("Loading contacts…").font(.caption).foregroundColor(.gray)
            }
            Spacer()
        } else if viewModel.showPermissionDenied {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "lock.shield").font(.system(size: 40)).foregroundColor(.gray)
                Text("No Contact Access").font(.headline).foregroundColor(.white)
                Text("Enable access in Settings to search contacts").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            Spacer()
        } else if !viewModel.searchText.isEmpty && viewModel.filteredContacts.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "person.slash").font(.system(size: 40)).foregroundColor(.gray.opacity(0.5))
                Text("No contacts match \"\(viewModel.searchText)\"").font(.body).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            Spacer()
        } else if !viewModel.filteredContacts.isEmpty {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        Color.clear.frame(height: 1).id("top")
                        ForEach(Array(viewModel.filteredContacts.enumerated()), id: \.element) { _, contact in
                            ContactRowView(contact: contact, isHighlighted: viewModel.selectedContact?.id == contact.id)
                                .onTapGesture { viewModel.callContact(contact) }
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
                    Text("Start typing to find contacts").font(.headline).foregroundColor(.white.opacity(0.7))
                    Text("Supports pinyin initials, full pinyin,\nEnglish names & partial phone numbers").font(.caption).foregroundColor(.gray.opacity(0.5)).multilineTextAlignment(.center)
                }
                HStack(spacing: 16) {
                    hintChip("zs → 张三")
                    hintChip("jd → John Doe")
                    hintChip("138 → Phone")
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
                Text("Recent Calls").font(.caption).foregroundColor(.gray)
                Spacer()
                Button("Clear") {
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
                        HStack(spacing: 10) {
                            // Direction icon
                            Image(systemName: record.direction == .outgoing
                                ? "arrow.up.right" : "arrow.down.left")
                                .font(.system(size: 10))
                                .foregroundColor(record.direction == .outgoing ? .green : .orange)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.contactName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                Text(record.phoneNumber)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text(record.timestamp, style: .time)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.08))
                        .cornerRadius(8)
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
