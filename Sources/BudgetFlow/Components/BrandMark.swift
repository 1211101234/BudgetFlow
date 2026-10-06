import AppKit
import SwiftUI

struct BrandMark: View {
    var size: CGFloat = 52

    var body: some View {
        Group {
            if let image = AppAssets.budgetFlowIcon {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Image(systemName: "wallet.bifold.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
                    .foregroundStyle(.white)
                    .background(BudgetTheme.brand.gradient)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        .accessibilityHidden(true)
    }
}

@MainActor
private enum AppAssets {
    static let budgetFlowIcon: NSImage? = {
        let bundles = [Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        guard let url = bundles.lazy.compactMap({
            $0.url(forResource: "BudgetFlowIcon", withExtension: "png")
        }).first else {
            return nil
        }
        return NSImage(contentsOf: url)
    }()
}
