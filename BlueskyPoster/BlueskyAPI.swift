import Foundation
import Alamofire

class BlueskyAPI: ObservableObject {
    private let accessJwtKey = "accessJwtKey"
    private let didKey = "didKey"
    
    private let service = "com.yourapp.bluesky" // Replace with your app's bundle identifier
    
    @Published var accessJwt: String?
    @Published var did: String?
    
    init() {
        // Try to load credentials from Keychain on app launch
        if let jwtData = KeychainHelper.shared.read(service: service, account: accessJwtKey),
           let didData = KeychainHelper.shared.read(service: service, account: didKey) {
            self.accessJwt = String(data: jwtData, encoding: .utf8)
            self.did = String(data: didData, encoding: .utf8)
        }
    }

    // Login function to get access JWT
    func login(username: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = "https://bsky.social/xrpc/com.atproto.server.createSession"
        
        let parameters: [String: Any] = [
            "identifier": username,
            "password": password
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let data):
                    if let json = data as? [String: Any],
                       let accessJwt = json["accessJwt"] as? String,
                       let did = json["did"] as? String {
                        self.accessJwt = accessJwt
                        self.did = did
                        
                        // Store the accessJwt and did in Keychain
                        KeychainHelper.shared.save(Data(accessJwt.utf8), service: self.service, account: self.accessJwtKey)
                        KeychainHelper.shared.save(Data(did.utf8), service: self.service, account: self.didKey)
                        
                        completion(.success(accessJwt))
                    } else {
                        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // Function to create a post
    func createPost(message: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let accessJwt = accessJwt, let did = did else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
            completion(.failure(error))
            return
        }
        
        let url = "https://bsky.social/xrpc/com.atproto.repo.createRecord"
        
        let parameters: [String: Any] = [
            "collection": "app.bsky.feed.post",
            "repo": did,
            "record": [
                "$type": "app.bsky.feed.post",
                "text": message,
                "createdAt": ISO8601DateFormatter().string(from: Date())
            ]
        ]
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessJwt)",
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success:
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    // Async wrapper for createPost
    func createPostAsync(message: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            createPost(message: message) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // Logout: Clear the stored credentials
    func logout() {
        accessJwt = nil
        did = nil
        
        KeychainHelper.shared.delete(service: service, account: accessJwtKey)
        KeychainHelper.shared.delete(service: service, account: didKey)
    }
}
