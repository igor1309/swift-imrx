// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-imrx",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .imrx,
        .imTools,
    ],
    dependencies: [
        .combineSchedulers,
        .customDump,
    ],
    targets: [
        .imrx,
        .imrxTests,
        .imTools,
        .imToolsTests,
    ]
)

private extension Product {
    
    static let imrx = library(
        name: .imrx,
        targets: [
            .imrx
        ]
    )
    
    static let imTools = library(
        name: .imTools,
        targets: [
            .imTools
        ]
    )
}

private extension Target {
    
    static let imrx = target(
        name: .imrx,
        dependencies: [
            .combineSchedulers,
        ]
    )
    
    static let imrxTests = testTarget(
        name: .imrxTests,
        dependencies: [
            .combineSchedulers,
            .customDump,
            .imrx,
        ]
    )
    
    static let imTools = target(
        name: .imTools,
        dependencies: [
        ]
    )
    
    static let imToolsTests = testTarget(
        name: .imToolsTests,
        dependencies: [
            .customDump,
            .imTools,
        ]
    )
}

private extension Target.Dependency {
    
    static let imrx = byName(name: .imrx)
    
    static let imTools = byName(name: .imTools)
}

private extension String {
    
    static let imrx = "IMRx"
    static let imrxTests = "IMRxTests"
    
    static let imTools = "IMTools"
    static let imToolsTests = "IMToolsTests"
}

// MARK: - Point-Free

private extension Package.Dependency {
    
    static let casePaths = Package.Dependency.package(
        url: .pointFreeGitHub + .case_paths,
        from: .init(0, 10, 1)
    )
    static let combineSchedulers = Package.Dependency.package(
        url: .pointFreeGitHub + .combine_schedulers,
        from: .init(1, 0, 0)
    )
    static let customDump = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_custom_dump,
        from: .init(1, 2, 0)
    )
    static let identifiedCollections = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_identified_collections,
        from: .init(0, 4, 1)
    )
    static let snapshotTesting = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_snapshot_testing,
        from: .init(1, 10, 0)
    )
    static let swiftUINavigation = Package.Dependency.package(
        url: .pointFreeGitHub + .swiftui_navigation,
        from: .init(0, 4, 5)
    )
    static let tagged = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_tagged,
        from: .init(0, 7, 0)
    )
    static let shimmer = Package.Dependency.package(
        url: .swift_shimmer_path,
        exact: .init(1, 0, 1)
    )
    static let phoneNumberKit = Package.Dependency.package(
        url: .phoneNumberKit_path,
        exact: .init(3, 5, 8)
    )
}

private extension Target.Dependency {
    
    static let casePaths = product(
        name: .casePaths,
        package: .case_paths
    )
    static let combineSchedulers = product(
        name: .combineSchedulers,
        package: .combine_schedulers
    )
    static let customDump = product(
        name: .customDump,
        package: .swift_custom_dump
    )
    static let identifiedCollections = product(
        name: .identifiedCollections,
        package: .swift_identified_collections
    )
    static let snapshotTesting = product(
        name: .snapshotTesting,
        package: .swift_snapshot_testing
    )
    static let swiftUINavigation = product(
        name: .swiftUINavigation,
        package: .swiftui_navigation
    )
    static let tagged = product(
        name: .tagged,
        package: .swift_tagged
    )
    static let shimmer = product(
        name: .shimmer,
        package: .swift_shimmer
    )
    static let phoneNumberKit = product(
        name: .phoneNumberKit,
        package: .phoneNumberKit
    )
}

private extension String {
    
    static let pointFreeGitHub = "https://github.com/pointfreeco/"
    
    static let casePaths = "CasePaths"
    static let case_paths = "swift-case-paths"
    
    static let combineSchedulers = "CombineSchedulers"
    static let combine_schedulers = "combine-schedulers"
    
    static let customDump = "CustomDump"
    static let swift_custom_dump = "swift-custom-dump"
    
    static let identifiedCollections = "IdentifiedCollections"
    static let swift_identified_collections = "swift-identified-collections"
    
    static let snapshotTesting = "SnapshotTesting"
    static let swift_snapshot_testing = "swift-snapshot-testing"
    
    static let swiftUINavigation = "SwiftUINavigation"
    static let swiftui_navigation = "swiftui-navigation"
    
    static let tagged = "Tagged"
    static let swift_tagged = "swift-tagged"
    
    static let shimmer = "Shimmer"
    static let swift_shimmer = "SwiftUI-Shimmer"
    static let swift_shimmer_path = "https://github.com/markiv/SwiftUI-Shimmer"
    
    static let phoneNumberKit = "PhoneNumberKit"
    static let phoneNumberKit_path = "https://github.com/marmelroy/PhoneNumberKit"
}
