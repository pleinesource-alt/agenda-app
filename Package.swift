// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Agenda",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        .executableTarget(
            name: "Agenda",
            path: "Sources/Agenda",
            exclude: ["Info.plist"],
            linkerSettings: [
                // Embeds Info.plist into the built binary so macOS shows
                // the calendar-access prompt instead of crashing (a
                // plain `swift run` executable has no app bundle of its
                // own to carry usage-description keys otherwise).
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Agenda/Info.plist"
                ], .when(platforms: [.macOS]))
            ]
        )
    ]
)
