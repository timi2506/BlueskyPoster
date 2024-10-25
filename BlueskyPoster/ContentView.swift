import SwiftUI

struct ContentView: View {
    @StateObject private var blueskyAPI = BlueskyAPI() // Explicit initialization with ()
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var message: String = ""
    @State private var loginError: String?
    @State private var postSuccessMessage: String?
    @State private var postErrorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if blueskyAPI.accessJwt != nil {
                // Post message view
                VStack {
                    TextField("Enter message", text: $message)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Post to Bluesky") {
                        postMessage()
                    }
                    .padding()
                    
                    if let postSuccessMessage = postSuccessMessage {
                        Text(postSuccessMessage)
                            .foregroundColor(.green)
                    }
                    
                    if let postErrorMessage = postErrorMessage {
                        Text(postErrorMessage)
                            .foregroundColor(.red)
                    }
                    
                    Button("Logout") {
                        logout()
                    }
                    .foregroundColor(.red)
                    .padding()
                }
            } else {
                // Login view
                VStack {
                    TextField("Username or Email", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Login to Bluesky") {
                        login()
                    }
                    .padding()
                    
                    if let loginError = loginError {
                        Text(loginError)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
    }
    
    // Login function
    private func login() {
        blueskyAPI.login(username: username, password: password) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.loginError = nil
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loginError = "Login failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Post message function
    private func postMessage() {
        blueskyAPI.createPost(message: message) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.postSuccessMessage = "Post successful!"
                    self.postErrorMessage = nil
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.postErrorMessage = "Post failed: \(error.localizedDescription)"
                    self.postSuccessMessage = nil
                }
            }
        }
    }
    
    // Logout function
    private func logout() {
        blueskyAPI.logout()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
