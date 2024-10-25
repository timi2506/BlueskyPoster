import Foundation
import Alamofire

class BlueskyAPI: ObservableObject {
    static let shared = BlueskyAPI()  // Singleton instance

    private let accessJwtKey = "accessJwtKey"
    private let didKey = "didKey"
    private let service = "com.yourapp.bluesky" // Replace with your app's bundle identifier
    
    @Published var accessJwt: String?
    @Published var did: String?
    
    private init() {
        // Load credentials from Keychain on initialization
        if let jwtData = KeychainHelper.shared.read(service: service, account: accessJwtKey),
           let didData = KeychainHelper.shared.read(service: service, account: didKey) {
            self.accessJwt = String(data: jwtData, encoding: .utf8)
            self.did = String(data: didData, encoding: .utf8)
        }
    }

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
    
    func logout() {
        accessJwt = nil
        did = nil
        
        KeychainHelper.shared.delete(service: service, account: accessJwtKey)
        KeychainHelper.shared.delete(service: service, account: didKey)
    }
}
