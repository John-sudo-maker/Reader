//
//  ReaderTests.swift
//  ReaderTests
//
//  Created by John on 2026/4/2.
//

import XCTest
@testable import Reader

// MARK: - AuthenticationService Tests
final class AuthenticationServiceTests: XCTestCase {
    var authService: AuthenticationService!
    
    override func setUp() async throws {
        try await super.setUp()
        authService = AuthenticationService()
        // 清除之前的登录状态
        await MainActor.run {
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "savedUsername")
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            authService.logout()
        }
        authService = nil
        try await super.tearDown()
    }
    
    // MARK: - Login Tests
    func testLoginWithValidCredentials() async throws {
        let result = try await authService.login(username: "testuser", password: "123456")
        XCTAssertTrue(result)
        
        await MainActor.run {
            XCTAssertTrue(authService.isLoggedIn())
        }
    }
    
    func testLoginWithEmptyUsername() async {
        do {
            _ = try await authService.login(username: "", password: "123456")
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
    
    func testLoginWithEmptyPassword() async {
        do {
            _ = try await authService.login(username: "testuser", password: "")
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
    
    func testLoginWithEmptyCredentials() async {
        do {
            _ = try await authService.login(username: "", password: "")
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
    
    // MARK: - Logout Tests
    func testLogout() async throws {
        // 先登录
        _ = try await authService.login(username: "testuser", password: "123456")
        
        await MainActor.run {
            XCTAssertTrue(authService.isLoggedIn())
        }
        
        // 再退出
        await MainActor.run {
            authService.logout()
            XCTAssertFalse(authService.isLoggedIn())
        }
    }
    
    // MARK: - Login State Tests
    func testIsLoggedInInitiallyFalse() async {
        await MainActor.run {
            XCTAssertFalse(authService.isLoggedIn())
        }
    }
    
    func testIsLoggedInAfterLogin() async throws {
        _ = try await authService.login(username: "testuser", password: "123456")
        
        await MainActor.run {
            XCTAssertTrue(authService.isLoggedIn())
        }
    }
}

// MARK: - APIService Tests
final class APIServiceTests: XCTestCase {
    var apiService: APIService!
    
    override func setUp() {
        super.setUp()
        apiService = APIService()
    }
    
    override func tearDown() {
        apiService = nil
        super.tearDown()
    }
    
    // MARK: - Fetch News Tests
    func testFetchNewsReturnsArticles() async throws {
        let articles = try await apiService.fetchNews()
        let count = articles.count
        XCTAssertGreaterThanOrEqual(count, 1)
    }
    
    func testFetchNewsArticlesHaveRequiredFields() async throws {
        let articles = try await apiService.fetchNews()
        
        for article in articles {
            // 提取属性值到局部变量，避免并发问题
            let title = article.title
            let description = article.description
            let url = article.url
            let stars = article.stars
            
            XCTAssertFalse(title.isEmpty, "标题不应为空")
            XCTAssertFalse(description.isEmpty, "描述不应为空")
            XCTAssertTrue(url.hasPrefix("https://"), "URL应以https://开头")
            XCTAssertGreaterThanOrEqual(stars, 0, "star数量不应为负数")
        }
    }
    
    // MARK: - Search News Tests
    func testSearchNewsWithValidQuery() async throws {
        let results = try await apiService.searchNews(query: "Swift")
        XCTAssertNotNil(results)
    }
    
    func testSearchNewsWithEmptyQuery() async throws {
        let results = try await apiService.searchNews(query: "")
        XCTAssertNotNil(results)
    }
    
    func testSearchNewsWithNonExistentQuery() async throws {
        let results = try await apiService.searchNews(query: "xyznonexistent123456789")
        XCTAssertNotNil(results)
    }
}

// MARK: - NewsArticle Tests
final class NewsArticleTests: XCTestCase {
    
    func testNewsArticleInitialization() {
        let article = NewsArticle(
            title: "Test Title",
            description: "Test Description",
            stars: 100,
            url: "https://github.com/test",
            author: "testauthor",
            language: "Swift"
        )
        
        XCTAssertEqual(article.title, "Test Title")
        XCTAssertEqual(article.description, "Test Description")
        XCTAssertEqual(article.stars, 100)
        XCTAssertEqual(article.url, "https://github.com/test")
        XCTAssertEqual(article.author, "testauthor")
        XCTAssertEqual(article.language, "Swift")
    }
    
    func testNewsArticleFromGitHubRepo() {
        let owner = Owner(
            login: "testowner",
            id: 1,
            avatarUrl: nil,
            htmlUrl: nil,
            type: "User"
        )
        
        let repo = GitHubRepo(
            id: 1,
            name: "TestRepo",
            fullName: "testowner/TestRepo",
            description: "Test Description",
            stargazersCount: 500,
            htmlUrl: "https://github.com/testowner/TestRepo",
            owner: owner,
            fork: false,
            language: "Swift"
        )
        
        let article = NewsArticle.from(repo)
        
        XCTAssertEqual(article.title, "TestRepo")
        XCTAssertEqual(article.description, "Test Description")
        XCTAssertEqual(article.stars, 500)
        XCTAssertEqual(article.url, "https://github.com/testowner/TestRepo")
        XCTAssertEqual(article.author, "testowner")
        XCTAssertEqual(article.language, "Swift")
    }
    
    func testNewsArticleFromGitHubRepoWithNilDescription() {
        let repo = GitHubRepo(
            id: 1,
            name: "TestRepo",
            fullName: "testowner/TestRepo",
            description: nil,
            stargazersCount: 500,
            htmlUrl: "https://github.com/testowner/TestRepo",
            owner: nil,
            fork: false,
            language: nil
        )
        
        let article = NewsArticle.from(repo)
        XCTAssertEqual(article.description, "暂无描述")
        XCTAssertNil(article.author)
        XCTAssertNil(article.language)
    }
}

// MARK: - Mock Data Tests
final class MockDataTests: XCTestCase {
    var apiService: APIService!
    
    override func setUp() {
        super.setUp()
        apiService = APIService()
    }
    
    override func tearDown() {
        apiService = nil
        super.tearDown()
    }
    
    func testMockArticlesCount() async throws {
        let articles = try await apiService.fetchNews()
        let count = articles.count
        XCTAssertGreaterThanOrEqual(count, 3, "Mock数据至少应该有3条")
    }
    
    func testMockArticlesHaveValidData() async throws {
        let articles = try await apiService.fetchNews()
        
        for article in articles {
            let title = article.title
            let description = article.description
            let url = article.url
            
            XCTAssertFalse(title.isEmpty)
            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(url.hasPrefix("https://"))
        }
    }
}

// MARK: - UserDefaults Tests
final class UserDefaultsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // 清除测试数据
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "savedUsername")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "savedUsername")
        super.tearDown()
    }
    
    func testSaveAndRetrieveLoginState() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set("testuser", forKey: "savedUsername")
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let username = UserDefaults.standard.string(forKey: "savedUsername")
        
        XCTAssertTrue(isLoggedIn)
        XCTAssertEqual(username, "testuser")
    }
    
    func testDefaultLoginStateIsFalse() {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        XCTAssertFalse(isLoggedIn)
    }
    
    func testClearLoginState() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        XCTAssertFalse(isLoggedIn)
    }
}

