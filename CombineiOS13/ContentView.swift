//
//  ContentView.swift
//  CombineiOS13
//
//  Created by Toshihiro Goto on 2020/08/10.
//  Copyright © 2020 Toshihiro Goto. All rights reserved.
//

import SwiftUI
import Combine

final class ContentViewModel : ObservableObject, Identifiable {
    
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordAgain: String = ""
    @Published var passwordFlag: Bool = true
    
    private var cancellables: [AnyCancellable] = []
    
    private var validatedUsername: AnyPublisher<String?, Never> {
        return $username
                .debounce(for: 0.1, scheduler: RunLoop.main)
                .removeDuplicates()
                .flatMap { (username) -> AnyPublisher<String?, Never> in
                        Future<String?, Never> { (promise) in
                            // FIXME: Search for a user name on the network
                            if 5...16 ~= username.count {
                                promise(.success(username))
                            } else {
                                promise(.success(nil))
                            }
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
    }
    
    var validatedPassword: AnyPublisher<String?, Never> {
           return Publishers.CombineLatest($password, $passwordAgain)
               .map { password, passwordAgain in
                   guard password == passwordAgain, password.count > 7 else { return nil }
                   return password
           }
           .eraseToAnyPublisher()
       }
    
    var validatedCredentials: AnyPublisher<(String, String)?, Never> {
            return Publishers.CombineLatest(validatedUsername, validatedPassword)
                .map { username, password in
                    guard let uname = username, let pwd = password else { return nil }
                    return (uname, pwd)
            }
            .eraseToAnyPublisher()
        }
    
    func onAppear() {
        self.validatedUsername
            .sink(receiveValue: { value in
                if let value = value {
                    self.username = value
                } else {
                    print("Invalid username")
                }
            })
            .store(in: &self.cancellables)
        
        self.validatedCredentials
            .sink(receiveValue: { value in
                if value != nil {
                    self.passwordFlag = false
                } else {
                    self.passwordFlag = true
                }
            })
            .store(in: &self.cancellables)
    }
    
    func onDisappear() {
        self.cancellables.forEach { $0.cancel() }
        self.cancellables = []
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                Image(systemName: "person.circle")
                    .font(.system(size: 32))
                TextField("Username", text: $viewModel.username)
                .keyboardType(.alphabet)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack(spacing: 16) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 32))
                SecureField("Password", text: $viewModel.password)
                .keyboardType(.alphabet)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack(spacing: 16) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 32))
                SecureField("Repeat Password", text: $viewModel.passwordAgain)
                .keyboardType(.alphabet)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Spacer().frame(height: 24)
            
            Button(action:{}){
                Text("Create Account")
                    .frame(maxWidth: .infinity, maxHeight: 44)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .disabled(viewModel.passwordFlag)
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
