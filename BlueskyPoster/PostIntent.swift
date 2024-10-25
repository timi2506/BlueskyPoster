import AppIntents

struct PostIntent: AppIntent {
    static var title: LocalizedStringResource = "Post to Bluesky"
    static var description = IntentDescription("Post a message to Bluesky.")

    @Parameter(title: "Message")
    var message: String

    static var parameterSummary: some ParameterSummary {
        Summary("Post \(\.$message) to Bluesky")
    }

    func perform() async throws -> some IntentResult {
        let blueskyAPI = BlueskyAPI.shared

        await blueskyAPI.createPost(message: message) { result in
            switch result {
            case .success:
                print("Message posted successfully!")
            case .failure(let error):
                print("Failed to post message: \(error.localizedDescription)")
            }
        }

        return .result()
    }
}
