import AppKit
import SwiftUI

enum BudgetTheme {
    static let brand = Color(nsColor: .systemIndigo)
    static let positive = Color(nsColor: .systemTeal)
    static let warning = Color(nsColor: .systemOrange)
    static let critical = Color(nsColor: .systemRed)
    static let information = Color(nsColor: .systemBlue)
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let divider = Color(nsColor: .separatorColor)

    static let heroGradient = LinearGradient(
        colors: [brand.opacity(0.26), positive.opacity(0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct BudgetCanvas<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            BudgetTheme.canvas
            if !reduceTransparency {
                LinearGradient(
                    colors: [BudgetTheme.brand.opacity(0.055), .clear, BudgetTheme.positive.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            content
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        }
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(BudgetTheme.brand.gradient, in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(BudgetTheme.positive)
                Text(title)
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct BudgetPanelModifier: ViewModifier {
    let accent: Color?

    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(BudgetTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(alignment: .top) {
                if let accent {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accent)
                        .frame(height: 4)
                        .padding(.horizontal, 18)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(BudgetTheme.divider.opacity(0.7), lineWidth: 1)
            }
    }
}

extension View {
    func budgetPanel(accent: Color? = nil) -> some View {
        modifier(BudgetPanelModifier(accent: accent))
    }
}
