import SwiftUI
import Contacts

// MARK: - Contact Row

struct ContactRowView: View {
    let contact: ContactModel
    let isHighlighted: Bool

    init(contact: ContactModel, isHighlighted: Bool = false) {
        self.contact = contact
        self.isHighlighted = isHighlighted
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Group {
                if let data = contact.thumbnailImageData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle()
                            .fill(avatarColor.opacity(0.25))
                        Text(contact.initials)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(avatarColor)
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )

            // Name & phone
            VStack(alignment: .leading, spacing: 2) {
                // Name row + nickname badge
                HStack(spacing: 6) {
                    Text(contact.fullName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if !contact.nickname.isEmpty {
                        Text(contact.nickname)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                            .lineLimit(1)
                    }
                }

                if let phone = contact.phoneNumbers.first {
                    HStack(spacing: 4) {
                        Image(systemName: "phone")
                            .font(.system(size: 9))
                        Text(phone)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.gray)
                }

                // Company / organization
                if !contact.organization.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.system(size: 8))
                        Text(contact.organization)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.gray.opacity(0.6))
                    .lineLimit(1)
                }
            }

            Spacer()

            // Phone icon
            Image(systemName: "phone.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.green.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color.green.opacity(0.08) : Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isHighlighted ? Color.green.opacity(0.2) : Color.white.opacity(0.03),
                            lineWidth: isHighlighted ? 1 : 0.5
                        )
                )
        )
        .padding(.horizontal, 8)
    }

    // Deterministic color from name
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .cyan, .mint, .teal, .indigo, .purple, .pink, .orange]
        let hash = abs(contact.fullName.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 4) {
        ContactRowView(
            contact: ContactModel(
                contact: {
                    let c = CNMutableContact()
                    c.givenName = "San"
                    c.familyName = "Zhang"
                    c.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile,
                                                      value: CNPhoneNumber(stringValue: "+86 138 0013 8000"))]
                    c.organizationName = "Acme Corp"
                    return c as CNContact
                }()
            ),
            isHighlighted: false
        )
        ContactRowView(
            contact: ContactModel(
                contact: {
                    let c = CNMutableContact()
                    c.givenName = "Alice"
                    c.familyName = "Johnson"
                    c.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberiPhone,
                                                      value: CNPhoneNumber(stringValue: "+1 (650) 555-1234"))]
                    return c as CNContact
                }()
            ),
            isHighlighted: true
        )
    }
    .padding(.vertical)
    .background(Color.black)
    .previewLayout(.sizeThatFits)
}
