//
//  ServiceProtocols.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import Foundation
import LocalAuthentication

protocol AuthenticationServiceProtocol {
    func login(username: String, password: String) async throws -> Bool
    func logout()
    func isLoggedIn() -> Bool
    func authenticateWithBiometry() async throws -> Bool
    func getBiometryType() -> LABiometryType
}

protocol StorageServiceProtocol {
    func save<T: Codable>(_ value: T, for key: String) throws
    func load<T: Codable>(for key: String) throws -> T?
    func delete(for key: String) throws
}

protocol APIServiceProtocol {
    func fetchNews() async throws -> [NewsArticle]
    func searchNews(query: String) async throws -> [NewsArticle]
}
