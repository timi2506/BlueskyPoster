import AppIntents

struct BlueskyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] = [
        AppShortcut(
            intent: PostIntent(),
            phrases: ["Post to Bluesky \(\.$message)"],
            shortTitle: "Post to Bluesky",
            systemImageName: "paperplane.fill"
        )
    ]
}
