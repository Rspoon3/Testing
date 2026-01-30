import SwiftUI
import TestDrivePersistence

/// Displays a domain logo with fallback to first letter in colored circle.
///
/// Automatically fetches logos using DomainLogoService and handles loading states.
struct DomainLogoView: View {

    // MARK: - Properties

    let domain: String?
    let size: CGFloat

    @State private var logoImage: UIImage?
    @State private var isLoading = true
    @Environment(\.domainLogoService) private var logoService

    // MARK: - Body

    var body: some View {
        ZStack {
            if let image = logoImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            } else if isLoading {
                ProgressView()
                    .frame(width: size, height: size)
            } else {
                fallbackView
            }
        }
        .task(id: domain) {
            await loadLogo()
        }
    }

    // MARK: - Fallback View

    private var fallbackView: some View {
        ZStack {
            Circle()
                .fill(fallbackColor.opacity(0.2))
                .frame(width: size, height: size)

            Text(firstLetter)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Computed Properties

    private var firstLetter: String {
        guard let domain = domain?.trimmingCharacters(in: .whitespacesAndNewlines),
              !domain.isEmpty else {
            return "?"
        }

        return domain.prefix(1).uppercased()
    }

    private var fallbackColor: Color {
        guard let domain = domain else {
            return .gray
        }

        // Hash domain for consistent color
        let hash = abs(domain.hashValue)
        let hue = Double(hash % 360) / 360.0

        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }

    // MARK: - Private Helpers

    private func loadLogo() async {
        guard let domain else {
            isLoading = false
            return
        }

        logoImage = await logoService.logo(for: domain)
        isLoading = false
    }
}

// MARK: - Environment Key

private struct DomainLogoServiceKey: EnvironmentKey {
    static let defaultValue = DomainLogoService.shared
}

extension EnvironmentValues {
    var domainLogoService: DomainLogoService {
        get { self[DomainLogoServiceKey.self] }
        set { self[DomainLogoServiceKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DomainLogoView(domain: "apple.com", size: 64)
        DomainLogoView(domain: "github.com", size: 64)
        DomainLogoView(domain: "amazon.com", size: 64)
        DomainLogoView(domain: nil, size: 64)
    }
    .padding()
}
