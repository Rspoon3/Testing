
import SwiftUI
struct PaywallView: View {
    @State private var selectedPlan: Plan = .monthly

    var body: some View {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.5), .purple.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
                        StickyHeader()
                        
                        // Benefits Section
                        BenefitsSection()
                        
                        // Pricing Section
                        PricingSection(selectedPlan: $selectedPlan)
                        
                        // Start for Free Button
                        StartForFreeButton {
                            print("Started Free Trial with \(selectedPlan.rawValue.capitalized) Plan")
                        }
                        
                        // Guarantee
                        Text("7-day free trial. Cancel anytime.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 20)
                    }
            }
        }
    }
}

// MARK: - Sticky Header

struct StickyHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Step Up to Premium")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .purple, radius: 5, x: 0, y: 2)

            Text("Experience all the benefits of going premium.")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 40)
    }
}

// MARK: - Benefits Section

struct BenefitsSection: View {
    var body: some View {
        VStack(spacing: 15) {
            BenefitItem(icon: "star.fill", title: "Exclusive Content", description: "Access all premium features and content.")
            BenefitItem(icon: "bolt.fill", title: "Enhanced Speed", description: "Faster performance and prioritized updates.")
            BenefitItem(icon: "lock.fill", title: "Top Security", description: "Advanced privacy and protection features.")
        }
        .padding(.horizontal)
    }
}

struct BenefitItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .font(.largeTitle)
                .padding()
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// MARK: - Pricing Section

struct PricingSection: View {
    @Binding var selectedPlan: Plan

    var body: some View {
        VStack(spacing: 10) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack(spacing: 10) {
                ForEach(Plan.allCases, id: \.self) { plan in
                    PricingCard(plan: plan, isSelected: plan == selectedPlan) {
                        withAnimation {
                            selectedPlan = plan
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct PricingCard: View {
    let plan: Plan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(plan.rawValue.capitalized)
                .font(.headline)
                .foregroundColor(.white)

            Text(plan.subtitle)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .white.opacity(0.6))

            Text(plan.price)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.4))
        }
        .padding()
        .frame(height: 150)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isSelected ? Color.blue.gradient : Color.white.opacity(0.2).gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.blue.gradient : Color.white.opacity(0.2).gradient, lineWidth: 2)
        )
        .shadow(radius: 5)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(), value: isSelected)
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Start for Free Button

struct StartForFreeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Start for Free")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
}

// MARK: - Plan Enum

enum Plan: String, CaseIterable {
    case weekly, monthly, yearly

    var price: String {
        switch self {
        case .weekly: return "$1.99"
        case .monthly: return "$4.99"
        case .yearly: return "$49.99"
        }
    }

    var subtitle: String {
        switch self {
        case .weekly: return "Billed weekly"
        case .monthly: return "Billed monthly"
        case .yearly: return "Most Popular"
        }
    }
}