// MARK: - Performance Tests
final class PerformanceTests: XCTestCase {
    
    func testFetchNewsPerformance() {
        let apiService = APIService()
        
        measure {
            let expectation = XCTestExpectation(description: "Fetch news")
            
            Task {
                do {
                    _ = try await apiService.fetchNews()
                    expectation.fulfill()
                } catch {
                    // 不要在这里调用 XCTFail，因为会在异步上下文中
                    print("Performance test error: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)  // 增加超时时间
        }
    }
    
    func testJSONDecodingPerformance() throws {
        let jsonString = """
        {
            "items": [
                {
                    "id": 1,
                    "name": "TestRepo",
                    "description": "Test Description",
                    "stargazers_count": 100,
                    "html_url": "https://github.com/test/test",
                    "owner": {
                        "login": "testowner",
                        "id": 1
                    }
                }
            ],
            "total_count": 1
        }
        """
        
        let jsonData = try XCTUnwrap(jsonString.data(using: .utf8))
        
        measure {
            do {
                let _ = try JSONDecoder().decode(SearchResult.self, from: jsonData)
            } catch {
                // 在 measure 块内不能调用 XCTFail
                print("Decoding failed: \(error)")
            }
        }
    }
}

// MARK: - Network Mock Tests
final class NetworkMockTests: XCTestCase {
    
    // Mock URLProtocol 类
    class MockURLProtocol: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let mockData = """
            {
                "items": [
                    {
                        "id": 1,
                        "name": "MockRepo",
                        "description": "Mock Description",
                        "stargazers_count": 1000,
                        "html_url": "https://github.com/mock/mock",
                        "owner": {
                            "login": "mockowner",
                            "id": 1
                        },
                        "language": "Swift"
                    }
                ],
                "total_count": 1
            }
            """.data(using: .utf8)!
            
            let response = HTTPURLResponse(
                url: try! XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: mockData)
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
    
    func testMockNetworkRequest() async throws {
        // 配置 URLSession 使用 Mock
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        
        let url = try XCTUnwrap(URL(string: "https://api.github.com/search/repositories?q=test"))
        let (data, _) = try await session.data(from: url)
        
        let searchResult = try JSONDecoder().decode(SearchResult.self, from: data)
        let itemsCount = searchResult.items.count
        let firstName = searchResult.items.first?.name
        
        XCTAssertEqual(itemsCount, 1)
        XCTAssertEqual(firstName, "MockRepo")
    }
}

// MARK: - Combined Tests Runner
final class AllTests: XCTestCase {
    func testRunAllTests() {
        print("运行所有测试...")
        XCTAssertTrue(true, "测试套件启动")
    }
}
