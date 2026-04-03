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
    
    // MARK: - launches
    func testAppLaunches() throws {
        XCTAssertTrue(app.tabBars.firstMatch.exists, "TabBar 应该存在")
        XCTAssertTrue(app.tabBars.buttons["首页"].exists, "首页 Tab 应该存在")
        XCTAssertTrue(app.tabBars.buttons["搜索"].exists, "搜索 Tab 应该存在")
        XCTAssertTrue(app.tabBars.buttons["我的"].exists, "我的 Tab 应该存在")
    }
    
    // MARK: - main page test
    func testHomePageLoads() throws {
        let homeTab = app.tabBars.buttons["首页"]
        XCTAssertTrue(homeTab.exists)
        homeTab.tap()
        
        let navigationBar = app.navigationBars["热门仓库"]
        XCTAssertTrue(navigationBar.exists, "导航栏应该显示'热门仓库'")
        
        let imageWidget = app.images.firstMatch
        XCTAssertTrue(imageWidget.waitForExistence(timeout: 3), "图片组件应该存在")
    }
    
    func testHomePageHasLoginButtonWhenNotLoggedIn() throws {
        logoutIfNeeded()
        
        app.tabBars.buttons["首页"].tap()
        
        let loginButton = app.navigationBars["热门仓库"].buttons["登录"]
        XCTAssertTrue(loginButton.exists, "未登录时应该显示登录按钮")
    }
    
    func testHomePageHasLogoutButtonWhenLoggedIn() throws {
        performLogin()
        
        app.tabBars.buttons["首页"].tap()
        
        let logoutButton = app.navigationBars["热门仓库"].buttons["退出"]
        XCTAssertTrue(logoutButton.exists, "登录后应该显示退出按钮")
        
        logoutButton.tap()
        
        let confirmAlert = app.alerts.firstMatch
        if confirmAlert.exists {
            confirmAlert.buttons["确定"].tap()
        }
    }
    
    // MARK: - search page
    func testSearchPageRequiresLogin() throws {
        logoutIfNeeded()
        
        let searchTab = app.tabBars.buttons["搜索"]
        XCTAssertTrue(searchTab.exists)
        searchTab.tap()
        
        let emptyStateLabel = app.staticTexts["🔐 请先登录后再使用搜索功能\n\n点击右上角登录"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 2), "未登录时应该显示登录提示")
    }
    
    func testSearchPageWorksWhenLoggedIn() throws {
        performLogin()
        
        app.tabBars.buttons["搜索"].tap()
        
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "登录后应该显示搜索框")
        
        searchField.tap()
        searchField.typeText("Swift")
        
        searchField.typeText("\n")
        
        sleep(2)
        
        let resultCell = app.cells.firstMatch
        XCTAssertTrue(resultCell.waitForExistence(timeout: 5), "应该显示搜索结果")
    }
    
    // MARK: - profile page
    func testProfilePageRequiresLogin() throws {
        logoutIfNeeded()
        
        let profileTab = app.tabBars.buttons["我的"]
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
        
        let loginButton = app.buttons["立即登录"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2), "未登录时应该显示登录按钮")
    }
    
    func testProfilePageShowsUserInfoWhenLoggedIn() throws {
        performLogin()
        
        app.tabBars.buttons["我的"].tap()
        
        let nameLabel = app.staticTexts.element(matching: .any, identifier: nil)
        sleep(1)
        
        let logoutButton = app.buttons["退出登录"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 3), "登录后应该显示退出按钮")
    }
    
    // MARK: - login flow test
    func testLoginFlow() throws {
        logoutIfNeeded()
        
        triggerLogin()
        
        let loginTitle = app.staticTexts["欢迎回来"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 3), "登录页面应该出现")
        
        let usernameField = app.textFields["用户名"]
        let passwordField = app.secureTextFields["密码"]
        
        XCTAssertTrue(usernameField.exists, "用户名输入框应该存在")
        XCTAssertTrue(passwordField.exists, "密码输入框应该存在")
        
        usernameField.tap()
        usernameField.typeText("testuser")
        
        passwordField.tap()
        passwordField.typeText("123456")
        
        let loginButton = app.buttons["登录"]
        XCTAssertTrue(loginButton.exists)
        loginButton.tap()
        
        sleep(2)
        
        XCTAssertFalse(loginTitle.exists, "登录成功后登录页面应该消失")
    }
    
    func testLoginWithSkip() throws {
        logoutIfNeeded()
        
        triggerLogin()
        
        let loginTitle = app.staticTexts["欢迎回来"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 3))
        
        let skipButton = app.buttons["跳过，继续浏览"]
        XCTAssertTrue(skipButton.exists)
        skipButton.tap()
        
        sleep(1)
        XCTAssertFalse(loginTitle.exists, "点击跳过后登录页面应该关闭")
    }
    
    // MARK: - logoff test
    func testLogoutFlow() throws {
        performLogin()
        
        app.tabBars.buttons["我的"].tap()
        
        let logoutButton = app.buttons["退出登录"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 3))
        logoutButton.tap()
        
        let confirmAlert = app.alerts.firstMatch
        if confirmAlert.exists {
            confirmAlert.buttons["确定"].tap()
        }
        
        sleep(1)
        
        let loginButton = app.buttons["立即登录"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 3), "退出后应该显示登录按钮")
    }
    
    // MARK: - Tab switch test
    func testTabSwitching() throws {
        let tabs = ["首页", "搜索", "我的"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "\(tabName) Tab 应该存在")
            tab.tap()
            sleep(1)
            
            XCTAssertTrue(tab.isSelected, "\(tabName) Tab 应该被选中")
        }
    }
    
    func testUnloggedUserCannotAccessSearch() throws {
        logoutIfNeeded()
        
        app.tabBars.buttons["搜索"].tap()
        
        let prompt = app.staticTexts["🔐 请先登录后再使用搜索功能\n\n点击右上角登录"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 3), "未登录用户应该看到登录提示")
    }
    
    func testUnloggedUserCannotAccessProfile() throws {
        logoutIfNeeded()
        
        app.tabBars.buttons["我的"].tap()
        
        let loginButton = app.buttons["立即登录"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 3), "未登录用户应该看到登录按钮")
    }
    
    func testBiometryLoginOption() throws {
        logoutIfNeeded()
        
        triggerLogin()
        
        let biometryButton = app.buttons.element(matching: .any, identifier: nil)
        
        if biometryButton.label.contains("Face ID") || biometryButton.label.contains("Touch ID") {
            biometryButton.tap()
            
            XCTAssertTrue(biometryButton.exists, "生物识别登录按钮应该存在")
        }
    }
    
    func testHomePageScrolling() throws {
        sleep(3)
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "滚动视图应该存在")
        
        scrollView.swipeUp()
        sleep(1)
        
        scrollView.swipeDown()
        sleep(1)
        
        XCTAssertTrue(app.exists, "App 应该正常运行")
    }
    
    func testTakeScreenshots() throws {
        app.tabBars.buttons["首页"].tap()
        sleep(2)
        let homeScreenshot = app.screenshot()
        let homeAttachment = XCTAttachment(screenshot: homeScreenshot)
        homeAttachment.name = "HomePage"
        add(homeAttachment)
        
        triggerLogin()
        sleep(1)
        let loginScreenshot = app.screenshot()
        let loginAttachment = XCTAttachment(screenshot: loginScreenshot)
        loginAttachment.name = "LoginPage"
        add(loginAttachment)
        
        let skipButton = app.buttons["跳过，继续浏览"]
        if skipButton.exists {
            skipButton.tap()
        }
        
        app.tabBars.buttons["搜索"].tap()
        sleep(1)
        let searchScreenshot = app.screenshot()
        let searchAttachment = XCTAttachment(screenshot: searchScreenshot)
        searchAttachment.name = "SearchPage"
        add(searchAttachment)
        
        app.tabBars.buttons["我的"].tap()
        sleep(1)
        let profileScreenshot = app.screenshot()
        let profileAttachment = XCTAttachment(screenshot: profileScreenshot)
        profileAttachment.name = "ProfilePage"
        add(profileAttachment)
    }
        
    private func performLogin() {
        logoutIfNeeded()
        
        triggerLogin()
        
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
        
        app.tabBars.buttons["首页"].tap()
    }
    
    private func triggerLogin() {
        app.tabBars.buttons["首页"].tap()
        
        let navLoginButton = app.navigationBars.buttons["登录"]
        if navLoginButton.exists {
            navLoginButton.tap()
            return
        }
        
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
