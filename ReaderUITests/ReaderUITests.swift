//
//  ReaderUITests.swift
//  ReaderUITests
//
//  Created by John on 2026/4/2.
//

import XCTest

final class ReaderUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        super.tearDown()
    }
    
    // MARK: - 启动测试
    func testAppLaunches() throws {
        // 验证 App 启动成功
        XCTAssertTrue(app.tabBars.firstMatch.exists, "TabBar 应该存在")
        XCTAssertTrue(app.tabBars.buttons["首页"].exists, "首页 Tab 应该存在")
        XCTAssertTrue(app.tabBars.buttons["搜索"].exists, "搜索 Tab 应该存在")
        XCTAssertTrue(app.tabBars.buttons["我的"].exists, "我的 Tab 应该存在")
    }
    
    // MARK: - 首页测试
    func testHomePageLoads() throws {
        // 点击首页 Tab
        let homeTab = app.tabBars.buttons["首页"]
        XCTAssertTrue(homeTab.exists)
        homeTab.tap()
        
        // 验证首页元素存在
        let navigationBar = app.navigationBars["热门仓库"]
        XCTAssertTrue(navigationBar.exists, "导航栏应该显示'热门仓库'")
        
        // 验证图片组件存在
        let imageWidget = app.images.firstMatch
        XCTAssertTrue(imageWidget.waitForExistence(timeout: 3), "图片组件应该存在")
    }
    
    func testHomePageHasLoginButtonWhenNotLoggedIn() throws {
        // 确保未登录状态
        logoutIfNeeded()
        
        // 点击首页 Tab
        app.tabBars.buttons["首页"].tap()
        
        // 验证登录按钮存在
        let loginButton = app.navigationBars["热门仓库"].buttons["登录"]
        XCTAssertTrue(loginButton.exists, "未登录时应该显示登录按钮")
    }
    
    func testHomePageHasLogoutButtonWhenLoggedIn() throws {
        // 先登录
        performLogin()
        
        // 点击首页 Tab
        app.tabBars.buttons["首页"].tap()
        
        // 验证退出按钮存在
        let logoutButton = app.navigationBars["热门仓库"].buttons["退出"]
        XCTAssertTrue(logoutButton.exists, "登录后应该显示退出按钮")
        
        // 退出登录
        logoutButton.tap()
        
        // 确认退出
        let confirmAlert = app.alerts.firstMatch
        if confirmAlert.exists {
            confirmAlert.buttons["确定"].tap()
        }
    }
    
    // MARK: - 搜索页面测试
    func testSearchPageRequiresLogin() throws {
        // 确保未登录状态
        logoutIfNeeded()
        
        // 点击搜索 Tab
        let searchTab = app.tabBars.buttons["搜索"]
        XCTAssertTrue(searchTab.exists)
        searchTab.tap()
        
        // 验证未登录提示
        let emptyStateLabel = app.staticTexts["🔐 请先登录后再使用搜索功能\n\n点击右上角登录"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 2), "未登录时应该显示登录提示")
    }
    
    func testSearchPageWorksWhenLoggedIn() throws {
        // 先登录
        performLogin()
        
        // 点击搜索 Tab
        app.tabBars.buttons["搜索"].tap()
        
        // 验证搜索框存在
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "登录后应该显示搜索框")
        
        // 输入搜索内容
        searchField.tap()
        searchField.typeText("Swift")
        
        // 点击搜索
        searchField.typeText("\n")
        
        // 等待搜索结果
        sleep(2)
        
        // 验证结果存在
        let resultCell = app.cells.firstMatch
        XCTAssertTrue(resultCell.waitForExistence(timeout: 5), "应该显示搜索结果")
    }
    
    // MARK: - 个人资料页面测试
    func testProfilePageRequiresLogin() throws {
        // 确保未登录状态
        logoutIfNeeded()
        
        // 点击我的 Tab
        let profileTab = app.tabBars.buttons["我的"]
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
        
        // 验证登录按钮存在
        let loginButton = app.buttons["立即登录"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2), "未登录时应该显示登录按钮")
    }
    
    func testProfilePageShowsUserInfoWhenLoggedIn() throws {
        // 先登录
        performLogin()
        
        // 点击我的 Tab
        app.tabBars.buttons["我的"].tap()
        
        // 验证用户信息显示
        let nameLabel = app.staticTexts.element(matching: .any, identifier: nil)
        // 等待页面加载
        sleep(1)
        
        // 验证退出按钮存在
        let logoutButton = app.buttons["退出登录"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 3), "登录后应该显示退出按钮")
    }
    
    // MARK: - 登录流程测试
    func testLoginFlow() throws {
        // 确保未登录状态
        logoutIfNeeded()
        
        // 触发登录
        triggerLogin()
        
        // 验证登录页面出现
        let loginTitle = app.staticTexts["欢迎回来"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 3), "登录页面应该出现")
        
        // 输入用户名和密码
        let usernameField = app.textFields["用户名"]
        let passwordField = app.secureTextFields["密码"]
        
        XCTAssertTrue(usernameField.exists, "用户名输入框应该存在")
        XCTAssertTrue(passwordField.exists, "密码输入框应该存在")
        
        usernameField.tap()
        usernameField.typeText("testuser")
        
        passwordField.tap()
        passwordField.typeText("123456")
        
        // 点击登录按钮
        let loginButton = app.buttons["登录"]
        XCTAssertTrue(loginButton.exists)
        loginButton.tap()
        
        // 等待登录完成
        sleep(2)
        
        // 验证登录成功（登录页面消失）
        XCTAssertFalse(loginTitle.exists, "登录成功后登录页面应该消失")
    }
    
    func testLoginWithSkip() throws {
        // 确保未登录状态
        logoutIfNeeded()
        
        // 触发登录
        triggerLogin()
        
        // 验证登录页面出现
        let loginTitle = app.staticTexts["欢迎回来"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 3))
        
        // 点击跳过按钮
        let skipButton = app.buttons["跳过，继续浏览"]
        XCTAssertTrue(skipButton.exists)
        skipButton.tap()
        
        // 验证登录页面关闭
        sleep(1)
        XCTAssertFalse(loginTitle.exists, "点击跳过后登录页面应该关闭")
    }
    
    // MARK: - 退出登录测试
    func testLogoutFlow() throws {
        // 先登录
        performLogin()
        
        // 进入个人资料页
        app.tabBars.buttons["我的"].tap()
        
        // 点击退出登录
        let logoutButton = app.buttons["退出登录"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 3))
        logoutButton.tap()
        
        // 确认退出
        let confirmAlert = app.alerts.firstMatch
        if confirmAlert.exists {
            confirmAlert.buttons["确定"].tap()
        }
        
        // 等待退出完成
        sleep(1)
        
        // 验证已退出（登录按钮重新出现）
        let loginButton = app.buttons["立即登录"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 3), "退出后应该显示登录按钮")
    }
    
    // MARK: - Tab 切换测试
    func testTabSwitching() throws {
        // 测试切换所有 Tab
        let tabs = ["首页", "搜索", "我的"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "\(tabName) Tab 应该存在")
            tab.tap()
            sleep(1)
            
            // 验证当前 Tab 被选中
            XCTAssertTrue(tab.isSelected, "\(tabName) Tab 应该被选中")
        }
    }
    
    // MARK: - 未登录限制测试
    func testUnloggedUserCannotAccessSearch() throws {
        // 确保未登录状态
        logoutIfNeeded()
        
        // 直接点击搜索 Tab
        app.tabBars.buttons["搜索"].tap()
        
        // 验证未登录提示
        let prompt = app.staticTexts["🔐 请先登录后再使用搜索功能\n\n点击右上角登录"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 3), "未登录用户应该看到登录提示")
    }
    
    func testUnloggedUserCannotAccessProfile() throws {
        // 确保未登录状态
        logoutIfNeeded()
        
        // 直接点击我的 Tab
        app.tabBars.buttons["我的"].tap()
        
        // 验证显示登录按钮
        let loginButton = app.buttons["立即登录"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 3), "未登录用户应该看到登录按钮")
    }
    
    // MARK: - 生物识别测试（仅模拟器）
    func testBiometryLoginOption() throws {
        // 确保未登录状态
        logoutIfNeeded()
        
        // 触发登录
        triggerLogin()
        
        // 检查是否有生物识别按钮（取决于模拟器配置）
        let biometryButton = app.buttons.element(matching: .any, identifier: nil)
        
        // 如果存在生物识别按钮，测试点击
        if biometryButton.label.contains("Face ID") || biometryButton.label.contains("Touch ID") {
            biometryButton.tap()
            
            // 在模拟器上，需要手动触发 Face ID 匹配
            // 这里只验证按钮存在
            XCTAssertTrue(biometryButton.exists, "生物识别登录按钮应该存在")
        }
    }
    
    // MARK: - 滚动测试
    func testHomePageScrolling() throws {
        // 等待首页加载
        sleep(3)
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "滚动视图应该存在")
        
        // 向下滑动
        scrollView.swipeUp()
        sleep(1)
        
        // 向上滑动
        scrollView.swipeDown()
        sleep(1)
        
        // 验证没有崩溃
        XCTAssertTrue(app.exists, "App 应该正常运行")
    }
    
    // MARK: - 内存和性能测试
    func testMemoryUsage() throws {
        // 测试多次切换 Tab
        for _ in 1...10 {
            app.tabBars.buttons["首页"].tap()
            sleep(1)
            app.tabBars.buttons["搜索"].tap()
            sleep(1)
            app.tabBars.buttons["我的"].tap()
            sleep(1)
        }
        
        // 验证 App 没有崩溃
        XCTAssertTrue(app.exists, "多次切换 Tab 后 App 应该仍然正常运行")
    }
    
    // MARK: - 截图测试（可用于 TestFlight）
    func testTakeScreenshots() throws {
        // 首页截图
        app.tabBars.buttons["首页"].tap()
        sleep(2)
        let homeScreenshot = app.screenshot()
        let homeAttachment = XCTAttachment(screenshot: homeScreenshot)
        homeAttachment.name = "HomePage"
        add(homeAttachment)
        
        // 登录页面截图
        triggerLogin()
        sleep(1)
        let loginScreenshot = app.screenshot()
        let loginAttachment = XCTAttachment(screenshot: loginScreenshot)
        loginAttachment.name = "LoginPage"
        add(loginAttachment)
        
        // 关闭登录页面
        let skipButton = app.buttons["跳过，继续浏览"]
        if skipButton.exists {
            skipButton.tap()
        }
        
        // 搜索页面截图
        app.tabBars.buttons["搜索"].tap()
        sleep(1)
        let searchScreenshot = app.screenshot()
        let searchAttachment = XCTAttachment(screenshot: searchScreenshot)
        searchAttachment.name = "SearchPage"
        add(searchAttachment)
        
        // 个人资料页面截图
        app.tabBars.buttons["我的"].tap()
        sleep(1)
        let profileScreenshot = app.screenshot()
        let profileAttachment = XCTAttachment(screenshot: profileScreenshot)
        profileAttachment.name = "ProfilePage"
        add(profileAttachment)
    }
    
    // MARK: - 辅助方法
    
    private func performLogin() {
        // 如果已登录，先退出
        logoutIfNeeded()
        
        // 触发登录
        triggerLogin()
        
        // 输入凭据并登录
        let usernameField = app.textFields["用户名"]
        let passwordField = app.secureTextFields["密码"]
        
        if usernameField.waitForExistence(timeout: 3) {
            usernameField.tap()
            usernameField.typeText("testuser")
            
            passwordField.tap()
            passwordField.typeText("123456")
            
            app.buttons["登录"].tap()
            sleep(2)
        }
    }
    
    private func logoutIfNeeded() {
        // 尝试退出登录
        app.tabBars.buttons["我的"].tap()
        
        let logoutButton = app.buttons["退出登录"]
        if logoutButton.exists {
            logoutButton.tap()
            let confirmAlert = app.alerts.firstMatch
            if confirmAlert.exists {
                confirmAlert.buttons["确定"].tap()
            }
            sleep(1)
        }
        
        // 回到首页
        app.tabBars.buttons["首页"].tap()
    }
    
    private func triggerLogin() {
        // 尝试通过首页的登录按钮触发
        app.tabBars.buttons["首页"].tap()
        
        let navLoginButton = app.navigationBars.buttons["登录"]
        if navLoginButton.exists {
            navLoginButton.tap()
            return
        }
        
        // 或者通过个人资料页的登录按钮触发
        app.tabBars.buttons["我的"].tap()
        let profileLoginButton = app.buttons["立即登录"]
        if profileLoginButton.exists {
            profileLoginButton.tap()
        }
    }
}

// MARK: - XCUIElement 扩展
extension XCUIElement {
    var isSelected: Bool {
        return (self.value as? String) == "selected"
    }
}
