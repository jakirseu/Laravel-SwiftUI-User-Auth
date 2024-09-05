import SwiftUI

struct ContentView: View {
    
    @State var name = "Ali"
    @State var email = "ali1@email.com"
    @State var password = "12345"
    @State private var errorMessage: String?
    @State private var userResponse: UserResponse?
    @State var shouldPresentSheet = false
    
    var body: some View {
        VStack(spacing: 20){
            if let userResponse = userResponse {
                Text("User Name: \(userResponse.user.name)")
                Text("User Email: \(userResponse.user.email)")
                Button("Logout") {
                    Task{
                        await logout()
                    }
                }
            } else {
                TextField("Email", text: $email)
                TextField("Password", text: $password )
                Button("Login") {
                    Task{
                        await login()
                    }
                }
                
                // User Registration Button and Form
                Button("Create an account") {
                    shouldPresentSheet.toggle()
                }
                .sheet(isPresented: $shouldPresentSheet) {
                    print("Sheet dismissed!")
                } content: {
                    
                    VStack{
                        TextField("Name", text: $name)
                        TextField("Email", text: $email)
                        TextField("Password", text: $password )
                        Button("Register") {
                            Task{
                                await register()
                            }
                        }
                        
                        if let errorMessage = errorMessage {
                            Text("Error: \(errorMessage)")
                        }
                        
                    }.padding()
                        .textFieldStyle(.roundedBorder)
                    
                }
            }
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
    }
    
    
    func register() async  {
        guard let url = URL(string: "http://userauth.test/api/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let loginDetails = [ "name": name, "email": email, "password": password]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: loginDetails, options: [])
        
        do {
            // Perform the request
            let (responseData, response) = try await URLSession.shared.data(for: request)
            // Check the response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.unknown)
            }
            switch httpResponse.statusCode {
            case 200:
                // Decode the response data
                userResponse = try JSONDecoder().decode(UserResponse.self, from: responseData)
            default:
                // decode error response
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: responseData)
                errorMessage = errorResponse.message
            }
            
        } catch{
            print("Error:  \(error.localizedDescription)")
        }
    }
    
    
    func login() async  {
        guard let url = URL(string: "http://userauth.test/api/login") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let loginDetails = ["email": email, "password": password]
        
        request.httpBody = try? JSONEncoder().encode(loginDetails)
        
        
        do {
            // Perform the request
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            
            // Check the response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.unknown)
            }
            
            switch httpResponse.statusCode {
            case 200:
                self.shouldPresentSheet = false
                // Decode the response data
                userResponse = try JSONDecoder().decode(UserResponse.self, from: responseData)
                
            default:
                // decode error response
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: responseData)
                errorMessage = errorResponse.message
            }
        } catch{
            print("Error:  \(error.localizedDescription)")
        }
    }
    
    func logout() async  {
        guard let url = URL(string: "http://userauth.test/api/logout") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set the Authorization header with the Bearer token
        request.setValue("Bearer \(userResponse?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        
        do {
            // Perform the request
            let (responseData, response) = try await URLSession.shared.data(for: request)
            // Check the response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.unknown)
            }
            
            switch httpResponse.statusCode {
            case 200:
                // clearing the local user data
                self.userResponse = nil
                if let responseString = String(data: responseData, encoding: .utf8) {
                    print("Response as String: \(responseString)")
                }
                
            default:
                // decode error response
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: responseData)
                errorMessage = errorResponse.message
            }
            
        } catch{
            print("Error:  \(error.localizedDescription)")
        }
    }
    
}

#Preview {
    ContentView()
}


struct UserResponse: Codable {
    let user: User
    let token: String
}

struct User: Codable {
    let id: Int
    let name: String
    let email: String
    
}

struct ErrorResponse: Codable {
    let message: String
}
