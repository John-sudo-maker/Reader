//
//  AuthenticationService.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import Foundation
import LocalAuthentication
import Security

class AuthenticationService: AuthenticationServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let keychainService = "com.newsreader.app"
    
    func login(username: String, password: String) async throws -> Bool {
        guard !username.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        try saveToKeychain(username, forKey: "username")
        try saveToKeychain(password, forKey: "password")
        
        userDefaults.set(true, forKey: "isLoggedIn")
        userDefaults.set(username, forKey: "savedUsername")
        return true
    }
    
    func logout() {
        userDefaults.set(false, forKey: "isLoggedIn")
    }
    
    func isLoggedIn() -> Bool {
        return userDefaults.bool(forKey: "isLoggedIn")
    }
    
    func authenticateWithBiometry() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometryNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "验证身份以登录") { success, error in
                if success {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(throwing: error ?? AuthError.biometryFailed)
                }
            }
        }
    }
    
    func getBiometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }
    
    private func saveToKeychain(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case biometryNotAvailable
    case biometryFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "用户名或密码错误"
        case .biometryNotAvailable: return "设备不支持生物识别"
        case .biometryFailed: return "生物识别验证失败"
        }
    }
}

enum KeychainError: Error {
    case saveFailed
}
