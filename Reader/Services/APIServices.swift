//
//  APIServices.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import Foundation

class APIService: APIServiceProtocol {
    private let baseURL = "https://api.github.com"
    private let useMockData = false  // 改为 false 使用真实 API
    
    func fetchNews() async throws -> [NewsArticle] {
        if useMockData {
            return getMockArticles()
        }
        
        let urlString = "\(baseURL)/search/repositories?q=language:swift&sort=stars&order=desc&per_page=20"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 403 {
                    print("API 速率限制达到，使用 Mock 数据")
                    return getMockArticles()  // 降级到 Mock 数据
                }
                
                guard httpResponse.statusCode == 200 else {
                    throw APIError.httpError(httpResponse.statusCode)
                }
            }
            
            let searchResult = try JSONDecoder().decode(SearchResult.self, from: data)
            return searchResult.items.map { NewsArticle.from($0) }
            
        } catch {
            print("请求失败: \(error.localizedDescription)")
            // 网络错误时返回 Mock 数据
            return getMockArticles()
        }
    }
    
    func searchNews(query: String) async throws -> [NewsArticle] {
        if useMockData {
            return getMockArticles().filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                ($0.description.localizedCaseInsensitiveContains(query))
            }
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/repositories?q=\(encodedQuery)&sort=stars&order=desc&per_page=20"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ReaderApp/1.0", forHTTPHeaderField: "User-Agent")  // 添加 User-Agent
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Search HTTP Status: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    throw APIError.httpError(httpResponse.statusCode)
                }
            }
            
            let searchResult = try JSONDecoder().decode(SearchResult.self, from: data)
            print("搜索到 \(searchResult.items.count) 个结果")
            return searchResult.items.map { NewsArticle.from($0) }
            
        } catch {
            print("搜索失败: \(error)")
            throw error
        }
    }
    
    // Mock 数据作为备用
    private func getMockArticles() -> [NewsArticle] {
        return [
            NewsArticle(
                title: "SwiftUI - 构建现代 iOS 应用",
                description: "SwiftUI 是 Apple 推出的现代化 UI 框架，让开发者可以用声明式语法构建界面。",
                stars: 12450,
                url: "https://github.com/apple/swift",
                author: "apple",
                language: "Swift"
            ),
            NewsArticle(
                title: "Alamofire - 优雅的网络请求库",
                description: "Alamofire 是用 Swift 编写的 HTTP 网络请求库，提供了链式请求和响应处理。",
                stars: 39800,
                url: "https://github.com/Alamofire/Alamofire",
                author: "Alamofire",
                language: "Swift"
            ),
            NewsArticle(
                title: "SnapKit - 自动布局简化工具",
                description: "SnapKit 让 iOS 自动布局代码更简洁易读，是 Swift 开发者的好帮手。",
                stars: 18900,
                url: "https://github.com/SnapKit/SnapKit",
                author: "SnapKit",
                language: "Swift"
            ),
            NewsArticle(
                title: "Kingfisher - 图片加载库",
                description: "Kingfisher 是一个强大的图片下载和缓存库",
                stars: 21500,
                url: "https://github.com/onevcat/Kingfisher",
                author: "onevcat",
                language: "Swift"
            ),
            NewsArticle(
                title: "RxSwift - 响应式编程",
                description: "RxSwift 是 Reactive Extensions 的 Swift 版本",
                stars: 23500,
                url: "https://github.com/ReactiveX/RxSwift",
                author: "ReactiveX",
                language: "Swift"
            )
        ]
    }
}

// API 错误类型
enum APIError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case emptyData
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .emptyData:
            return "服务器返回空数据"
        case .decodingError(let msg):
            return "数据解析错误: \(msg)"
        }
    }
}

// GitHubRepo 模型 - 同时支持普通仓库和搜索 API 返回的仓库
struct GitHubRepo: Codable {
    let id: Int
    let name: String
    let fullName: String?
    let description: String?
    let stargazersCount: Int
    let htmlUrl: String
    let owner: Owner?
    let fork: Bool?
    let language: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, owner, fork, language
        case fullName = "full_name"
        case stargazersCount = "stargazers_count"
        case htmlUrl = "html_url"
    }
}

struct Owner: Codable {
    let login: String
    let id: Int
    let avatarUrl: String?
    let htmlUrl: String?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case login, id, type
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
    }
}

struct SearchResult: Codable {
    let items: [GitHubRepo]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case items
        case totalCount = "total_count"
    }
}

struct NewsArticle {
    let title: String
    let description: String
    let stars: Int
    let url: String
    let author: String?
    let language: String?
    
    static func from(_ repo: GitHubRepo) -> NewsArticle {
        return NewsArticle(
            title: repo.name,
            description: repo.description ?? "暂无描述",
            stars: repo.stargazersCount,
            url: repo.htmlUrl,
            author: repo.owner?.login,
            language: repo.language
        )
    }
}
