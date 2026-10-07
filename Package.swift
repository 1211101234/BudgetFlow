// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BudgetFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BudgetFlow", targets: ["BudgetFlow"]),
        .executable(name: "BudgetFlowWidget", targets: ["BudgetFlowWidget"]),
        .library(name: "BudgetCore", targets: ["BudgetCore"])
    ],
    targets: [
        .target(name: "BudgetCore"),
        .executableTarget(
            name: "BudgetFlow",
            dependencies: ["BudgetCore"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "BudgetFlowWidget",
            dependencies: ["BudgetCore"]
        ),
        .testTarget(
            name: "BudgetCoreTests",
            dependencies: ["BudgetCore"]
        )
    ]
)
