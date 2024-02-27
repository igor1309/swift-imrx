// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-imrx",
    products: [
        .imrx,
    ],
    targets: [
        .imrx,
        .imrxTests,
    ]
)

private extension Product {
    
    static let imrx = library(
        name: .imrx,
        targets: [
            .imrx
        ]
    )
}

private extension Target {
    
    static let imrx = target(name: .imrx)
    
    static let imrxTests = testTarget(
        name: .imrxTests,
        dependencies: [
            .imrx
        ]
    )
}

private extension Target.Dependency {
    
    static let imrx = byName(name: .imrx)
}

private extension String {
    
    static let imrx = "IMRx"
    static let imrxTests = "IMRxTests"
}
