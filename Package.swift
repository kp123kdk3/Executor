// swift-tools-version: 5.7
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
    targets: [
        .target(
            name: "ExecutorCore",
            path: "Frontend",
            sources: ["ProcessManager.m"],
            publicHeadersPath: "."
        ),
        .executableTarget(
            name: "Executor",
            dependencies: ["ExecutorCore"],
            path: "Frontend",
            exclude: ["ProcessManager.m"],
            sources: ["ScriptingInterfaceApp.swift"]
        )
    ]
) 