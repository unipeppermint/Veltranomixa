// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "LuckyIslandRules", platforms: [.macOS(.v13)], products: [.library(name: "IslandCore", targets: ["IslandCore"])], targets: [.target(name: "IslandCore", path: "Veltranomixa", exclude: ["Views", "Resources", "Assets.xcassets", "Base.lproj", "Info.plist", "AppDelegate.swift", "SceneDelegate.swift", "ViewController.swift"], sources: ["Domain", "Data"]), .testTarget(name: "IslandCoreTests", dependencies: ["IslandCore"], path: "Tests")])
