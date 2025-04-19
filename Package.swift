// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Executor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Executor",
            targets: ["Executor"]
        )
    ],
    dependencies: [
        // Add any dependencies here
    ],
    targets: [
        .executableTarget(
            name: "Executor",
            dependencies: [],
            path: ".",
            sources: [
                "Frontend",
                "Loader",
                "Hooking",
                "Scripting",
                "Security"
            ],
            cxxSettings: [
                .headerSearchPath("Scripting"),
                .define("LUA_COMPAT_5_3")
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("AppKit"),
                .linkedFramework("CommonCrypto")
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
) 